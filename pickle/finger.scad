// A long enough distance in every direction from the originl.
universe = 170;

function finger_length() = 36;

finger_width = 12.15;
teeth_pairs = 6;

slack = 0.05;

module finger_profile_2d(complement=false, truncate=0) {
  if (complement) {
    rotate([0, 0, 180])
    difference() {
      hull() finger_profile_2d(truncate=truncate);
      finger_profile_2d(truncate=truncate);
    }
  } else {
    for (a = [-1, 1], b = [0:teeth_pairs-1])
    scale([a, 1])
    translate([b*(finger_width), 0])
    difference() {
      polygon([
        [0, -finger_length()/2],
        [finger_width, -finger_length()/2],
        // Apex.
        [
          finger_width/2 + (finger_width/5)*(b+1)/teeth_pairs,
          finger_length()/2
        ],
      ]);
      
      // Truncation.
      translate([-universe, finger_length()/2 - truncate])
      square([2*universe, universe]);
    }
  }
}

module finger_base_2d() {
  translate([-universe, -universe-finger_length()/2])
  square([2*universe, universe + 0.001]);
}

module finger_2d(complement=false, truncate=0) {
  difference() {
    offset(-slack)
    union() {
      finger_profile_2d(complement=complement, truncate=2+truncate);
      finger_base_2d();
    }
    finger_base_2d();
  }
}

module finger_cavity_2d(complement=false, truncate=0) {
  offset(slack)
  finger_profile_2d(complement, truncate=0.8+truncate);
}

linear_extrude(2) finger_2d();
color("blue") linear_extrude(1) finger_cavity_2d();