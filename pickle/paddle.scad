use <finger.scad>

mark_number = 6;

// Parameters for the overall shape.
width = 200;
fan_length = 225;
fan_roundoff = 69;

// The length of the flat striking surface, before it hits the grip
// shelf. This is the part that has a tapered "wedge" shape.
wedge_length = 251;

bridge_grip_overlap = 20;

// Make a wedge shape.
max_thickness = 24;
min_thickness = 8;

// TODO: add interior voids at the corners of the neck, for strength

// TODO: get rid of grip_plate; print shelf directly onto bottom. Include
// interior voids to ensure a continuous upper sheet.

// TODO: rework knurling or use grip tape

grip_width = 34.6;

// TODO: simplify; this is now the same as max_thickness
grip_thickness = 24;

// Parameter for slicing into printable sections.
top_length = 216 - finger_length()/2;

// The distance between the two critical points: The shelf and the finger joint.
middle_length = wedge_length - top_length;

bridge_length = wedge_length + bridge_grip_overlap - fan_length;

// Linear interpolation.
finger_thickness =
  min_thickness*middle_length/wedge_length +
  max_thickness*top_length/wedge_length;
  
wedge_angle = atan(
  (max_thickness - min_thickness) / (2 * wedge_length));

grip_groove_floor = 6;
grip_tongue_width = 4.6;

tab_x = 73; // TUNED

function bulge_radius(thickness, intercept_angle) =
  thickness / (2 * sin(intercept_angle));

module chain() {
  if ($children >= 2)
  for (i = [0:$children-2])
  hull() {
    children(i);
    children(i+1);
  }
}

module bulge_piece(r) {
  // A 1/8th slice of a sphere.
  translate([-r, -r])
  rotate_extrude($fn=16, angle=90)
  intersection() {
    circle($fn=24, r=r);
    
    translate([r, r])
    square(r*2, center=true);
  }
}

module fan_piece(flip, x, y,
    // Set this to true for a shallower curve on the top, for the right
    // hand thumb to rest in. This only shows up on one side.
    gentle_right_curve=false,
    // Set this to a positive value to drop the piece on the left-hand
    // side, to add more stiffness where I don't need clearance for my
    // hand.
    left_y_drop=0
) {
  y_frac = y/wedge_length;
  thickness = (1 - y_frac)*max_thickness + y_frac*min_thickness;

  intersection() {
    for (a = [-1, 1])   
    for (b = [-1, 1]) {
      gentle_factor =
        (!gentle_right_curve || a != 1) ? 1 // No gentle curve.
        // More gentle on top than on the bottom.
        : (b == 1) ? 0.72 : 0.86;
      
      scale([a, 1, b * gentle_factor])
      translate([x, y - left_y_drop * (a == -1 ? 1 : 0)])
      scale([1, flip ? -1 : 1])
      bulge_piece(bulge_radius(thickness, 45));
    }
    
    // Chop off anything that goes above the max_thickness. This avoids
    // flattening the gentle_top_curve when hull'ing with a taller piece.
    translate([-400, -400, max_thickness/2-100])
    cube([800, 800, 101]);
  }
}

module fan(base_only=false) {  
  hull()
  for (angle = [0:10:90]) {
    x = width/2 + fan_roundoff*(sin(angle)-1);
    
    // Top edges.
    if (!base_only)
    fan_piece(false, x,
      wedge_length + fan_roundoff*(cos(angle)-1));
    
    // Bottom edges.
    if (angle >= 50)
    fan_piece(true, x,
      wedge_length - fan_length + fan_roundoff*(1-cos(angle)));
  }
}

// `i` should be in the range [0, 3].
module bridge(i) {
  x_frac = [0.31, 0.166, 0.074, 0.03][i];
  y_frac = [0.28, 0.57, 0.8, 0.945][i];
  left_y_drop = 4*i;

  fan_piece(true,
    grip_width/2 + x_frac*0.5*(width-grip_width),
    bridge_length*(1-y_frac) - bridge_grip_overlap,
    gentle_right_curve=true,
    left_y_drop=left_y_drop);
}

// Fillet on the concave side of the grip, for strength at
// the weakest part of the whole paddle.
module fillet() {
  intersection() {
    hull()
    for (y = [15, -11])
    translate([-0.5, y])
    fan_piece(true,
      grip_width/2 + 0.03*0.5*(width-grip_width),
      bridge_length*(1-0.945) - bridge_grip_overlap - 15);
    
    translate([-200, 0])
    cube(400, center=true);
  }
}

module wedge() {
  difference() {
    // "Unwedge" the piece, so that one surface coincides with the xy-plane.
    rotate([-wedge_angle, 0, 0])
    translate([0, 0, max_thickness/2])
    difference() {
      union() {
        fan();
        
        chain() {
          fan(base_only=true);
          bridge(0);
          bridge(1);
          bridge(2);
          bridge(3);
        }
        
        fillet();
      }   
    
      // Cut in the wedge surface.
      for (a = [-1, 1])
      scale([1, 1, a])
      translate([0, 0, max_thickness/2])
      rotate([-wedge_angle, 0, 0])
      translate([0, 0, 20])
      cube([width, 600, 40], center=true);
    }

    // Flatten the stem that intersects with the grip.
    translate([-100, -100, max_thickness])
    cube([200, 200, 10]);
  }
}

