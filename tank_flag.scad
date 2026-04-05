// Use 0.15mm layers.
linear_extrude(1.65) {
  square([1.7, 16]);

  translate([0, 9])
  square([8, 7]);
  
  translate([1.7, 9])
  rotate([0, 0, 45])
  square(2.1, center=true);
}