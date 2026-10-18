mark_number = 8;
layer = 0.16;

// Parameters for the overall shape.
width = 199.5;
fan_length = 232;
fan_roundoff = 80;

// The length of the flat striking surface, before it hits the grip
// shelf. This is the part that has a tapered "wedge" shape.
wedge_length = 257;

bridge_grip_overlap = 20;

// Make a wedge shape.
function max_thickness() = 24;
function min_thickness() = 7.9;

grip_width = 34.6;

bridge_length = wedge_length + bridge_grip_overlap - fan_length;

wedge_angle = atan(
  (max_thickness() - min_thickness()) / (2 * wedge_length));
  
// Default values.
$grip_offs = 0;

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

module fan_piece(
    flip,
    x,
    y,
    // Set this to true for a shallower curve on the top.
    gentle=false
) {
  y_frac = y/wedge_length;
  thickness = (1 - y_frac)*max_thickness() + y_frac*min_thickness();

  intersection() {
    for (a = [-1, 1])   
    for (b = [-1, 1]) {
      gentle_factor =
          (gentle && a == 1 && b == 1) ? 0.72 // top right
        : gentle ? 0.86
        : 1;
      
      scale([a, 1, b])
      translate([x, y])
      scale([1, flip ? -1 : 1])
      scale([1, 1, gentle_factor])
      bulge_piece(bulge_radius(thickness, 45));
    }
    
    // Chop off anything that goes above the max_thickness. This avoids
    // flattening the gentle_top_curve when hull'ing with a taller piece.
    translate([-400, -400, max_thickness()/2-100])
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
    gentle=true
  );
}

module wedge() {
  difference() {
    // "Unwedge" the piece, so that one surface coincides with the xy-plane.
    rotate([-wedge_angle, 0, 0])
    translate([0, 0, max_thickness()/2])
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
      translate([0, 0, max_thickness()/2])
      rotate([-wedge_angle, 0, 0])
      translate([0, 0, 20])
      cube([width, 600, 40], center=true);
    }

    // Flatten the stem that intersects with the grip.
    translate([-100, -100, max_thickness()])
    cube([200, 200, 10]);
  }
}

module wedge_top_cut() {
  rotate([-wedge_angle, 0, 0])
  translate([0, 0, max_thickness()])
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
    scale([grip_width/2, (1.12*max_thickness() - flats)/2])
    circle($fn=18, r=1);
    
    // Cut off to meet the build plate.
    translate([-30, max_thickness()/2 - max_thickness()])
    square([60, max_thickness()]);
  }
}

module rotate_up(ra, twist=0) {
  r = ra[0];
  a = ra[1];
  rotate([0, 0, -twist])
  translate([r, 0])
  rotate([0, a, 0])
  translate([-r, 0])
  rotate([0, 0, twist])
  children();
}

module rotate_up_extrude(ra, twist=0) {
  r = ra[0];
  a = ra[1];
  rotate([0, 0, -twist])
  rotate([-90, 0])
  translate([r, 0])
  rotate_extrude(angle=a)
  translate([-r, 0])
  rotate([0, 0, twist])
  children();
}

module linear_extrude_eps(h) {
  eps = 0.001;
  translate([0, 0, -eps])
  linear_extrude(h + 2*eps)
  children();
}

knurl_groove_layers = 3;

// Width of the three steps, from deepest to shallowest.
knurl_groove_widths = [1.2, 1.7, 2.2];

module knurling_rays(groove_width, max_a=80) {
  translate([-100, 0, -0.001])
  for (a = [8.5:3.3:max_a])
  rotate([0, 0, -a])
  translate([0, -groove_width/2, -100])
  cube([200, groove_width, 200]);
}

module grip() {
  $fn = 40;
  
  // Twist the grip into the z-dimension.
  twist = -35;
  
  straight1 = 12;
  elbow1 = [70, 43];
  straight2 = 32.9;
  
  difference() {
    translate([0, 0, max_thickness()/2])
    rotate([90, 0, 0]) {
      // Add some length to make sure the grip smoothly meets the wedge. This
      // also makes the bottom axial groove extend into the wedge a bit,
      // avoiding correlated weak areas.
      straight_extension = 18;
      translate([0, 0, -straight_extension])
      linear_extrude_eps(straight1 + straight_extension) grip_2d();
            
      translate([0, 0, straight1])
      scale([-1, 1]) {
        rotate_up_extrude(elbow1, twist) grip_2d();

        rotate_up(elbow1, twist) {
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
    
    // Cut the part of the grip that would protrude above the hitting
    // surface.
    intersection() {
      wedge_top_cut();
      
      translate([0, 300])
      cube(600, center=true);
    }
  }
}

module knurled_grip() {
  scale([-1, 1]) {
    // Bottom of the grooves.
    grip($grip_offs=-knurl_groove_layers*layer);

    // Stair steps.
    for (i = [0:knurl_groove_layers-1])
    difference() {
      grip($grip_offs=-layer*(knurl_groove_layers-1-i));
      knurling_rays(knurl_groove_widths[i]);
    }
  }
}

// TODO: print this separately
module shelf() {
  shelf_width = 9;
  shelf_thickness = 4.6;
  shelf_chamfer = 0.9;
  
  // Narrow it slightly.
  scale([0.95, 1, 1])
  translate([0, 0, max_thickness()/2])
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
  translate([-grip_width*0.05, 0, max_thickness()-1])
  rotate([45, 0, 0])
  cube([grip_width*0.55, 3.3, 3.3], center=true);
}

module unibody() {
  difference() {
    color("cyan")
    wedge();
    
    // Cut the same knurling grooves into the fillet, to match the grip knurling
    // grooves.
    for (i = [0:knurl_groove_layers-1])
    for (a = [-1, 1])
    translate([0, 0, a * (max_thickness() - layer*(knurl_groove_layers-i))])
    knurling_rays(knurl_groove_widths[i], max_a=35);
  }

  difference() {
    knurled_grip();

    // Mark number.
    // TODO: fix this
    /*
    translate([-60, -99.2, 4.8]) // TUNED
    rotate([90, 0, -15])
    linear_extrude(10)
    offset(delta=0.7)
    text(str(mark_number), size=14.5);
    */
  }
}

// Position on the Neptune 4 Plus build plate.
module print_position() {
  translate([-40, -85])
  rotate([0, 0, -33])
  children();
}

// A large square that defines the model's bounding box. This helps Orca
// to place all of the modifiers in the proper alignment.
module positioning_square() {
  translate([0, 0, -1])
  linear_extrude(0.2)
  square(310, center=true);
}

unibody();
