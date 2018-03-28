require 'prawn'
require 'nokogiri'
require 'combine_pdf'

# 1440 twips per inch (20 per PDF point)
TWIP = 1440.0

# 72 PDF points per inch
PDF_POINT = 72.0

SIZES = {
  '30252 Address' => [252 - 16, 72 - 4]
  #'30252 Address' => [3.5 * PDF_POINT, 1 * PDF_POINT]
}

# About this much margin on the left is not actually shown in the output pdf.
LEFT_MARGIN = 0.21

# Text boxes in Prawn are less forgiving than in Dymo.
# Add just a bit more space for text to fit and not get cut off.
EXTRA_PADDING = 10

doc = Nokogiri::XML(File.read(ARGV.first))
paper_size = SIZES[doc.css('PaperName').first.text] || SIZES.values.first

path = File.expand_path('out.pdf', __dir__)
Prawn::Document.generate(path, page_size: paper_size, margin: [0, 0, 0, 0]) do
  doc.css('ObjectInfo').each do |object|
    bounds = object.css('Bounds').first.attributes
    width = ((bounds['Width'].value.to_i / TWIP) - LEFT_MARGIN) * PDF_POINT
    height = bounds['Height'].value.to_i / TWIP * PDF_POINT
    x = ((bounds['X'].value.to_i / TWIP) - LEFT_MARGIN) * PDF_POINT
    y = paper_size.last - (bounds['Y'].value.to_i / TWIP * PDF_POINT)
    go_to_page 1
    if (text_object = object.css('TextObject').first)
      elements = text_object.css('StyledText Element').map do |element|
        size = element.css('Attributes Font').first.attributes['Size'].value.to_i
        string = element.css('String').first.text
        escaped_string = string.gsub('<', '&lt;').gsub('>', '&gt;')
        spacing = 0
        %(<font name="Helvetica" character_spacing="#{spacing}" size="#{size}">#{escaped_string}</font>)
      end
      valign = {
        'Top'    => :top,
        'Bottom' => :bottom,
        'Middle' => :center
      }[text_object.css('VerticalAlignment').first.text] || :top
      align = {
        'Left'   => :left,
        'Right'  => :right,
        'Center' => :center
      }[text_object.css('HorizontalAlignment').first.text] || :left
      overflow = {
        'None'      => :truncate,
        'AlwaysFit' => :shrink_to_fit
      }[text_object.css('TextFitMode').first.text] || :truncate
      # WARNING: the magic numbers below are hard-won -- be careful changing them!
      y -= 3 # simulate vertical padding
      height -= valign == :bottom ? 4 : 6 # bottom-aligned things need less padding ¯\_(ツ)_/¯
      width += 12 # prawn wraps text earlier than Dymo, so give the box some extra room
      text_box(
        elements.join,
        at: [x, y],
        width: width,
        height: height,
        overflow: overflow,
        inline_format: true,
        align: align,
        valign: valign,
        disable_wrap_by_char: true,
        single_line: true
      )
    else
      puts 'unsupported object type'
    end
  end
end

pdf = CombinePDF.new
pdf << CombinePDF.load('out.pdf')
pdf << CombinePDF.load('sizes_template.pdf')
pdf.save 'sizes_combined.pdf'

actual = CombinePDF.load('out.pdf').pages[0]
pdf = CombinePDF.load('sizes_template.pdf')
pdf.pages.each { |page| page << actual }
pdf.save 'sizes_overlay.pdf'
