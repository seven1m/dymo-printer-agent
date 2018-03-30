# Problem:
#
# There is a 10-12 second delay between each print job when printing labels on a Dymo LabelWriter
# (and probably other Dymo printers) via newer versions of Cups. This affects macOS High Sierra,
# Raspbian Linux, and probably other Linux distributions.
#
# This script is a hack to work around the problem by killing hung print processes once the label is finished printing.
#
# Script Usage:
#
#     sudo ruby dymo_speed.rb
#
# This is what you see when Dymo is printing:
#
#     $ ps aux | grep -i dymo
#     lp   6428 4.5 0.5 13244 5012 ?  S 18:03 0:00 DYMO_LabelWriter_450 63 ...
#     root 6429 3.0 0.4 37684 4596 ? Sl 18:03 0:00 usb://DYMO/LabelWriter%20450?serial=...
#
# This is what you see when the Dymo driver is sleeping, preventing the next print job from running:
#
#     $ ps aux | grep -i dymo
#     root 6429 3.0 0.4 37684 4596 ? Sl 18:03 0:00 usb://DYMO/LabelWriter%20450?serial=...
#
# When the second scenario is witnessed, kill -9 the driver so the next job can be processed.
#
loop do
  printing = false
  driver_pid = nil
  `ps aux | grep -i dymo`.split(/\n/).each do |line|
    parts = line.split
    pid = parts[1]
    name = parts[10]
    printing = true if name =~ /DYMO_/
    driver_pid = pid if name =~ %r{usb://}
  end
  if driver_pid && !printing
    `kill -9 #{driver_pid}`
    puts "#{driver_pid} was killed"
  end
  sleep 0.1
end
