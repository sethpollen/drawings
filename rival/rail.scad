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

module piece() {
  width = 27;
  roundoff = 1.4;
  
  difference() {
    linear_extrude(15)
    translate([-width/2, 5])
    offset(r=roundoff, $fn=16)
    offset(delta=-roundoff)
    square([width, 75]);

    rail_cavity();

    for (y = [15, 65])
    translate([2-width/2, y, 9.8])
    rotate([0, 90, 0])
    screw_hole(width - 4);
  }
}

module cookie_cutter(complement=false) {
  tooth_depth = 5;
  tooth_width = 10;
  roundoff = 0.3;
  slack = 0.1;
  
  linear_extrude(30)
  offset(r=roundoff, $fn=16)
  offset(delta=-roundoff-slack)
  rotate([0, 0, complement ? 180 : 0])
  translate([2 * (complement ? 1 : -1), 0])
  difference() {
    translate([0.001-tooth_depth/2, -80])
    square([30, 160]);
    
    for (a = [-8:7])
    translate([-tooth_depth/2, a*tooth_width*2])
    square([tooth_depth, tooth_width]);
  }
}

module test(complement=false) {
  intersection() {
    piece();
    cookie_cutter(complement);
  }
}

module print() {
  test();

  difference() {
    test(true);
    
    translate([-25, 23, 10])
    linear_extrude(20)
    square([50, 14]);
  }
}

render()
print();