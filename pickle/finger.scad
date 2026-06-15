// A long enough distance in every direction from the origin.
universe = 170;

function finger_length() = 36;

finger_width = 12.15;
teeth_pairs = 6;
finger_floor = 2;

// TODO: previously this was 0.05.
xy_slack = 0.1;

// TODO: previously this was 0.4. That worked for PLA. But I suspect PETG
// sags more when bridging, so we need 0.6.
//
// TODO: print a test of the revised finger joint.
z_slack = 0.6;

module finger_profile_2d(complement) {
  if (complement) {
    rotate([0, 0, 180])
    difference() {
      hull() finger_profile_2d(false);
      finger_profile_2d(false);
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
      chop_length = 6; // TUNED
      
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
      finger_profile_2d(complement);
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
    rotate([0, 0, rot ? 180 : 0]) {
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
  
    // Slightly taper the tops of the teeth. Otherwise, the joint wants to
    // bend concavely upwards. I'm not sure why. I guess it has to do with
    // the inaccuracies of bridging over the cavities.
    //
    // TODO: decide whether this asymmetry is needed. It could be motivated
    // by the fact that I can file the bottom of the teeth but not the
    // ceiling of the tooth cavity.
    //
    //if (!cavity)
    //translate([0, 2])
    //rotate([-2.9, 0, rot ? 180 : 0])
    //translate([0, 15, 2 + thickness - finger_floor - z_slack])
    //cube([200, 30, 4], center=true);
  }
}

module finger_test_bottom() {
  width = 160;
  thickness = 15;
  separation = 1;

  // "bottom"
  translate([0, -separation]) {
    difference() {
      translate([-width/2, -30])
      cube([width, 30, thickness]);

      extrude_fingers(thickness=thickness, cavity=true, complement=true, rot=true);
    }
    extrude_fingers(thickness=thickness, cavity=false, complement=false);
  }
  
  // "top"
  translate([0, separation]) {
    difference() {
      translate([-width/2, 0])
      cube([width, 30, thickness]);
        
      extrude_fingers(thickness=thickness, cavity=true);
    }
    extrude_fingers(thickness=thickness, cavity=false, complement=true, rot=true);
  }
}

finger_test_bottom();
