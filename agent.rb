require 'bundler/setup'
require 'sinatra'
require 'thin'
require 'builder'
require 'nokogiri'
require 'dymo_render'

class MyThinBackend < ::Thin::Backends::TcpServer
  def initialize(host, port, options)
    super(host, port)
    @ssl = true
    @ssl_options = options
  end
end

def render_options
  {
    fallback_font: ENV['FALLBACK_FONT']
  }
end

configure do
  set :environment, :production
  set :bind, '0.0.0.0'
  set :port, 41951
  set :server, "thin"
  class << settings
    def server_settings
      {
        :backend          => MyThinBackend,
        :private_key_file => File.dirname(__FILE__) + "/ca.key",
        :cert_chain_file  => File.dirname(__FILE__) + "/ca.crt",
        :verify_peer      => false
      }
    end
  end
end

get '/' do
  'dymo-printer-agent is running!'
end

get '/DYMO/DLS/Printing/StatusConnected' do
  content_type 'application/json'
  headers 'Access-Control-Allow-Origin' => '*'
  'true'
end

get '/DYMO/DLS/Printing/GetPrinters' do
  builder = Builder::XmlMarkup.new
  builder.instruct! :xml, version: '1.0', encoding: 'utf-8'
  xml = builder.Printers do |printers|
    `lpstat -s`.each_line do |line|
      next unless line =~ /device for ([^:]+)/
      name = $1
      next unless name =~ /dymo/i
      printers.LabelWriterPrinter do |printer|
        printer.Name(name)
        case line
        when /450.*turbo/i
          printer.ModelName('DYMO LabelWriter 450 Turbo')
        else
          printer.ModelName('DYMO LabelWriter 450')
        end
        printer.IsConnected('True')
        printer.IsLocal('True')
        printer.IsTwinTurbo('False')
      end
    end
  end
  content_type 'text/xml'
  headers 'Access-Control-Allow-Origin' => '*'
  xml.to_s
end

post '/DYMO/DLS/Printing/PrintLabel' do
  label_xml = params[:labelXml]
  details = Nokogiri::XML(params[:labelSetXml])
  details.css('LabelRecord').each do |label|
    record_params = Hash[label.css('ObjectData').map { |d| [d.attributes['Name'].value, d.text] }]
    renderer = DymoRender.new(xml: label_xml, params: record_params, options: render_options)
    result = renderer.render
    path = File.expand_path('out.pdf', __dir__)
    File.write(path, result)

    orientation = renderer.orientation
    media = "Custom.#{renderer.pdf_width}x#{renderer.pdf_height}"
    graphics_opt = " -o Resolution=300x600dpi -o DymoPrintQuality=Graphics" if renderer.has_graphics?
    puts `lpr -P #{params[:printerName]} -o #{orientation} -o media=#{media} #{graphics_opt} #{path}`
  end
  content_type 'application/json'
  headers 'Access-Control-Allow-Origin' => '*'
  'true'
end

