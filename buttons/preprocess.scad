render()
linear_extrude(1)
difference() {
  translate([0.001, 0.001])
  square([191, 81]);
  
  projection(cut=true)
  translate([0, 0, -50])
  surface("scan4.png");
}
