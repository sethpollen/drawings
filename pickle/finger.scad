// A long enough distance in every direction from the origin.
universe = 170;

function finger_length() = 36;

finger_width = 12.15;
teeth_pairs = 6;
finger_floor = 2.2;

xy_slack = 0.1;
z_slack = 0.6;

module finger_profile_2d(complement, additional_end_chop=0) {
  if (complement) {
    rotate([0, 0, 180])
    difference() {
      hull() finger_profile_2d(false, additional_end_chop);
      finger_profile_2d(false, additional_end_chop);
    }
  } else {
    for (a = [-1, 1])
    scale([a, 1]) {
      for (b = [0:teeth_pairs-1])
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
      }
      
      // Shorten the outer tooth, so it fits within the taper of the
      // bottom piece.
      chop_length = 7.4 + additional_end_chop; // TUNED
      
      translate([(teeth_pairs-1)*finger_width, -finger_length()/2])
      difference() {
        translate([-5, 0])
        square([10, chop_length*2]);
        
        translate([0, 30/sqrt(2)+chop_length])
        rotate([0, 0, 45])
        square(30, center=true);
      }
    }
  }
}

module finger_base_2d() {
  translate([-universe, -universe-finger_length()/2])
  square([2*universe, universe + 0.001]);
}

module finger_2d(complement) {
  difference() {
    offset(delta=-xy_slack)
    union() {
      // Withdraw the chopped teeth slightly, so they have plenty of room.
      finger_profile_2d(complement, additional_end_chop=0.4);
      finger_base_2d();
    }
    finger_base_2d();
  }
}

module finger_cavity_2d(complement) {
  offset(delta=xy_slack)
  finger_profile_2d(complement);
}

module extrude_fingers(thickness, cavity, complement, rot=false) {
  difference() {
    translate([0, 0, finger_floor + (cavity ? 0 : z_slack)])
    rotate([0, 0, rot ? 180 : 0])
    linear_extrude(
      thickness
      - 2*finger_floor
      - (cavity ? 0 : 2*z_slack)
    ) {    
      if (cavity) {
        finger_cavity_2d(complement);
      } else {
        intersection() {
          finger_2d(complement);
          
          // Truncate the tips of the teeth, and prevent the backs from
          // sticking out.
          translate([-200, -1])
          square([400, 1 + finger_length()/2 - 3.2]);
        }
      }
    }
  }
}

module finger_test(separation=0) {
  width = 145;
  thickness = 15;
  depth = 21;

  // "bottom"
  translate([0, -separation]) {
    difference() {
      translate([-width/2, -depth])
      cube([width, depth, thickness]);
      
      rotate([45, 0, 0])
      cube([250, 0.49, 0.49], center=true);

      extrude_fingers(thickness=thickness, cavity=true, complement=true, rot=true);
    }
    extrude_fingers(thickness=thickness, cavity=false, complement=false);
  }
  
  // "top"
  translate([0, separation]) {
    difference() {
      translate([-width/2, 0])
      cube([width, depth, thickness]);

      rotate([45, 0, 0])
      cube([250, 0.49, 0.49], center=true);

      extrude_fingers(thickness=thickness, cavity=true);
    }
    extrude_fingers(thickness=thickness, cavity=false, complement=true, rot=true);
  }
}
