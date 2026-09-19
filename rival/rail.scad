module octagon(d) {
  intersection_for(a = [0, 45])
  rotate([0, 0, a])
  square(d, center=true);
}

module hexagon(d) {
  circle(d=d*2/sqrt(3), $fn=6);
}

module rail_cavity() {
  reps = 10;
  length = reps * 10 + 5;
  plateau_thickness = 3.6;
  base_height = 3; 
  base_width = 12.8;
  
  // Base.
  translate([-base_width/2, 0, -0.001])
  linear_extrude(base_height + 0.002)
  square([base_width, length]);

  difference() {
    // Plateaus.
    translate([0, 0, base_height + plateau_thickness/2 - 0.2])
    rotate([-90, 0, 0])
    linear_extrude(length)
    hull()
    for (a = [-1, 1])
    translate([a * (18.9 - plateau_thickness) / 2, 0])
    octagon(plateau_thickness);
    
    // Valleys.
    for (a = [0:reps-1])
    translate([-15, 5 + 10*a])
    linear_extrude(15)
    square([30, 5]);
  }
  
  // Fillets at bottom of each valley.
  for (a = [0:reps*2-1])
  translate([0, 5+5*a, base_height])
  rotate([0, 90])
  rotate([0, 0, 45])
  cube([0.7, 0.7, base_width], center=true);
}

module screw_hole(length) {
  $fn = 20;
  
  // Shaft.
  linear_extrude(length)
  octagon(4.3);
  
  // Head.
  translate([0, 0, -3])
  linear_extrude(3.001)
  octagon(7.9);
  
  // Nut.
  translate([0, 0, length-0.001])
  rotate([0, 0, 30])
  linear_extrude(10)
  hexagon(8.9);
}

block_width = 27;
block_height = 15.3;

module block() {
  $fn = 16;
  width = 32;
  roundoff = 1.4;
  
  difference() {
    hull()
    for (a = [-1, 1], b = [0, 1], c = [0, 1])
    translate([
      a*(width/2-roundoff),
      5+roundoff+b*(55-2*roundoff),
      roundoff+c*30
    ])
    sphere(r=roundoff, $fn=20);
    
    translate([0, 0, block_height])
    linear_extrude(30)
    square(200, center=true);

    rail_cavity();

    for (y = [13.5, 54])
    translate([0, y])
    rotate([0, 0, 180])
    translate([2-width/2, 0, 9.8])
    rotate([0, 90, 0])
    screw_hole(width - 6.6);
  }
}

module cookie_cutter(complement=false) {
  tooth_depth = 2.5;
  tooth_width = 10;
  roundoff = 0.3;
  slack = 0.1;
  x_offset = 3;
  
  translate([0, -10])
  linear_extrude(30)
  offset(r=roundoff, $fn=16)
  offset(delta=-roundoff-slack)
  rotate([0, 0, complement ? 180 : 0])
  translate([x_offset * (complement ? 1 : -1), 0])
  difference() {
    translate([0.001-tooth_depth/2, -80])
    square([30, 160]);
    
    for (a = [-10:10])
    if ((a % 2 == 0 && a != 4) || a == -5)
    translate([-tooth_depth/2, a*tooth_width])
    square([tooth_depth, tooth_width]);
  }
}

dovetail_length = 24;
dovetail_depth = 4;

module dovetail() {
  intersection() {
    linear_extrude(dovetail_depth, scale=0.85)
    square([200, dovetail_length], center=true);
    
    cube([block_width, 100, 100], center=true);
  }

  linear_extrude(dovetail_depth+0.2)
  square([block_width, dovetail_length*0.85], center=true);
}

module piece(complement=false) {
  intersection() {
    difference() {
      block();
      
      // Dovetail slot for the accessory to be glued in.
      scale([2, 1, 1])
      for (y = 0.2 * [-1, 1])
      translate([0, 35+y, block_height-dovetail_depth])
      dovetail();
    }
    cookie_cutter(complement);
  }
}

module print_pieces() {
  piece();
  
  translate([-4, 0])
  piece(true);
}

module dovetail_test() {
  dovetail();
  translate([0, 0, dovetail_depth + 0.2])
  linear_extrude(3)
  square([30, 35], center=true);
}

render() print_pieces();
