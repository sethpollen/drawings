include <common.scad>
include <screw.scad>

retention_plate_thickness = 1.2;
retention_plate_width = washer_od;
retention_plate_height = retention_plate_thickness * 3 + extra_loose;

retention_clip_length = 9;
retention_clip_width = retention_plate_width + 2*retention_plate_height;

// Plate which covers the ends of the pins.
module retention_plate(length) {
  dims = [retention_plate_width, length, 2*retention_plate_thickness];

  difference() {
    // Chamfer only the bottom.
    intersection() {
      chamfered_cube(dims, 0.4);
      translate([0, 0, -retention_plate_thickness])
        cube(dims);
    }
    
    translate([retention_plate_width/2, length/2, -eps]) {
      linear_extrude(10)
        octagon(screw_hole_id);
      linear_extrude(0.2)
        octagon(screw_hole_id + 0.4);
    }
  }
}

module retention_plate_clips(plate_length) {
  difference() {
    translate([-retention_plate_height, 0, -retention_plate_height + retention_plate_thickness]) {
      intersection() {
        translate([0, -plate_length/2, 0])
          chamfered_cube([
            retention_clip_width,
            plate_length*2,
            2*retention_plate_height
          ], retention_plate_height);
        for (y = [0, plate_length - retention_clip_length])
          translate([0, y, -retention_plate_height])
            cube([
              retention_clip_width,
              retention_clip_length,
              2*retention_plate_height
            ]);
      }      
    }
    
    // Cavity for the plate.
    translate([-extra_loose/2, -eps, -extra_loose + eps])
      cube([
        retention_plate_width + extra_loose,
        plate_length + 2*eps,
        retention_plate_thickness + extra_loose
      ]);
    
    // Pin holes.
    for (y = [0, plate_length - retention_clip_length])
      translate([retention_plate_width/2, retention_clip_length/2 + y, -5])
        linear_extrude(10)
          octagon(nail_loose_diameter);
  }
}

module retention_nut_hole(plate_length) {
  translate([retention_plate_width/2, plate_length/2, retention_plate_thickness-eps]) {
    rotate([0, 0, 90]) {
      nut_cavity();
      linear_extrude(10)
        octagon(screw_hole_id);
    }
  }
}
