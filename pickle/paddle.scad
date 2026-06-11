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

// Linear interpolation.
finger_thickness =
  min_thickness*(wedge_length - top_length)/wedge_length +
  max_thickness*top_length/wedge_length;
  
echo(finger_thickness);

wedge_angle = atan(
  (max_thickness - min_thickness) / (2 * wedge_length));

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
}

module flatten_wedge() {
  // "Unwedge" the piece, so that one surface coincides with the xy-plane.
  rotate([-wedge_angle, 0, 0])
  children();
}  

knurl_depth = 0.4;
knurl_peak = 3.1;
knurl_slope = 0.5;
knurl_valley = 0.8;
knurl_segment_length = knurl_slope + knurl_peak + knurl_slope + knurl_valley;

module grip_2d() {
  flats = 10;
    
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

module knurl_segment(bend_radius, i, x_scale=1, end=false) {
  z = i*knurl_segment_length;
  
  scale([x_scale, 1, -1])
  difference() {
    chain() {
      mklayer(bend_radius, z)
      offset(delta=-knurl_depth)
      grip_2d();
      
      mklayer(bend_radius, z + knurl_slope)
      grip_2d();
      
      mklayer(bend_radius, z + knurl_slope + knurl_peak)
      grip_2d();
      
      mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope)
      offset(delta=-knurl_depth)
      grip_2d();
      
      mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope + knurl_valley)
      offset(delta=(end ? -0.9 : 0) - knurl_depth)
      grip_2d();
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

module grip() {
  segments = 26;
  
  r1 = 1000;
  p1 = 2;
  
  r2 = 77;
  p2 = 9;

  r3 = 1000;
  p3 = segments - p1 - p2;
  
  shelf_width = 8.8;
  
  // Form the shelf.
  hull() {
    translate([0, max_thickness/2])
    scale([1, (max_thickness + shelf_width)/grip_thickness])
    translate([0, -max_thickness/2])
    knurl_segment(r1, 0);
  
    knurl_segment(r1, 1);
  }
  
  bend_translate(r1, -p1*knurl_segment_length) {
    for (i = [0:p2-1])
    knurl_segment(r2, i);
    
    bend_translate(r2, -p2*knurl_segment_length)
    for (i = [0:p3-1])
    knurl_segment(r3, i,
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

// Chamfer the bottom edge at the finger joint. This avoids elephant
// foot in a critical area.
module joint_chamfer() {
  w = 0.49;
  rotate([45, 0, 0])
  cube([250, w, w], center=true);
}

module top() {
  translate([0, wedge_length-top_length]) {
    difference() {
      translate([0, top_length-wedge_length])
      flatten_wedge()
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
  translate([0, wedge_length-top_length]) {
    difference() {
      translate([0, top_length-wedge_length]) {
        flatten_wedge()
        wedge();

        translate([0, 0, max_thickness/2])
        rotate([-90, 0, 0])
        grip();
      }
    
      translate([0, 200])
      cube([400, 400, 100], center=true);

      joint_chamfer();

      // Negative fingers.
      extrude_fingers(thickness=finger_thickness,
                      cavity=true, complement=true, rot=true);
    }
  
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

// Sheets to modify infill.
module sheets() {
  sheet_width = width + 20;
  sheet_length = 300;

  bottom_sheet_intrusion = 6*0.2;
  top_sheet_intrusion = 7*0.2;
  back_up_top_sheet = 3;
  back_up_bottom_sheet = back_up_top_sheet + 11;

  translate([-sheet_width/2, 0, 0]) {
    // Bottom sheet.
    translate([0, -back_up_bottom_sheet])
    cube([sheet_width, sheet_length, bottom_sheet_intrusion]);
    
    // Top sheet.
    translate([0, 0, -top_sheet_intrusion])
    rotate([-wedge_angle, 0, 0])
    translate([0, 0, max_thickness])
    rotate([-wedge_angle, 0, 0])
    translate([0, -back_up_top_sheet, 0])
    cube([
      sheet_width,
      sheet_length+back_up_top_sheet,
      3
     ]);
  }
  
  // Add an ornament on the top to help us align the sheets with the piece
  // to be printed.
  hull()
  translate([-10, wedge_length - top_length, max_thickness - 1]) {
    cube([20, 1, 20]);
    
    translate([0, 20])
    cube([20, 1, 5]);
  }
}

// Block to add one extra floor layer to the grip.
module grip_block() {
  cube([400, 400, 1.8]);
}

bottom();