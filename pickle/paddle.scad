use <finger.scad>

// TODO: remove this: length = 357;

// Parameters for the overall shape.
width = 200;
fan_length = 223;
fan_roundoff = 69;

// The length of the flat striking surface, before it hits the grip
// shelf. This is the part that has a tapered "wedge" shape.
wedge_length = 251;

bridge_grip_overlap = 20;

// Make a wedge shape.
max_thickness = 21;
min_thickness = 9;

// Has to be tweaked manually.
finger_thickness = 18.4;

wedge_angle = atan(
  (max_thickness - min_thickness) / (2 * wedge_length));

// Parameters for slicing into printable sections.
top_length = 211 - finger_length()/2;

handle_width = 35;

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
    handle_width/2 + x_frac*0.5*(width-handle_width),
    bridge_length*(1-y_frac) - bridge_grip_overlap);
}

module wedge() {
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
}

/*

// `part` should be 0 or 1. Part 0 has the fingers. Part 1 has the underside
// of the grip.
module bottom_impl(part=0) {
  unwedge() {
    difference() {
      whole();
      
      translate([0, 200])
      cube([400, 400, 100], center=true);

      // Negative fingers.
      if (part == 0)
      extrude_fingers(thickness=thickness,
                      cavity=true, complement=true, rot=true);
    }
    
    // Positive fingers.
    if (part == 0)
    extrude_fingers(thickness=thickness,
                    cavity=false, complement=false);
  }
  
  // The grip is not inside the "unwedge", so it is not aligned with the center
  // axis of the paddle. I think that is OK. The grip is aligned with the
  // "backhand" surface of the paddle.
  translate([0, 0, thickness/2 + 1])
  rotate([-90, 0, 0])
  grip();
}

// TODO: actually there is no part 1. For now I will just print part 0 and see how
// it works. It yields a slightly weird grip shape, but it is very simple. It avoids
// any joints in the critical area. It avoids the added weight of another glue
// joint. And it avoids any rough, supported surfaces on the grip (which might
// not feel good in the hand).
module bottom_part_cut() {
  translate([0, -200, -200])
  cube(400, center=true);
}

module bottom(part=0) {
  if (part == 0) {
    difference() {
      bottom_impl(part);
      
      // TODO: need to line this up correctly.
      joint_chamfer();
      
      bottom_part_cut();
    }
  } else {
    intersection() {
      bottom_impl(part);
      bottom_part_cut();
    }
  }
}

*/

knurl_depth = 0.5;
knurl_peak = 3.1;
knurl_slope = 0.5;
knurl_valley = 0.8;
knurl_segment_length = knurl_slope + knurl_peak + knurl_slope + knurl_valley;

module grip_2d(offs=0) {
  flats = 10;
  grip_thickness = 26;
  
  // The grip is offset from the center of the wedge base. This "lifts" the grip
  // away from the build plate, allowing more of its full profile to be printed.
  grip_offset = 1;
  
  offset(delta=offs)
  intersection() {
    // Main profile, rounded on both sides.
    translate([0, -grip_offset])
    hull()
    for (a = [-1, 1])
    scale([1, a])
    translate([0, flats/2])
    scale([handle_width/2, (grip_thickness-flats)/2])
    intersection() {
      circle($fn=30, r=1);
      
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
  linear_extrude(0.0001)
  children();
}

module knurl_segment(bend_radius, i, chamfer=false) {
  z = i*knurl_segment_length;
  
  scale([1, 1, -1])
  chain() {
    mklayer(bend_radius, z) grip_2d();
    mklayer(bend_radius, z + knurl_slope) grip_2d(offs=knurl_depth);
    mklayer(bend_radius, z + knurl_slope + knurl_peak) grip_2d(offs=knurl_depth);
    mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope) grip_2d();
    
    mklayer(bend_radius, z + knurl_slope + knurl_peak + knurl_slope + knurl_valley)
    offset(delta=(chamfer ? -0.9 : 0))
    grip_2d();
  }
}

module grip() {
  r1 = 1000;
  p1 = 2;
  
  r2 = 130;
  p2 = 25;
  
  // Form the shelf.
  hull() {
    translate([0, -5])
    knurl_segment(r1, 0);
  
    knurl_segment(r1, 1);
  }
  
  bend_translate(r1, -p1*knurl_segment_length) {
    for (i = [0:p2-1])
    knurl_segment(r2, i, chamfer=(i==p2-1));
  }
}

module whole() {
  wedge();

  translate([0, 0, max_thickness/2])
  rotate([-90, 0, 0])
  grip();
}

// Chamfer the bottom edge at the finger joint. This avoids elephant
// foot in a critical area.
//
// TODO: use
module joint_chamfer() {
  w = 0.49;
  rotate([45, 0, 0])
  cube([250, w, w], center=true);
}

module top() {
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
}

module bottom(part=0) {
  difference() {
    translate([0, top_length-wedge_length])
    whole();
    
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
}

//top();
bottom();