knurl_depth = 0.4;
knurl_peak = 3.1;
knurl_slope = 0.5;
knurl_valley = 0.8;
knurl_segment_length = knurl_slope + knurl_peak + knurl_slope + knurl_valley;

module grip_2d(knurl_inset=false) {
  flats = 10;
  bottom_sheet_width = 12;

  // This part is not inset when knurling. It ensures a continuous
  // bottom sheet for strength.
  translate([-bottom_sheet_width/2, max_thickness/2 - 1])
  square([bottom_sheet_width, 1]);
  
  offset(delta=knurl_inset ? -knurl_depth : 0)
  intersection() {
    // Main profile, rounded on both sides.
    hull()
    for (a = [-1, 1])
    scale([1, a])
    translate([0, flats/2])
    scale([grip_width/2, (1.12*grip_thickness - flats)/2])
    intersection() {
      circle($fn=18, r=1);
      
      translate([0, 2])
      square(4, center=true);
    }
    
    // Cut off to meet the build plate.
    translate([-30, max_thickness/2 - grip_thickness])
    square([60, grip_thickness]);
  }
}

module bend_translate(r, z) {
  translate([-r, 0, 0])
  rotate([0, -360*z/(2*PI*r), 0])
  translate([r, 0, 0])
  children();
}

module mklayer(r, z) {
  bend_translate(r, z)
  linear_extrude(0.01)
  children();
}

module knurl_segment(bend_radius, i, end=false) {
  z = i*knurl_segment_length;
  
  scale([1, 1, -1])
  difference() {
    chain() {
      mklayer(bend_radius, z)
      grip_2d(knurl_inset=true);
      
      mklayer(bend_radius, z + knurl_slope)
      grip_2d();
      
      mklayer(bend_radius, z + knurl_slope + knurl_peak)
      grip_2d();
      
      mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope)
      grip_2d(knurl_inset=true);
      
      mklayer(bend_radius,
              z + knurl_slope + knurl_peak + knurl_slope + knurl_valley)
      offset(delta=end ? -0.9 : 0)
      grip_2d(knurl_inset=true);
    }
    
    engrave_depth = 1.2;

    // Numeral on the base.
    if (end)
    bend_translate(bend_radius, z+knurl_segment_length-engrave_depth+0.3)
    translate([-6, 6])
    scale([1, -1])
    linear_extrude(engrave_depth)
    offset(0.3)
    text(str(mark_number), size=15);
  }
}

grip_prog = [[70, 9], [1000, 11], [27, 3], [-50, 1, true]];

module grip_stack(i=0) {
  if (i < len(grip_prog)) {
    // Radius of curvature for this section.
    r = grip_prog[i][0];
    // Number of segments in this section.
    n = grip_prog[i][1];
    
    // Optional parameter.
    end = (len(grip_prog[i]) > 2) ? grip_prog[i][2] : false;
    
    for (i = [0:n-1])
    knurl_segment(r, i, end=end);
   
    bend_translate(r, -n*knurl_segment_length)
    grip_stack(i+1);
  }
}

module grip() {
  shelf_r = 1000;
  shelf_n = 2;
  
  shelf_width = 9;
  
  translate([0, 0, max_thickness/2])
  rotate([-90, 0, 0]) {
    // Form the shelf.
    hull() {
      translate([0, max_thickness/2])
      scale([1, (max_thickness + shelf_width)/grip_thickness])
      translate([0, -max_thickness/2])
      knurl_segment(shelf_r, 0);
    
      knurl_segment(shelf_r, 1);
    }
    
    bend_translate(shelf_r, -shelf_n*knurl_segment_length)
    grip_stack();
  }
}

// Chamfer the bottom edge at the finger joint. This avoids elephant
// foot in a critical area.
module joint_chamfer() {
  w = 0.49;
  rotate([45, 0, 0])
  cube([250, w, w], center=true);
}

module top() {
  translate([0, middle_length]) {
    difference() {
      translate([0, -middle_length])
      wedge();
        
      translate([0, -200])
      cube([400, 400, 100], center=true);

      joint_chamfer();

      // Negative fingers.
      extrude_fingers(thickness=finger_thickness,
                      cavity=true);
    }
      
    // Positive fingers.
    extrude_fingers(thickness=finger_thickness,
                    cavity=false, complement=true, rot=true);
      
    // Tabs.
    linear_extrude(0.4)
    for (a = [-1, 1])
    translate([a*tab_x, 0])
    circle(d=10);
  }
}

module bottom() {
  difference() {
    // Combine the wedge and grip.
    union() {
      difference() {
        wedge();
      
        // Cut off the `top`.
        translate([0, 200 + middle_length])
        cube([400, 400, 70], center=true);
      }
      
      grip();
    }

    translate([0, middle_length]) {
      joint_chamfer();

      // Negative fingers.
      extrude_fingers(thickness=finger_thickness,
                      cavity=true, complement=true, rot=true);
    }
  }
  
  translate([0, middle_length]) {
    // Positive fingers.
    extrude_fingers(thickness=finger_thickness,
                    cavity=false, complement=false);

    // Tabs.
    linear_extrude(0.4)
    for (a = [-1, 1])
    translate([a*tab_x, 0])
    circle(d=10);
  }
}

bottom();