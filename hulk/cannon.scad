eps = 0.0001;
$fn = 60;

barrel_diameter = 22;
barrel_offset = 12;
height = 21;
base_height = 2.8;
base_chamfer = 1.6;
cavity_diameter = 27;
diameter = cavity_diameter + 10;

module exterior() {
  linear_extrude(0.2)
    circle(diameter/2-0.3);

  translate([0, 0, 0.2])
    linear_extrude(base_height - 0.2)
      circle(diameter/2);
  
  translate([0, 0, base_height])
    linear_extrude(base_chamfer, scale=0.91)
      circle(diameter/2);
  
  translate([0, 0, height - base_height])
    scale([1, 1, -1])
      linear_extrude(base_chamfer, scale=0.91)
        circle(diameter/2);
  
  translate([0, 0, height - base_height])
    linear_extrude(base_height)
      circle(diameter/2);
  
  linear_extrude(height) {
    // Barrels.
    for (a = [0:5])
      rotate([0, 0, a*60])
        translate([barrel_offset, 0])
          circle(d=barrel_diameter/2);
  }
}

floor = 1.6;

module empty_2d() {
  difference() {
    circle(d=diameter-10);
    circle(d=diameter-18);
  }
  square([4.5, 25], center=true);
}

module cannon() {
  difference() {
    exterior();
    
    translate([0, 0, floor])
      linear_extrude(height)
        circle(d=cavity_diameter);
    
    chamfer = 2.2;
    translate([0, 0, height-chamfer])
      linear_extrude(chamfer+eps, scale=1.15)
        circle(d=cavity_diameter);
    
    translate([0, 0, -0.001]) {
      linear_extrude(0.2)
        offset(0.2)
          empty_2d();
      translate([0, 0, 0.2])
        linear_extrude(0.2)
          empty_2d();
    }
  }
}

cannon();