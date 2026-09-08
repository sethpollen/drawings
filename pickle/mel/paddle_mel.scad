mark_number = 9;
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
function max_thickness() = 20.7;
function min_thickness() = 7.9;

grip_width = 30;

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

module fan_piece(flip, x, y, gentle_curve=false) {
  y_frac = y/wedge_length;
  thickness = (1 - y_frac)*max_thickness() + y_frac*min_thickness();

  intersection() {
    for (a = [-1, 1])   
    for (b = [-1, 1]) {
      gentle_factor = gentle_curve ? 0.86 : 1;
      
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
    gentle_curve=(i>=3)
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
  flats = 6;
  
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

module linear_extrude_eps(h) {
  eps = 0.001;
  translate([0, 0, -eps])
  linear_extrude(h + 2*eps)
  children();
}

knurl_groove_layers = 3;

// Width of the three steps, from deepest to shallowest.
knurl_groove_widths = [1.2, 1.7, 2.2];

module knurling_rays(groove_width) {
  translate([-100, 0, -0.001])
  for (a = [8.5:5:100])
  translate([0, -a-groove_width/2, 0])
  cube([200, groove_width, max_thickness() + 0.002]);
}

grip_straight1 = 102;
grip_straight2 = 5;
knob = 1.06;

module grip() {
  $fn = 40;
    
  difference() {
    translate([0, 0, max_thickness()/2])
    rotate([90, 0, 0]) {
      straight_extension = 18;
      translate([0, 0, -straight_extension])
      linear_extrude_eps(grip_straight1 + straight_extension) grip_2d();
      
      translate([0, 0, grip_straight1]) {
        linear_extrude(1, scale=knob) grip_2d();
        
        translate([0, 0, 1])
        linear_extrude_eps(grip_straight2 - 2)
        scale([1, 1] * knob)
        grip_2d();
          
        translate([0, 0, grip_straight2 - 1])
        linear_extrude(1, scale=1/knob)
        scale([1, 1]* knob)
        grip_2d();
      }
    }
    
    // Cut the part of the grip that would protrude above the hitting
    // surface.
    wedge_top_cut();
  }
}

module knurled_grip() {
  // Bottom of the grooves.
  grip($grip_offs=-knurl_groove_layers*layer);

  // Stair steps.
  for (i = [0:knurl_groove_layers-1])
  difference() {
    grip($grip_offs=-layer*(knurl_groove_layers-1-i));
    knurling_rays(knurl_groove_widths[i]);
  }
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
    knurling_rays(knurl_groove_widths[i]);
  }

  difference() {
    knurled_grip();

    // Mark number.
    translate([-5.5, 2-grip_straight1-grip_straight2, 3.2]) // TUNED
    rotate([90, 0, 0])
    linear_extrude(10)
    offset(delta=0.4)
    text(str(mark_number), size=14.2);
  }
  
  // Make the knurl grooves slightly shallower on the top and
  // bottom surfaces, for a more continuous sheet.
  intersection() {
    grip($grip_offs=layer*(1-knurl_groove_layers));

    for(z = [0, max_thickness()])
    translate([0, 0, z])
    cube([500, 500, knurl_groove_layers*layer*2], center=true);
  }
}

// Position on the Neptune 4 Plus build plate.
module print_position() {
  translate([-65, -65])
  rotate([0, 0, -45])
  children();
}

// A large square that defines the model's bounding box. This helps Orca
// to place all of the modifiers in the proper alignment.
module positioning_square() {
  translate([0, 0, -1])
  linear_extrude(0.2)
  square(310, center=true);
}

positioning_square();
print_position() unibody();
