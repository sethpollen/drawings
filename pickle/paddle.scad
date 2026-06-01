use <chain.scad>
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
max_thickness = 20;
min_thickness = 10;

wedge_angle = atan(
  (max_thickness - min_thickness) / (2 * wedge_length));

// Parameters for slicing into printable sections.
top_length = 216 - finger_length()/2;

handle_width = 35;

function bulge_radius(thickness, intercept_angle) =
  thickness / (2 * sin(intercept_angle));

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

// `i` should be in the range [0, 4].
module bridge(i) {
  intercept_angle = 52;
  x_frac = [0.28, 0.16, 0.083, 0.027][i];
  y_frac = [0.38 , 0.6 , 0.8 , 1.0  ][i];

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

wedge();


/*

// TODO: This no longer works because of the wedge cut

// Chamfer the bottom edge at the finger joint. This avoids elephant
// foot in a critical area.
module joint_chamfer() {
  w = 0.49;
  rotate([45, 0, 0])
  cube([250, w, w], center=true);
}

module top() {
  difference() {
    whole();
    
    translate([0, -200])
    cube([400, 400, 100], center=true);

    // TODO: This probably does not work.
    joint_chamfer();

    // Negative fingers.
    extrude_fingers(thickness=thickness,
                    cavity=true);
  }
  
  // Positive fingers.
  extrude_fingers(thickness=thickness,
                  cavity=false, complement=true, rot=true);
}

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

// Only produces half of the profile.
module grip_2d(flare=0, narrow=0, offs=0) {
  flats = thickness*0.5;
  grip_thickness = 26;
  
  offset(delta=offs)
  scale([(handle_width-narrow)/handle_width, 1]) {
    // Back it up by 2mm so the chamfer offset below doesn't create a
    // groove down the middle.
    translate([-handle_width/2, -2])
    square([handle_width, flats/2 + flare + 2]);

    translate([0, flats/2 + flare])
    scale([handle_width/2, (grip_thickness-flats)/2])
    intersection() {
      circle($fn=30, r=1);
      
      translate([0, 2])
      square(4, center=true);
    }
  }
}

knurl_depth = 0.3;
knurl_peak = 2;
knurl_slope = 0.4;
knurl_valley = 0.8;
knurl_segment_length = knurl_slope + knurl_peak + knurl_slope + knurl_valley;

module knurl_segment(bend_radius, i, chamfer=false) {
  z = i*knurl_segment_length;
  
  for (a = [-1, 1])
  scale([1, a, -1])
  chain() {
    mklayer(z, bend_radius) grip_2d();
    mklayer(z + knurl_slope, bend_radius) grip_2d(offs=knurl_depth);
    mklayer(z + knurl_slope + knurl_peak, bend_radius) grip_2d(offs=knurl_depth);
    mklayer(z + knurl_slope + knurl_peak + knurl_slope, bend_radius) grip_2d();
    
    mklayer(z + knurl_slope + knurl_peak + knurl_slope + knurl_valley, bend_radius)
    offset(delta=(chamfer ? -1 : 0))
    grip_2d();
  }
}

module grip() {
  shelf_height = 8;

  // Shelf.
  scale([1, -1, -1])
  chain() {
    mklayer(shelf_height) grip_2d();
    mklayer(4) grip_2d(flare=5.4);
    mklayer(1.2) grip_2d(flare=5.4);
    mklayer(0.5) grip_2d(flare=4.6, narrow=0.6);
    mklayer(0) grip_2d(flare=-1, narrow=2);
  }
  
  bend_radius = 130;
  bend_segments = 34;
  
  // Curved part of grip.
  translate([0, 0, knurl_segment_length - shelf_height])
  for (i = [0:bend_segments-1])
  knurl_segment(bend_radius, i, chamfer=(i == bend_segments-1));
}

//////////////////////////////////////////////////////////////////////////

*/