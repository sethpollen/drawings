upscale = 1.13;
thicken = upscale + 0.03;

module face() {
  protrusion = 0.65;
  
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
  scale([upscale, thicken, upscale])
  rotate([90, 0, 0]) {
    color("orange")
    linear_extrude(8)
    projection()
    import("cat.stl");
  
    translate([12.6, 17.5])
    face();
  }
}

module kitten_2d() {
  projection()
  import("kitty.stl");
}

module kitten_2d_shorttail() {
  intersection() {
    kitten_2d();
    square([100, 18]);
  }
  translate([0, -3])
  difference() {
    kitten_2d();
    square([100, 18]);
  }
}

module kitten() {
  scale([upscale, thicken, upscale])
  rotate([90, 0, 0])
  translate([-8, 0]) {
    color("orange")
    linear_extrude(8)
    kitten_2d_shorttail();
  
    translate([51, 10.6])    
    scale([1, 1] * 0.68)
    face();
  }
}

module print() {
  cat();
  kitten();
}

print();