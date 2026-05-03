// A long enough distance in every direction from the originl.
universe = 170;

finger_length = 40;
finger_width = 12;
teeth_pairs = 6;

slack = 0.05;

module finger_profile_2d(complement=false) {
  if (complement) {
    rotate([0, 0, 180])
    difference() {
      hull() finger_profile_2d();
      finger_profile_2d();
    }
  } else {
    for (a = [-1 :1], b = [0:teeth_pairs-1])
    scale([a, 1])
    translate([b*(finger_width), 0])
    polygon([
      [0, -finger_length/2],
      [finger_width, -finger_length/2],
      // Apex.
      [
        finger_width/2 + (finger_width/5)*(b+1)/teeth_pairs,
        finger_length/2
      ],
    ]);
  }
}

module finger_base_2d() {
  translate([-universe, -universe-finger_length/2])
  square([2*universe, universe + 0.001]);
}

module finger_2d(complement=false, truncate=0) {
  difference() {
    offset(-slack)
    union() {
      finger_profile_2d(complement);
      finger_base_2d();
    }
    
    // Truncation.
    translate([-universe, finger_length/2 - 2 - truncate])
    square([2*universe, universe]);
    
    finger_base_2d();
  }
}

module finger_cavity_2d(complement=false, truncate=0) {
  offset(slack)
  difference() {
    finger_profile_2d(complement);
    
    // Truncation.
    translate([-universe, finger_length/2 - 0.8 - truncate])
    square([2*universe, universe]);
  }
}

linear_extrude(2) finger_2d();
color("blue") linear_extrude(1) finger_cavity_2d();