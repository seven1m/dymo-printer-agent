x_values = [
  [0.23, 330],
  [0.98, 1407.387],
  [2.72, 3916.708],
  [0.72, 1033.292]
]

y_values = [
  [0.69, 988.6232],
  [0.26, 379.3768],
  [0.05, 72],
  [0.26, 373.8765]
]

TWIP = 1440

x_values.each do |inches, points|
  p([inches, points, inches * TWIP])
end
