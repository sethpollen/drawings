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

grip_width = 34.6;

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
  
// Default values.
$grip_offs = 0;

// Set to false to make computation cheaper.
enable_knurl = false;

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
    gentle_left_curve=false,
    // Extra width to add on the left side, to strengthen the neck.
    left_x=0
) {
  y_frac = y/wedge_length;
  thickness = (1 - y_frac)*max_thickness + y_frac*min_thickness;

  intersection() {
    for (a = [-1, 1])   
    for (b = [-1, 1]) {
      gentle =
        (gentle_right_curve && a == 1) ||
        (gentle_left_curve && a == -1);
      gentle_factor =
        !gentle ? 1 // No gentle curve.
        // More gentle on top than on the bottom.
        : (b == 1) ? 0.72 : 0.86;
      
      translate([(a == -1) ? -left_x : 0, 0])
      scale([a, 1, b])
      translate([x, y])
      scale([1, flip ? -1 : 1])
      scale([1, 1, gentle_factor])
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

  fan_piece(true,
    grip_width/2 + x_frac*0.5*(width-grip_width),
    bridge_length*(1-y_frac) - bridge_grip_overlap,
    gentle_right_curve=true,
    gentle_left_curve=(i>=3),
    left_x=(1.8*i));
}

// Fillet on the concave side of the grip, for strength at
// the weakest part of the whole paddle.
module fillet() {
  rotate([0, 0, 5])
  translate([-5, 0])
  intersection() {
    hull()
    for (y = [15, -16])
    translate([0, y])
    fan_piece(true,
      grip_width/2 + 0.03*0.5*(width-grip_width),
      bridge_length*(1-0.945) - bridge_grip_overlap - 15,
      gentle_left_curve=true);
    
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

module grip_2d() {
  flats = 11;
  
  offset(delta=$grip_offs)
  intersection() {
    // Main profile, rounded on both sides.
    hull()
    for (a = [-1, 1])
    scale([1, a])
    translate([0, flats/2])
    scale([grip_width/2, (1.12*max_thickness - flats)/2])
    circle($fn=18, r=1);
    
    // Cut off to meet the build plate.
    translate([-30, max_thickness/2 - max_thickness])
    square([60, max_thickness]);
  }
}

// TODO: more pronounced hook at the end of the grip.

// TODO: engrave numeral on base

// TODO: add shelf to grip. 9mm wide.

module rotate_up(ra) {
  r = ra[0];
  a = ra[1];
  translate([r, 0])
  rotate([0, a, 0])
  translate([-r, 0])
  children();
}

module rotate_up_extrude(ra) {
  r = ra[0];
  a = ra[1];
  rotate([-90, 0])
  translate([r, 0])
  rotate_extrude(angle=a)
  translate([-r, 0])
  children();
}

module linear_extrude_eps(h) {
  eps = 0.001;
  translate([0, 0, -eps])
  linear_extrude(h + 2*eps)
  children();
}

knurl_groove_width = 0.9;
knurl_groove_depth = 0.3;

module knurling_rays(angle_start=0) {
  translate([-120, 0, -1])
  for (a = [0:1.9:95])
  if (a >= angle_start)
  rotate([0, 0, -a])
  cube([200, knurl_groove_width, max_thickness + 2]);
}

module grip(knurl=enable_knurl) {
  if (knurl) {
    // Apply knurling and then recurse.
    difference() {
      grip(knurl=false);
      
      intersection() {
        knurling_rays();
        
        difference() {
          grip(knurl=false, $grip_offs=0.1);
          grip(knurl=false, $grip_offs=-knurl_groove_depth);
        }
      }
    }
  } else {
    $fn = 40;
    
    straight1 = 9.8;
    elbow1 = [70, 39];
    straight2 = 63;
    elbow2 = [30, 120];
    
    translate([0, 0, max_thickness/2])
    rotate([90, 0, 0])
    {
      linear_extrude_eps(straight1) grip_2d();
      translate([0, 0, straight1])
      // Bend right.
      scale([-1, 1]) {
        rotate_up_extrude(elbow1) grip_2d();
        rotate_up(elbow1) {
          linear_extrude_eps(straight2) grip_2d();
          translate([0, 0, straight2]) {
            rotate_up_extrude(elbow2) grip_2d();
          }
        }
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
    
    // Knurl the top and bottom, to align with the grip knurl grooves.
    if (enable_knurl)
    intersection() {
      knurling_rays(3);
      for(z = [0, max_thickness])
      translate([0, 0, z])
      cube([500, 500, knurl_groove_depth*2], center=true);
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