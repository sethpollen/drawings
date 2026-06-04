use <finger.scad>

mark_number = 4;

// Parameters for the overall shape.
width = 200;
fan_length = 223;
fan_roundoff = 69;

// The length of the flat striking surface, before it hits the grip
// shelf. This is the part that has a tapered "wedge" shape.
wedge_length = 251;

bridge_grip_overlap = 20;

// Make a wedge shape.
max_thickness = 20;
min_thickness = 9;

grip_thickness = 27;

// The grip is offset from the center of the wedge base. This "lifts" the grip
// away from the build plate, allowing more of its full profile to be printed.
grip_offset = 1.8;

// Parameter for slicing into printable sections.
top_length = 215 - finger_length()/2;

// Linear interpolation.
finger_thickness =
  min_thickness*(wedge_length - top_length)/wedge_length +
  max_thickness*top_length/wedge_length;

wedge_angle = atan(
  (max_thickness - min_thickness) / (2 * wedge_length));

grip_width = 35;

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
  // A quarter slice of a sphere.
  translate([-r, -r])
  rotate_extrude($fn=16, angle=90)
  intersection() {
    circle($fn=24, r=r);
    
    translate([r, 0])
    square(r*2, center=true);
  }
}

module fan_piece(flip, x, y) {
  y_frac = y/wedge_length;
  thickness = (1 - y_frac)*max_thickness + y_frac*min_thickness;

  for (a = [-1, 1])
  scale([a, 1])
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
  intercept_angle = 52;
  x_frac = [0.28, 0.18, 0.083, 0.03][i];
  y_frac = [0.38, 0.57, 0.8  , 0.95 ][i];

  bridge_length = wedge_length + bridge_grip_overlap - fan_length;

  fan_piece(true,
    grip_width/2 + x_frac*0.5*(width-grip_width),
    bridge_length*(1-y_frac) - bridge_grip_overlap);
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

knurl_depth = 0.5;
knurl_peak = 3.1;
knurl_slope = 0.5;
knurl_valley = 0.8;
knurl_segment_length = knurl_slope + knurl_peak + knurl_slope + knurl_valley;

module grip_2d(offs=0) {
  flats = 10;
    
  offset(delta=offs)
  intersection() {
    // Main profile, rounded on both sides.
    translate([0, -grip_offset])
    hull()
    for (a = [-1, 1])
    scale([1, a])
    translate([0, flats/2])
    scale([grip_width/2, (grip_thickness-flats)/2])
    intersection() {
      circle($fn=18, r=1);
      
      translate([0, 2])
      square(4, center=true);
    }
    
    // Cut off to meet the build plate.
    translate([-50, max_thickness/2 - knurl_depth -100])
    square(100);
  }
}

module bend_translate(r, z) {
  translate([r, 0, 0])
  rotate([0, 360*z/(2*PI*r), 0])
  translate([-r, 0, 0])
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
      mklayer(bend_radius, z) grip_2d();
      mklayer(bend_radius, z + knurl_slope) grip_2d(offs=knurl_depth);
      mklayer(bend_radius, z + knurl_slope + knurl_peak) grip_2d(offs=knurl_depth);
      mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope) grip_2d();
      
      mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope + knurl_valley)
      offset(delta=(end ? -0.9 : 0))
      grip_2d();
    }
    
    letter_depth = 1.6;
    
    if (end)
    bend_translate(bend_radius, z+knurl_segment_length-letter_depth+0.05)
    translate([-7, 6])
    scale([1, -1])
    linear_extrude(letter_depth)
    offset(0.3)
    text(str(mark_number), size=17);
  }
}

module grip() {
  segments = 27;
  
  r1 = 1000;
  p1 = 2;
  
  r2 = 90;
  p2 = 10;

  r3 = 1000;
  p3 = segments - p1 - p2;
  
  shelf_width = 8.8;
  
  // Form the shelf.
  hull() {
    translate([0, grip_thickness - max_thickness - grip_offset - shelf_width])
    knurl_segment(r1, 0);
  
    knurl_segment(r1, 1);
  }
  
  bend_translate(r1, -p1*knurl_segment_length) {
    for (i = [0:p2-1])
    knurl_segment(r2, i);
    
    bend_translate(r2, -p2*knurl_segment_length)
    for (i = [0:p3-1])
    knurl_segment(r3, i, end=(i==p3-1));
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
    translate([a*77, 0])
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
    translate([a*77, 0])
    circle(d=10);
  }
}

// Sheets to modify infill.
module sheets() {
  sheet_width = width + 20;
  sheet_length = 300;

  bottom_sheet_intrusion = 6*0.2;
  top_sheet_intrusion = 7*0.2;
  back_up_top_sheet = 4;

  translate([-sheet_width/2, 0, 0]) {
    // Bottom sheet.
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
      20
     ]);
  }
}

bottom();
