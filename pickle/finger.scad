// A long enough distance in every direction from the origin.
universe = 170;

function finger_length() = 36;

finger_width = 12.15;
teeth_pairs = 6;

xy_slack = 0.05;

layer_height = 0.2;

z_slack = 0.4;
finger_floor = 2.4;

module finger_profile_2d(complement=false, truncate=0) {
  if (complement) {
    rotate([0, 0, 180])
    difference() {
      // Take the complement, without any truncation.
      hull() finger_profile_2d();
      finger_profile_2d();
      
      // Apply truncation.
      translate([-universe, truncate - universe - finger_length()/2])
      square([2*universe, universe]);
    }
  } else {
    for (a = [-1, 1], b = [0:teeth_pairs-1])
    scale([a, 1])
    translate([b*finger_width, 0])
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
      translate([-universe, finger_length()/2 + truncate])
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
    offset(delta=-xy_slack)
    union() {
      finger_profile_2d(complement=complement, truncate=2.2+truncate);
      finger_base_2d();
    }
    finger_base_2d();
  }
}

module finger_cavity_2d(complement=false, truncate=0) {
  offset(delta=xy_slack)
  finger_profile_2d(complement, truncate=0.8+truncate);
}

module extrude_fingers(thickness, cavity, complement, rot=false) {  
  flat_tip = 2;
  bevel_height = (thickness - 2*finger_floor - 2*z_slack - flat_tip)/2;
  bevel_layers = floor(bevel_height / layer_height);
  
  for (a = [0:bevel_layers])
  translate([
    0,
    0,
    a*layer_height + finger_floor + (cavity ? 0 : z_slack)
  ])
  linear_extrude(
    thickness
    - a*layer_height*2
    - 2*finger_floor
    - (cavity ? 0 : 2*z_slack)
  )
  rotate([0, 0, rot ? 180 : 0]) {
    truncate = (bevel_layers-a)*0.06;
    
    if (cavity) {
      finger_cavity_2d(complement=complement, truncate=truncate);
    } else {
      intersection() {
        finger_2d(complement=complement, truncate=truncate);
        
        // Prevent the backs of the teeth from sticking out.
        translate([-200, -5])
        square([400, 100]);
      }
    }
  }
}
