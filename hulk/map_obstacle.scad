// From puzz2.scad.
s = 30.2;

height = 2.2;

preview = false;

module raster(matrix) {
  for (a = [0 : len(matrix)])
  for (b = [0 : len(matrix[a])])
  if (matrix[a][b] == 1)
  translate(s * [a, b])
  square(s + 0.0001, center=true);
}

module piece(matrix) {
  inset = 3.6;
  roundoff = 1.5;
  
  // Assume 0.2mm layers.
  linear_extrude(height)
  offset(r=roundoff, $fn=30)
  offset(delta=-inset-roundoff)
  raster(matrix);
  
  if(preview)
  translate([0, 0, -1])
  color("green")
  linear_extrude(1)
  raster(matrix);
}

piece([[1]]);
//piece([[1, 1]]);
