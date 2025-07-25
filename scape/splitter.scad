hex_diam = 38.4;
hex_spacing = 82.8 - hex_diam;
slack = 0.25;
wall = 0.95;

hole_depth = 1.2;
height = 4;

// Allowed styles: 1, 2, 3
style = 3;

module hex_2d() {
  circle(d=hex_diam*sqrt(4/3), $fn=6);
}

module joint_2d() {
  translate([0, hex_spacing/2])
    square([hex_diam*sqrt(1/3), hex_spacing], center=true);
}

module hexes_2d() {
  if (style == 1) {
    for (a = [0:2])
      translate([0, a*hex_spacing])
        hex_2d();

    for (a = [0:3])
      translate([0, (2+a)*hex_spacing])
        rotate([0, 0, -60])
          translate([0, hex_spacing])
            hex_2d();
  }

  if (style == 2) {
    for (a = [0:1]) {
      translate([0, a*hex_spacing])
        hex_2d();
    
      translate([0, (1+a)*hex_spacing])
        rotate([0, 0, -60])
          translate([0, hex_spacing])
            hex_2d();
      
      translate([0, (2+a)*hex_spacing])
        rotate([0, 0, -60])
          translate([0, 2*hex_spacing])
            hex_2d();
    }
  }

  if (style == 3) {
    for (a = [0:5])
      translate([0, a*hex_spacing])
        hex_2d();
  }
}

module joints_2d() {
  if (style == 1) {
    for (a = [0:1])
      translate([0, a*hex_spacing])
        joint_2d();

    for (a = [0:2])
      translate([sqrt(3)/2*hex_spacing, (2.5+a)*hex_spacing])
        joint_2d();
    
    translate([0, 2*hex_spacing])
      rotate([0, 0, -60])
        joint_2d();
  }
  
  if (style == 2) {
    joint_2d();

    translate([0, hex_spacing])
      rotate([0, 0, -60])
        joint_2d();
    
    translate([sqrt(3)/2*hex_spacing, 1.5*hex_spacing])
      joint_2d();
    
    translate([0, 2*hex_spacing])
      rotate([0, 0, -60])
        translate([0, hex_spacing])
          joint_2d();
    
    translate([sqrt(3)*hex_spacing, 3*hex_spacing])
      joint_2d();
  }

  if (style == 3) {
    for (a = [0:4])
      translate([0, a*hex_spacing])
        joint_2d();
  }
}

module exterior_2d() {
  difference() {
    union() {
      hexes_2d();
      joints_2d();
    }
    offset(6, $fn=32)
      offset(-12)
        hexes_2d();
  }
}

module splitter() {
  difference() {
    union() {
      linear_extrude(0.20001)
        offset(slack + wall - 0.3, $fn=16)
          exterior_2d();
      translate([0, 0, 0.2])
        linear_extrude(height - 0.2)
          offset(slack + wall, $fn=16)
            exterior_2d();
    }
    translate([0, 0, height-hole_depth])
      linear_extrude(height)
        offset(slack, $fn=16)
          hexes_2d();
  }
}

splitter();
