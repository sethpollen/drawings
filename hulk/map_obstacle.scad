// From puzz2.scad.
s = 30.2;

preview = false;

module raster(matrix) {
  for (a = [0 : len(matrix)])
  for (b = [0 : len(matrix[a])])
  if (matrix[a][b] == 1)
  translate(s * [a, b])
  square(s + 0.0001, center=true);
}

module piece(matrix) {
  linear_extrude(6)
  offset(delta=-4.9)
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
  select(3, [0, 0]);
  select(0, [1, 1]);
  select(3, [2, 0]);
  select(0, [3, 1]);
  select(1, [0, 2]);
  select(1, [1, 2]);
  select(2, [2, 2]);
  select(2, [3, 2]);
}

print();