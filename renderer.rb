require 'prawn'
require 'nokogiri'

module FormattedBoxDescenderFix
  # On bottom-aligned boxes, Dymo seems to count the height of character descenders.
  # Let's hack Prawn to do the same.

  def process_vertical_alignment(text)
    super
    @at[1] += @descender if @vertical_align == :bottom
  end
end

Prawn::Text::Formatted::Box.prepend(FormattedBoxDescenderFix)

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

  def initialize(xml:, params:)
    @xml = xml
    @params = params
    @doc = Nokogiri::XML(xml)
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
    elm = doc.css('PaperName').first
    elm && SIZES[elm.text] || SIZES.values.first
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
    name = text_object.css('Name').first
    name &&= name.text
    elements = text_object.css('StyledText Element')
    font = elements.first.css('Attributes Font').first
    font_family = FONTS[font.attributes['Family'].value] || 'Helvetica'
    size = font.attributes['Size'].value.to_i
    strings = elements.map do |element|
      string = @params[name] || element.css('String').first.text
      string = string.each_char.map { |c| [c, "\n"] }.flatten.join if verticalized
      string
    end
    y -= 3 # everything seems to be shifted down by about 3 points with Dymo
    begin
      pdf.fill_color color
      pdf.font font_family
      pdf.text_box(
        strings.join,
        size: size,
        at: [x, y],
        width: width,
        height: height,
        overflow: overflow_from_text_object(text_object),
        align: align_from_text_object(text_object),
        valign: valign_from_text_object(text_object),
        disable_wrap_by_char: true,
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
    'None'        => :truncate,
    'ShrinkToFit' => :shrink_to_fit
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
