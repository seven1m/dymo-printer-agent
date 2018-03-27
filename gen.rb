require 'prawn'
require 'nokogiri'
require 'combine_pdf'

SIZES = {
  '30252 Address' => [252 - 21, 72 - 8]
}

X_FACTOR = 0.05
X_MARGIN = 15.5
Y_FACTOR = 0.17
FONT_FACTOR = 0.74

doc = Nokogiri::XML(File.read(ARGV.first))
paper_size = SIZES[doc.css('PaperName').first.text] || SIZES.values.first

path = File.expand_path('../out.pdf', __FILE__)
Prawn::Document.generate(path, page_size: paper_size, margin: [0, 0, 0, 0]) do
  stroke_bounds
  doc.css('ObjectInfo').each do |object|
    bounds = object.css('Bounds').first.attributes
    width = bounds['Width'].value.to_i * X_FACTOR
    height = bounds['Height'].value.to_i * Y_FACTOR
    x = bounds['X'].value.to_i * X_FACTOR - X_MARGIN
    y = paper_size.last - (bounds['Y'].value.to_i * Y_FACTOR)
    bounding_box([x, y], width: width, height: height) do
      if (text_object = object.css('TextObject').first)
        elements = text_object.css('StyledText Element').map do |element|
          size = element.css('Attributes Font').first.attributes['Size'].value.to_i
          string = element.css('String').first.text
          escaped_string = string.gsub('<', '&lt;').gsub('>', '&gt;')
          spacing = size > 24 ? -0.4 : -0.1
          %(<font name="Helvetica" character_spacing="#{spacing}" size="#{size * FONT_FACTOR}">#{escaped_string}</font>)
        end
        text elements.join, inline_format: true
      else
        puts 'unsupported object type'
      end
    end
  end
end

#def f(text:, size:)
#  { text: text, size: size * 0.7, color: 'FF0000' }
#end
#
#Prawn::Document.generate('sizes.pdf', page_size: paper_size, margin: [0, 0, 0, 0]) do
#  #dash 10, :space => 4
#  stroke_color 'FF0000'
#  stroke_bounds
#  move_cursor_to 51
#  formatted_text [ 
#    f(text: "72", size: 74.6), # 0.965
#    f(text: "48", size: 50.5), # 0.950
#    f(text: "36", size: 38.5), # 0.932
#    f(text: "24", size: 26.5), # 0.905
#    f(text: "18", size: 18),   # 
#    f(text: "1414", size: 14),
#    f(text: "1010", size: 10),
#    f(text: "7777", size: 7),
#  ]
#end

pdf = CombinePDF.new
pdf << CombinePDF.load('out.pdf')
pdf << CombinePDF.load('sizes_template.pdf')
pdf.save 'sizes_combined.pdf'

actual = CombinePDF.load('out.pdf').pages[0]
pdf = CombinePDF.load('sizes_template.pdf')
pdf.pages.each { |page| page << actual }
pdf.save 'sizes_overlay.pdf'
