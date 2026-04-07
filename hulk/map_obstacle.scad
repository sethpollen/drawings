// From puzz2.scad.
s = 30.2;

height = 14;

preview = false;

module raster(matrix) {
  for (a = [0 : len(matrix)])
  for (b = [0 : len(matrix[a])])
  if (matrix[a][b] == 1)
  translate(s * [a, b])
  square(s + 0.0001, center=true);
}

module piece(matrix) {
  bottom_inset = 4;
  top_inset = 7.5;
  steps = height*5;
  step_inset = (top_inset-bottom_inset)/(steps-1);
  roundoff = 1.5;
  
  // Assume 0.2mm layers.
  for (i = [0:steps-1])
  translate([0, 0, i*0.2])
  linear_extrude(0.20001)
  offset(r=roundoff, $fn=30)
  offset(delta=-bottom_inset-i*step_inset-roundoff)
  raster(matrix);
  
  if(preview)
  translate([0, 0, -1])
  color("green")
  linear_extrude(1)
  raster(matrix);
}

module select(i, pos) {
  translate(s*pos) {
    if (i == 0) piece([[1]]);
    if (i == 1) piece([[1, 1]]);
    if (i == 2) piece([[1, 1, 1]]);
    if (i == 3) piece([[1, 1],
                       [1]]);
  }
}

module print() {
  select(0, [0, 2]);
  select(1, [1, 1]);
  select(2, [2, 0]);
  select(3, [0, 0]);
}

print();