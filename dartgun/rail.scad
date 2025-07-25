include <common.scad>

rail_notch_depth = 2.5;
rail_notch_length = 4;

// lug_type:
//   0 means no lug.
//   -1 means no lug and slightly recessed further.
//   1 means beveled.
//   2 means square.
module rail_2d(width, stem, lug_type) {
  translate([0, -stem/2 - 0.2, 0])
    square([width, stem - 0.4], center=true);
  
  difference() {
    hull()
      for (a = [-1, 1])
        scale([a, 1, 1])
          translate([width/2, 0, 0])
            rotate([0, 0, 45])
              square(rail_notch_depth*sqrt(2), center=true);
    
    // Square off the ends, to avoid sharp corners.
    for (a = [-1, 1])
      scale([a, 1, 1])
        translate([width/2 + rail_notch_depth, 0, 0])
          square(1, center=true);

    if (lug_type <= 0)
      translate([0, rail_notch_depth - (lug_type == -1 ? 0.4 : 0)])
        square([width+rail_notch_depth*4, rail_notch_depth*2], center=true);
  }
  
  if (lug_type == 2)
    translate([0, rail_notch_depth/2, 0])
      square([width + rail_notch_depth*2 - 1, rail_notch_depth], center=true);
}

module rail(width, length, stem, cavity=false) {
  repeats = floor(length / (2*rail_notch_length));
  
  intersection() {
    // Cut to just the desired length.
    cube([width+20, stem+20, length*2], center=true);
    
    for (a = [0:repeats]) {
      translate([0, 0, a*2*rail_notch_length]) {
        difference() {
          // High piece.
          translate([0, 0, cavity ? -snug/2 : 0])
            linear_extrude(rail_notch_length+eps + (cavity ? snug : 0))
              offset(cavity ? snug : 0)
                rail_2d(width, stem, cavity ? 2 : 1);

          // Chamfer edges.
          if (!cavity)
            for (z = [0, rail_notch_length])
              translate([0, rail_notch_depth, z])
                hull()
                  rotate([45, 0, 0])
                    cube(
                      [width*2, foot*sqrt(2), foot*sqrt(2)],
                      center=true
                    );
        }

        // Low piece.
        translate([0, 0, rail_notch_length])
          linear_extrude(rail_notch_length+eps)
            offset(cavity ? snug : 0)
              // When not cutting out a cavity, recess the low piece a bit
              // to make up for printing inaccuracies while bridging.
              rail_2d(width, stem, cavity ? 0 : -1);      
      }
    }
  }
}
