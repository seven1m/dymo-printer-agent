require 'prawn'
require 'nokogiri'
require 'combine_pdf'

# 1440 twips per inch (20 per PDF point)
TWIP = 1440.0

# 72 PDF points per inch
PDF_POINT = 72.0

SIZES = {
  '30252 Address' => [252, 81]
}.freeze

# This may be needed for some label types. Zero for now.
LEFT_MARGIN = 0

FONTS = {
  'Arial' => 'Helvetica'
}.freeze


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
      if (background = text_object.css('BackColor').first)
        alpha = background.attributes['Alpha'].value.to_i
        if alpha > 0
          fill_color Prawn::Graphics::Color.rgb2hex([
            background.attributes['Red'].value.to_i,
            background.attributes['Green'].value.to_i,
            background.attributes['Blue'].value.to_i
          ])
          rectangle [x, y], width, height
          fill
        end
      end
      elements = text_object.css('StyledText Element').map do |element|
        font = element.css('Attributes Font').first
        font_family = FONTS[font.attributes['Family'].value] || 'Helvetica'
        size = font.attributes['Size'].value.to_i
        string = element.css('String').first.text
        escaped_string = string.gsub('<', '&lt;').gsub('>', '&gt;')
        spacing = 0
        %(<font name="#{font_family}" character_spacing="#{spacing}" size="#{size}">#{escaped_string}</font>)
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
      y -= 3 # simulate vertical padding
      begin
        text_box(
          '<color rgb="5ecede">' + elements.join + '</color>',
          at: [x, y],
          width: width,
          height: height,
          overflow: overflow,
          inline_format: true,
          align: align,
          valign: valign,
          #disable_wrap_by_char: true,
          single_line: true
        )
      rescue Prawn::Errors::CannotFit
        puts 'cannot fit'
      end
    else
      puts 'unsupported object type'
    end
  end
end

pdf = CombinePDF.new
pdf << CombinePDF.load('out.pdf')
pdf << CombinePDF.load('sample_nametag.pdf')
pdf.save 'sample_nametag_combined.pdf'

actual = CombinePDF.load('out.pdf').pages[0]
pdf = CombinePDF.load('sample_nametag.pdf')
pdf.pages.each { |page| page << actual }
pdf.save 'sample_nametag_overlay.pdf'
