require 'prawn'
require 'nokogiri'

class Renderer
  # 1440 twips per inch (20 per PDF point)
  TWIP = 1440.0

  # 72 PDF points per inch
  PDF_POINT = 72.0

  # TODO: add more label sizes here
  SIZES = {
    '30252 Address' => [252, 81]
  }.freeze

  # This may be needed for some label types. Zero for now.
  LEFT_MARGIN = 0

  # TODO: translate more font names here
  FONTS = {
    'Arial' => 'Helvetica'
  }.freeze

  def initialize(label_xml)
    @label_xml = label_xml
    @doc = Nokogiri::XML(label_xml)
  end

  def render
    build_pdf
    doc.css('ObjectInfo').each do |object|
      pdf.go_to_page 1
      render_object(object)
    end
    pdf.render
  end

  private

  attr_reader :doc, :pdf

  def paper_size
    SIZES[doc.css('PaperName').first.text] || SIZES.values.first
  end

  def build_pdf
    @pdf = Prawn::Document.new(page_size: paper_size, margin: [0, 0, 0, 0])
  end

  def render_object(object)
    bounds = object.css('Bounds').first.attributes
    x = ((bounds['X'].value.to_i / TWIP) - LEFT_MARGIN) * PDF_POINT
    y = paper_size.last - (bounds['Y'].value.to_i / TWIP * PDF_POINT)
    width = ((bounds['Width'].value.to_i / TWIP) - LEFT_MARGIN) * PDF_POINT
    height = bounds['Height'].value.to_i / TWIP * PDF_POINT
    if (text_object = object.css('TextObject').first)
      render_text_object(text_object, x, y, width, height)
    elsif (shape_object = object.css('ShapeObject').first)
      render_shape_object(shape_object, x, y, width, height)
    else
      puts 'unsupported object type'
    end
  end

  def render_text_object(text_object, x, y, width, height)
    foreground = text_object.css('ForeColor').first
    color = color_from_element(foreground)
    draw_rectangle_from_object(text_object, x, y, width, height)
    verticalized = text_object.css('Verticalized').first
    verticalized &&= verticalized.text == 'True'
    elements = text_object.css('StyledText Element').map do |element|
      styled_text_element_to_formatted_strings(element, verticalized: verticalized)
    end
    y -= 3 # simulate vertical padding
    begin
      pdf.text_box(
        "<color rgb='#{color}'>#{elements.join}</color>",
        at: [x, y],
        width: width,
        height: height,
        overflow: overflow_from_text_object(text_object),
        inline_format: true,
        align: align_from_text_object(text_object),
        valign: valign_from_text_object(text_object),
        single_line: !verticalized
      )
    rescue Prawn::Errors::CannotFit
      puts 'cannot fit'
    end
  end

  def draw_rectangle_from_object(text_object, x, y, width, height)
    background = text_object.css('BackColor').first
    return unless background
    alpha = background.attributes['Alpha'].value.to_i
    return if alpha.zero?
    pdf.fill_color color_from_element(background)
    pdf.rectangle [x, y], width, height
    pdf.fill
  end

  def color_from_element(element)
    red   = element.attributes['Red'].value.to_i
    green = element.attributes['Green'].value.to_i
    blue  = element.attributes['Blue'].value.to_i
    Prawn::Graphics::Color.rgb2hex([red, green, blue])
  end

  def styled_text_element_to_formatted_strings(element, verticalized: false)
    font = element.css('Attributes Font').first
    font_family = FONTS[font.attributes['Family'].value] || 'Helvetica'
    size = font.attributes['Size'].value.to_i
    string = element.css('String').first.text
    string = string.each_char.map { |c| [c, "\n"] }.flatten.join if verticalized
    escaped_string = string.gsub('<', '&lt;').gsub('>', '&gt;')
    spacing = 0
    %(<font name="#{font_family}" character_spacing="#{spacing}" size="#{size}">#{escaped_string}</font>)
  end

  VALIGNS = {
    'Top'    => :top,
    'Bottom' => :bottom,
    'Middle' => :center
  }.freeze

  def valign_from_text_object(text_object)
    VALIGNS[text_object.css('VerticalAlignment').first.text] || :top
  end

  ALIGNS = {
    'Left'   => :left,
    'Right'  => :right,
    'Center' => :center
  }.freeze

  def align_from_text_object(text_object)
    ALIGNS[text_object.css('HorizontalAlignment').first.text] || :left
  end

  OVERFLOWS = {
    'None'      => :truncate,
    'AlwaysFit' => :shrink_to_fit
  }.freeze

  def overflow_from_text_object(text_object)
    OVERFLOWS[text_object.css('TextFitMode').first.text] || :truncate
  end

  def render_shape_object(shape_object, x, y, width, height)
    case shape_object.css('ShapeType').first.text
    when 'HorizontalLine'
      pdf.line_width height
      pdf.horizontal_line x, x + width, at: y
      pdf.stroke
    else
      puts 'unknown shape type'
    end
  end
end
