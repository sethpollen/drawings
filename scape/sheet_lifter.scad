// Use 0.2mm layers.

hole_spacing = 216;
$fn = 40;
height = 1.4;

module exterior_2d() {
  diam = 30;
  
  hull() {
    for (a = [-1, 1]) {
      translate([0, a*hole_spacing/2])
        circle(d=diam);
      
      translate([hole_spacing/5, a*hole_spacing/6])
        circle(d=diam);
    }
  }
}

module holes_2d() {
  for (a = [-1, 0, 1])
    translate([0, a*hole_spacing/2])
      hull()
        for (b = [-1, 0])
          translate([b*6-2, 0])
            circle(d=6);
}

module profile_2d() {
  difference() {
    exterior_2d();
    holes_2d();
  }
}

module main() {
  rotate([0, 0, 35]) {
    linear_extrude(0.2)
      offset(-0.3)
        profile_2d();
    translate([0, 0, 0.2])
      linear_extrude(height-0.2)
        profile_2d();
  }
}

main();