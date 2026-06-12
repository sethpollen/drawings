use <finger.scad>

mark_number = 4;

// Parameters for the overall shape.
width = 200;
fan_length = 225;
fan_roundoff = 69;

// The length of the flat striking surface, before it hits the grip
// shelf. This is the part that has a tapered "wedge" shape.
wedge_length = 251;

bridge_grip_overlap = 20;

// Make a wedge shape.
max_thickness = 20;
min_thickness = 8;

grip_width = 34.8;
grip_thickness = 24.7;

// The grip is offset from the center of the wedge base. This "lifts" the grip
// away from the build plate, allowing more of its full profile to be printed.
grip_offset = 1.9;

// Parameter for slicing into printable sections.
top_length = 216 - finger_length()/2;

// The distance between the two critical points: The shelf and the finger joint.
middle_length = wedge_length - top_length;

// Linear interpolation.
finger_thickness =
  min_thickness*middle_length/wedge_length +
  max_thickness*top_length/wedge_length;
  
wedge_angle = atan(
  (max_thickness - min_thickness) / (2 * wedge_length));

grip_groove_floor = 5;
grip_tongue_width = 4.4;

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

module fan_piece(flip, x, y, gentle_top_curve=false) {
  y_frac = y/wedge_length;
  thickness = (1 - y_frac)*max_thickness + y_frac*min_thickness;
  gentle_scale_factor = 0.72;

  for (a = [-1, 1])
  for (b = [-1, (gentle_top_curve && a == 1) ? gentle_scale_factor : 1])
  scale([a, 1, b])
  translate([x, y])
  scale([1, flip ? -1 : 1])
  bulge_piece(bulge_radius(thickness, 45));
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

  bridge_length = wedge_length + bridge_grip_overlap - fan_length;

  fan_piece(true,
    grip_width/2 + x_frac*0.5*(width-grip_width),
    bridge_length*(1-y_frac) - bridge_grip_overlap,
    gentle_top_curve=true);
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
    translate([-30, -30, max_thickness])
    cube([60, 60, 10]);
  }
}

knurl_depth = 0.4;
knurl_peak = 3.1;
knurl_slope = 0.5;
knurl_valley = 0.8;
knurl_segment_length = knurl_slope + knurl_peak + knurl_slope + knurl_valley;

// Values for `type`:
//   -1 Nothing at all.
//   0  Grip exterior.
//   1  Central tongue.
//   2  Central groove.
module grip_2d(type=0) {
  flats = 10;

  if (type == 0)
  intersection() {
    // Main profile, rounded on both sides.
    translate([0, -grip_offset])
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

  if (type == 1)
  translate([0, max_thickness/2 - grip_thickness - 0.0001])
  hull() {
    translate([-0.4, 0])
    square([0.8, grip_thickness - grip_groove_floor]);
    
    square([grip_tongue_width, 0.0001], center=true);
  }
  
  // TODO: also need to take in the ends of the tongue.
  if (type == 2)
  offset(delta=0.1)
  grip_2d(type=1);
}

module bend_translate(r, z) {
  translate([-r, 0, 0])
  rotate([0, -360*z/(2*PI*r), 0])
  translate([r, 0, 0])
  children();
}

module mklayer(r, z) {
  bend_translate(r, z)
  linear_extrude(0.07)
  children();
}

module knurl_segment(bend_radius, i, type=0, x_scale=1, end=false) {
  z = i*knurl_segment_length;
  knurl_offs = (type == 0) ? -knurl_depth : 0;
  
  scale([(type == 0) ? x_scale : 1, 1, -1])
  difference() {
    chain() {
      mklayer(bend_radius, z)
      offset(delta=knurl_offs)
      grip_2d(type=type);
      
      mklayer(bend_radius, z + knurl_slope)
      grip_2d(type=type);
      
      mklayer(bend_radius, z + knurl_slope + knurl_peak)
      grip_2d(type=type);
      
      mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope)
      offset(delta=knurl_offs)
      grip_2d(type=type);
      
      mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope + knurl_valley)
      offset(delta=knurl_offs + (end ? -0.9 : 0))
      grip_2d(type=type);
    }

    letter_depth = 1;
    
    if (end)
    bend_translate(bend_radius, z+knurl_segment_length-letter_depth+0.1)
    translate([-7, 6])
    scale([1, -1])
    linear_extrude(letter_depth)
    offset(0.3)
    text(str(mark_number), size=17);
  }
}

module grip(type=0) {
  segments = 26;
  
  r1 = 1000;
  p1 = 2;
  
  r2 = 77;
  p2 = 9;

  r3 = 1000;
  p3 = segments - p1 - p2;
  
  shelf_width = 8.8;
  
  translate([0, 0, max_thickness/2])
  rotate([-90, 0, 0]) {
    // Form the shelf.
    hull() {
      translate([0, max_thickness/2])
      scale([1, (max_thickness + shelf_width)/grip_thickness])
      translate([0, -max_thickness/2])
      knurl_segment(r1, 0, type=type);
    
      knurl_segment(r1, 1, type=type);
    }
    
    bend_translate(r1, -p1*knurl_segment_length) {
      for (i = [0:p2-1])
      knurl_segment(r2, i, type=type);
      
      bend_translate(r2, -p2*knurl_segment_length)
      for (i = [0:p3-1]) {
        // No tongue for the last segment.
        mytype = (type == 0) ? 0
               : (i < p3-1) ? type
               : -1;
        
        knurl_segment(r3, i,
          type=mytype,
          // Make a slight pommel.
          x_scale=(
              (i == p3-1)
            ? 1.08
            : (i == p3-2)
            ? 1.04
            : 1
          ),
          end=(i == p3-1)
        );
      }
    }
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
      translate([0, top_length-wedge_length])
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

module bottom_template() {
  translate([0, middle_length])
  difference() {
    translate([0, top_length-wedge_length]) {
      wedge();
      grip();
    }
  
    translate([0, 200])
    cube([400, 400, 100], center=true);
  }
}

module bottom() {
  difference() {
    bottom_template();

    translate([0, middle_length]) {
      joint_chamfer();

      // Negative fingers.
      extrude_fingers(thickness=finger_thickness,
                      cavity=true, complement=true, rot=true);
    }
    
    // Cut off the grip piece.
    translate([-200, -200, max_thickness])
    cube([400, 400, 100]);
    
    // Groove.
    grip(type=2);
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

// TODO: use this
/*
module upper_sheet() {
  sheet_width = width + 20;
  back_up = 2;
  thickness = 15;
  
  // Tilted sheet over the paddle face.
  translate([0, 0, 0.001]) // Don't actually intersect the face.
  rotate([-wedge_angle, 0, 0])
  translate([0, 0, max_thickness])
  rotate([-wedge_angle, 0, 0])
  translate([-sheet_width/2, -back_up, 0])
  cube([sheet_width, 300+back_up, thickness]);
  
  // Horizontal sheet over the grip.
  translate([-sheet_width/2, -180, max_thickness])
  cube([sheet_width, 180, thickness]);
}
*/


module grip_plate() {
  intersection() {
    translate([0, middle_length])
    bottom_template();

    union() {
      translate([-200, -200, max_thickness])
      cube([400, 400, 100]);
      
      grip(type=1);
    }
  }
}

wedge();
