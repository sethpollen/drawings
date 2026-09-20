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

dovetail_width = 23;
dovetail_length = 24;
dovetail_depth = 4;
dovetail_height = dovetail_depth + 0.2;

module dovetail_2d(retract) {
  $fn = 16;
  
  offset(r=retract?1:0)
  offset(delta=retract?-1:0)
  square([dovetail_width, dovetail_length], center=true);
}

module dovetail(retract=true) {
  scal = 0.82;
  
  difference() {
    union() {
      intersection() {
        // Scale 0.85
        hull() {
          linear_extrude(0.6)
          dovetail_2d(retract);
          
          translate([0, 0, dovetail_depth])
          linear_extrude(1e-6)
          scale([1, scal])
          dovetail_2d(retract);
        }
      }

      linear_extrude(dovetail_height)
      scale([1, scal])
      dovetail_2d(retract);
    }
    
    if (retract)
    for (a = [-3:3])
    translate([0, a*3])
    cube([40, 0.8, 0.4], center=true);
  }
}

module block_piece(complement=false) {
  intersection() {
    difference() {
      block();
      
      // Dovetail slot for the accessory to be glued in.
      for (x = 0.18*[-1, 1], y = 0.2*[-1, 1])
      translate([x, 35+y, block_height-dovetail_depth])
      dovetail(false);
    }
    cookie_cutter(complement);
  }
}

module print_block_pieces() {
  block_piece();
  
  translate([-4, 0])
  block_piece(true);
}

module tombstone_2d(width, height) {
  translate([0, height-width/2])
  difference() {
    circle(d=width);

    translate([0, -50])
    square(100, center=true);
  }
  
  translate([-width/2, 0])
  square([width, height-width/2 + 0.001]);
}

hood_height = 24;
hood_length = 11;
crosshair_elevation = 12;
crosshair_width = 0.7;

module hood_2d() {
  $fn = 40;
  
  wall = 1.5;
  
  difference() {
    tombstone_2d(dovetail_width, hood_height);
    
    translate([0, -wall])
    tombstone_2d(dovetail_width-2*wall, hood_height);
  }
}

module sight() {
  dovetail();

  translate([0, dovetail_length/2, dovetail_height])
  rotate([90, 0]) {
    linear_extrude(hood_length)
    hood_2d();
    
    // Slopes.
    intersection() {
      translate([0, 0, hood_length])
      linear_extrude(30)
      hood_2d();

      translate([0, -49, 0])
      rotate([40, 0])
      cube(100, center=true);
    }
    
    // Crosshairs.
    linear_extrude(5) {
      translate([0, crosshair_elevation])
      square([dovetail_width, crosshair_width], center=true);
        
      translate([-crosshair_width/2, 0])
      square([crosshair_width, crosshair_elevation]);
    }
  }
}

render()
sight();