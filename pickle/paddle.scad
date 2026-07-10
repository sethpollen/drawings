use <finger.scad>

mark_number = 7;

// Parameters for the overall shape.
width = 200;
fan_length = 233;
fan_roundoff = 80;

// The length of the flat striking surface, before it hits the grip
// shelf. This is the part that has a tapered "wedge" shape.
wedge_length = 261;

bridge_grip_overlap = 20;

// Make a wedge shape.
max_thickness = 24.2;
min_thickness = 7.7;

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
$grip_knurl = false;
$grip_offs = 0;
$finger_notch = true;

tab_height = 0.45;
tab_x = 74; // TUNED

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
    // Extra translation to add on the left side, to strengthen the neck.
    left_xy=[0, 0]
) {
  y_frac = y/wedge_length;
  thickness = (1 - y_frac)*max_thickness + y_frac*min_thickness;

  intersection() {
    for (a = [-1, 1])   
    for (b = [-1, 1]) {
      gentle_factor =
          (gentle_right_curve && a == 1 && b == 1) ? 0.72 // top right
        : (gentle_right_curve && a == 1)           ? 0.86 // bottom right
        : (gentle_left_curve && a == -1 && b == 1) ? 0.86 // top left
        : (gentle_left_curve && a == -1)           ? 0.86 // bottom left
        : 1;
      
      translate((a == -1) ? left_xy : [0, 0])
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
  x_frac = [0.31, 0.166, 0.074, 0.02][i];
  y_frac = [0.28, 0.57, 0.8, 0.985][i];

  fan_piece(
    true,
    grip_width/2 + x_frac*0.5*(width-grip_width),
    bridge_length*(1-y_frac) - bridge_grip_overlap,
    gentle_right_curve=true,
    gentle_left_curve=(i>=3),
    left_xy=[
      [0, -1.5, -1.8, -1.8][i],
      [0, 0, -5, -10][i]
    ]
  );
}

// Fillet on the concave side of the grip, for strength at
// the weakest part of the whole paddle.
module fillet() {
  intersection() {
    hull()
    for (xy = [[0, 0], [2, -25]]) // TUNED
    translate(xy)
    intersection() {      
      // Take the left-hand piece of bridge(3).
      translate([-50, 0])
      cube(100, center=true);
      
      bridge(3);
    }
    
    // Cut to the right thickness.
    cube([200, 200, max_thickness], center=true);
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
  
  // Don't tilt the fillet by the wedge_angle.
  translate([0, 0, max_thickness/2])
  fillet();
}

module wedge_top_cut() {
  rotate([-wedge_angle, 0, 0])
  translate([0, 0, max_thickness])
  rotate([-wedge_angle, 0, 0])
  translate([0, 0, 20])
  cube([width, 600, 40], center=true);
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

knurl_groove_width = 1.4;
knurl_groove_depth = 0.45;

module knurling_rays(angle_end=95) {
  // Suppress special features when generating projections of the grip.
  $grip_knurl = false;
  $finger_notch = false;
  
  center_smooth_band = 13.2;
  
  difference() {
    translate([-110, -13, -1])
    for (a = [0:2.95:angle_end])
    if (a <= angle_end)
    rotate([0, 0, -a])
    cube([200, knurl_groove_width, max_thickness + 2]);
    
    // Fill the knurl grooves in the center of the top and bottom
    // surfaces, to ensure a continuous sheet to take the main
    // loads.
    for (depth_width = [[0.3, 1], [0.15, 0.75], [0, 0.5]])
    linear_extrude(max_thickness - depth_width[0])
    offset(delta=depth_width[1] * center_smooth_band/2 - grip_width/2)
    projection()
    grip();
  }
  
  // Central, axial groove on top and bottom.
  difference() {    
    linear_extrude(max_thickness+1)
    offset(delta=knurl_groove_width/2-grip_width/2)
    projection()
    grip();
    
    // Remove the part that would go past the shelf into the `top`.
    translate([-50, -1, -50])
    cube(100);
  }
}

module grip() {
  if ($grip_knurl) {
    $grip_knurl = false;

    // Apply knurling and then recurse.
    difference() {
      grip();
      
      intersection() {
        knurling_rays();
        
        difference() {
          grip($grip_offs=0.1);
          grip($grip_offs=-knurl_groove_depth);
        }
      }
    }
  } else {
    $fn = 40;
    
    straight1 = 12;
    elbow1 = [70, 39];
    straight2 = 63;
    
    translate([0, 0, max_thickness/2])
    rotate([90, 0, 0]) {
      // Add some length to make sure the grip smoothly meets the wedge. This
      // also makes the bottom axial groove extend into the wedge a bit,
      // avoiding correlated weak areas.
      straight_extension = 18;
      translate([0, 0, -straight_extension])
      linear_extrude_eps(straight1 + straight_extension) grip_2d();
            
      translate([0, 0, straight1])
      scale([-1, 1]) {
        rotate_up_extrude(elbow1) grip_2d();
        
        // Finger notch.
        if ($finger_notch)
        rotate_up(elbow1 - [0, 10.4])
        hull() {
          chamfer = 1.8;
          peak_thickness = 1;
          peak_height = 2.9;
          
          translate([0, 0, -chamfer])
          linear_extrude_eps(chamfer*2 + peak_thickness)
          intersection() {
            grip_2d();
            
            // Chop the negative-x area, to avoid a protrusion on the opposite
            // side caused by the `translate` above.
            translate([50, 0]) square(100, center=true);
          }
          
          linear_extrude_eps(peak_thickness)
          translate([peak_height, 0])
          grip_2d();
        }

        rotate_up(elbow1) {
          linear_extrude_eps(straight2) grip_2d();
          
          translate([0, 0, straight2])
          intersection() {
            // The final elbow is the intersection of two different
            // extrusions, which lets us taper the end.
            rotate_up_extrude([32, 115], $fn=19) grip_2d();
            
            tight_r = 14;
            rotate_up_extrude([tight_r, 180], $fn=22)
            intersection() {
              grip_2d();
              // Avoid a negative x-coordinate for the tight
              // rotate_extrude.
              translate([tight_r-grip_width/2, 0])
              square(grip_width, center=true);
            }
          }
        }
      }
    }
  }
}

module shelf() {
  shelf_width = 9;
  shelf_thickness = 4.6;
  shelf_chamfer = 0.9;
  
  // Narrow it slightly.
  scale([0.95, 1, 1])
  translate([0, 0, max_thickness/2])
  rotate([90, 0, 0])
  hull() {
    translate([0, shelf_width, 0]) {
      linear_extrude(shelf_thickness)
      grip_2d($grip_offs=-shelf_chamfer);
      
      translate([0, 0, shelf_chamfer])
      linear_extrude(shelf_thickness-2*shelf_chamfer)
      grip_2d();
    }
    
    linear_extrude(shelf_thickness + 7)
    grip_2d($grip_offs=-shelf_chamfer);
  }
  
  // Fill the angle between the shelf and surface, just a little bit.
  translate([-grip_width*0.05, 0, max_thickness-1])
  rotate([45, 0, 0])
  cube([grip_width*0.55, 3.3, 3.3], center=true);
}

module wedge_and_grip() {
  wedge();
  grip();
}

// Causes generation of internal floors and ceilings, but
// now alls.
perforation_width_small = 0.2;

// Generates walls.
perforation_width_large = 0.5;

// Make sure the top sheet continues under the shelf.
module shelf_perforations() {
  thickness = 0.15; // 1 layer.
  
  intersection() {
    shelf();
    
    difference() {
      translate([0, 0, thickness])
      wedge_and_grip();
      
      wedge_and_grip();
    }

    for (y = [-15:1.5:5])
    translate([0, y, 20])
    cube([40, perforation_width_small, 40], center=true);
  }
}

module strength_perforations_bounding_box() {
  scale([1, -1])
  translate([-150, -23])
  square([300, 105]);
}

// Add material at the corners of the neck.
module strength_perforations_fence() {
  inset = 9;

  linear_extrude(max_thickness+1)
  difference() {
    intersection() {
      strength_perforations_bounding_box();

      offset(delta=-inset)
      projection() wedge_and_grip();
    }
    intersection() {
      strength_perforations_bounding_box();

      offset(delta=-inset-perforation_width_large)
      projection() wedge_and_grip();
    }
  }
}

// Perforations along the four corners of the neck, to add material for
// strength.
module strength_perforations() {
  depth = 1.5;
  thickness = 0.15; // 1 layer.
  
  // Top perforation.
  difference() {
    intersection() {
      strength_perforations_fence();
      translate([0, 0, -depth]) wedge_and_grip();
    }
    translate([0, 0, -depth-thickness])
    wedge_and_grip();
  }
  
  // Bottom perforation.
  difference() {
    intersection() {
      strength_perforations_fence();
      translate([0, 0, depth]) wedge_and_grip();
    }
    translate([0, 0, depth+thickness])
    wedge_and_grip();
  }
}

module bottom_perforations() {
  shelf_perforations();
  strength_perforations();
}

// Chamfer the bottom edge at the finger joint. This avoids elephant
// foot in a critical area.
module joint_chamfer() {
  w = 0.49;
  rotate([45, 0, 0])
  cube([250, w, w], center=true);
}

lock_hole_play = 0.05;

// A hole through which I can insert a piece of filament, to lock the two
// parts together while the epoxy sets.
module lock_hole() {
  translate([-width/2, middle_length-2.5, finger_thickness/2])
  rotate([0, 90, 0])
  linear_extrude(width)
  // A strand of filament is nominally 1.75mm. Allow some play, but not much.
  // A bit more play vertically, where the tightness doesn't matter.
  scale([1.75, 1.75] + [0.6, 0.2])
  // Octagonal cross-section.
  intersection_for(a = [0, 45])
  rotate([0, 0, a])
  square(1, center=true);
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
    difference() {
      extrude_fingers(thickness=finger_thickness,
                      cavity=false, complement=true, rot=true);
      
      translate([0, -middle_length-lock_hole_play])
      lock_hole();
    }

    // Tabs.
    linear_extrude(tab_height)
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
      
      grip($grip_knurl=true);
    }
    
    translate([0, lock_hole_play])
    lock_hole();
    
    // Cut the parts of the grip and fillet that go above the wedge surface.
    wedge_top_cut();
    
    translate([0, middle_length]) {
      joint_chamfer();

      // Negative fingers.
      extrude_fingers(thickness=finger_thickness,
                      cavity=true, complement=true, rot=true);
    }

    // Mark number.
    translate([-71, -124.8, 4.8]) // TUNED
    rotate([90, 0])
    linear_extrude(10)
    offset(delta=0.7)
    text(str(mark_number), size=14.5);
    
    // Knurl the top and bottom surfaces, to align with the grip knurl
    // grooves.
    intersection() {
      knurling_rays(angle_end=25);

      for(z = [0, max_thickness])
      translate([0, 0, z])
      cube([500, 500, knurl_groove_depth*2], center=true);
    }
  }
  
  difference() {
    shelf();
    
    // Extend the central knurl groove under the shelf, for more
    // strength.
    translate([
      -0.2,
      -25,
      max_thickness-knurl_groove_depth+0.001
    ])
    cube([0.5, 20, knurl_groove_depth]);
  }
  
  translate([0, middle_length]) {
    // Positive fingers.
    extrude_fingers(thickness=finger_thickness,
                    cavity=false, complement=false);

    // Tabs.
    linear_extrude(tab_height)
    for (a = [-1, 1])
    translate([a*tab_x, 0])
    circle(d=10);
  }
}

bottom();