require_relative './renderer'

label_filename = ARGV.first

out = Renderer.new(xml: File.read(label_filename), params: {}).render
File.write('out.pdf', out)
