
module face() {
  protrusion = 0.9;
  
  color("black")
  translate([0, 0, -protrusion])
  linear_extrude(8 + protrusion*2)
  scale([1, 1] * 0.094)
  offset(delta=1.3)
  projection()
  translate([-128, -128, 30])
  import("face.stl");
}

module cat() {
  rotate([90, 0, 0]) {
    color("orange")
    import("cat.stl");
  
    translate([12.6, 17.5])
    face();
  }
}

module kitten() {
  rotate([90, 0, 0]) {
    color("orange")
    import("kitty.stl");
  
    translate([51, 11])
    scale([1, 1] * 0.65)
    face();
  }
}

cat();
kitten();