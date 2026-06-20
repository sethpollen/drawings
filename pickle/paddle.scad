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
max_thickness = 22;
min_thickness = 8;

grip_width = 34.6;
grip_thickness = 24.4;

// The grip is offset from the center of the wedge base. This "lifts" the grip
// away from the build plate, allowing more of its full profile to be printed.
grip_offset = 1;

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

grip_groove_floor = 6;
grip_tongue_width = 4.6;

// Default value, for convenience.
$grip_type = 0;

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
    gentle_top_curve=false,
    // Set this to a positive value to drop the piece on the left-hand
    // side, to add more stiffness where I don't need clearance for my
    // hand.
    left_y_drop=0
) {
  y_frac = y/wedge_length;
  thickness = (1 - y_frac)*max_thickness + y_frac*min_thickness;
  gentle_scale_factor = 0.72;

  intersection() {
    for (a = [-1, 1])   
    for (b = [-1, 1]) {
      gentle = (gentle_top_curve && a == 1 && b == 1);
      
      scale([a, 1, b * (gentle ? gentle_scale_factor : 1)])
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
  left_y_drop = [0, 5, 10, 15][i]; // TODO: more

  bridge_length = wedge_length + bridge_grip_overlap - fan_length;

  fan_piece(true,
    grip_width/2 + x_frac*0.5*(width-grip_width),
    bridge_length*(1-y_frac) - bridge_grip_overlap,
    gentle_top_curve=true, left_y_drop=left_y_drop);
}

// TODO: numeral "6" is not centered anymore.

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
    translate([-50, -50, max_thickness])
    cube([100, 100, 10]);
  }
}

knurl_depth = 0.4;
knurl_peak = 3.1;
knurl_slope = 0.5;
knurl_valley = 0.8;
knurl_segment_length = knurl_slope + knurl_peak + knurl_slope + knurl_valley;

// Values for `$grip_type`:
//   -1  Nothing at all.
//    0  Grip exterior.
//    1  Central tongue.
//    2  Central groove.
module grip_2d(knurl_inset=false) {
  flats = 10;
  bottom_sheet_width = 12;

  if ($grip_type == 0) {
    // This part is not inset when knurling. It ensures a continuous
    // bottom sheet for strength.
    translate([-bottom_sheet_width/2, max_thickness/2 - 1])
    square([bottom_sheet_width, 1]);
    
    offset(delta=knurl_inset ? -knurl_depth : 0)
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
  }

  if ($grip_type == 1)
  translate([0, max_thickness/2 - grip_thickness - 0.0001])
  hull() {
    translate([-0.4, 0])
    square([0.8, grip_thickness - grip_groove_floor]);
    
    square([grip_tongue_width, 0.0001], center=true);
  }
  
  groove_slack = 0.1;

  if ($grip_type == 2)
  offset(delta=groove_slack)
  grip_2d($grip_type=1);
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
  if (end && $grip_type != 0) {
    // Don't extend the tongue and groove all the way to the end.
  } else {
    z = i*knurl_segment_length;
        
    groove_end_slack = ($grip_type == 2) ? 0.2 : 0;
    extra_height = groove_end_slack * 2;
    
    scale([1, 1, -1])
    difference() {
      chain() {
        mklayer(bend_radius, z - groove_end_slack)
        grip_2d(knurl_inset=true);
        
        mklayer(bend_radius, z + knurl_slope)
        grip_2d();
        
        mklayer(bend_radius, z + knurl_slope + knurl_peak)
        grip_2d();
        
        mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope)
        grip_2d(knurl_inset=true);
        
        mklayer(bend_radius,
                z + knurl_slope + knurl_peak + knurl_slope +
                knurl_valley + extra_height + groove_end_slack)
        offset(delta=end ? -0.9 : 0)
        grip_2d(knurl_inset=true);
      }
      
      engrave_depth = 1.2;

      // Numeral on the base.
      if (end)
      bend_translate(bend_radius, z+knurl_segment_length-engrave_depth+0.3)
      translate([-7, 6])
      scale([1, -1])
      linear_extrude(engrave_depth)
      offset(0.3)
      text(str(mark_number), size=17);
    }
  }
}

module grip_stack(prog, i=0) {
  if (i < len(prog)) {
    // Radius of curvature for this section.
    r = prog[i][0];
    // Number of segments in this section.
    n = prog[i][1];
    
    // Optional parameter.
    end = (len(prog[i]) > 2) ? prog[i][2] : false;
    
    for (i = [0:n-1])
    knurl_segment(r, i, end=end);
   
    bend_translate(r, -n*knurl_segment_length)
    grip_stack(prog, i+1);
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
    grip_stack([[70, 9], [1000, 11], [27, 3], [-50, 1, true]]);
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

module bottom_template() {
  difference() {
    wedge();
  
    translate([0, 200 + middle_length])
    cube([400, 400, 70], center=true);
  }
  
  grip($grip_type=0);
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
    cube([400, 400, 30]);
    
    // Groove.
    grip($grip_type=2);
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

// TODO: Make the tongue much shallower, so it doesn't stiffen the
// grip. Really, the tongue could just be two pins to align the
// grip plate during gluing. It should have one deep pin at its
// upper end, to bind the grip layers together.
module grip_plate() {
  intersection() {
    bottom_template();

    union() {
      translate([-200, -200, max_thickness])
      cube([400, 200, 30]);
      
      grip($grip_type=1);
    }
  }
}

bottom();
