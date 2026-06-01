use <chain.scad>
use <finger.scad>

// TODO: clean up unused variables.

// Parameters for the overall shape.
width = 200;
length = 357;
fan_length = 223;
fan_roundoff = 69;
handle_width = 35;

// The length of the flat striking surface, before it hits the grip
// shelf.
flat_surface_length = length - 106;

// 20mm of overlap between grip and the main body of the paddle.
bridge_length = flat_surface_length + 20 - fan_length;

// Make a wedge shape.
thickness = 20;
end_thickness = 10;

bulge_fn = 24;
tab_height = 0.6;

// Parameters for slicing into printable sections.
top_length = 216 - finger_length()/2;

function bulge_radius(intercept_angle) =
  thickness / (2 * sin(intercept_angle));

module bulge_2d(intercept_angle) {
  r = bulge_radius(intercept_angle);
  
  translate([-r, 0])
  intersection() {
    circle($fn=bulge_fn, r=r);
    
    translate([0, -thickness/2])
    square(thickness);
  }
}

module fan() {
  intercept_angle = 45;
  
  hull()
  translate([0, -fan_length/2])
  for (a = [-1, 1], b = [-1, 1])
  scale([
    a, b,
    // Adjust the bulge at the tip of the wedge.
    1-(b+1)*0.15
  ])
  translate(-fan_roundoff*[1,1] + [width, fan_length]/2)
  rotate_extrude($fn=36, angle=90)
  translate([fan_roundoff, 0])
  bulge_2d(intercept_angle);
}

// `i` should be in the range [0, 4].
module bridge(i) {
  intercept_angle = 52;
  x_frac = [0.46, 0.28, 0.16, 0.083, 0.027][i];
  y_frac = [0.1 , 0.38 , 0.6 , 0.8 , 1.0  ][i];

  r = bulge_radius(intercept_angle);

  for (a = [-1, 1])
  scale([a, 1])
  translate([
    handle_width/2 - r + x_frac*0.5*(width-handle_width),
    r - fan_length - y_frac*bridge_length
  ])
  rotate([0, 0, -90])
  rotate_extrude($fn=bulge_fn, angle=90)
  translate([r, 0])
  bulge_2d(intercept_angle);
}

module wedge_cut() {
  translate([0, top_length, thickness/2])
  for (a = [-1, 1])
  scale([1, 1, a])
  hull() {
    translate([0, 0, end_thickness/2])
    linear_extrude(50)
    square([300, 0.01], center=true);

    translate([0, -flat_surface_length, thickness/2])
    linear_extrude(50)
    square([300, 0.01], center=true);
  }
}

module unwedge() {
  wedge_angle = atan((thickness-end_thickness) / (2*flat_surface_length));
  rotate([-wedge_angle, 0, 0])
  translate([0, flat_surface_length-top_length, 0])
  children();
}

module whole() {
  difference() {
    translate([0, top_length, thickness/2]) {
      chain() {
        fan();
        bridge(0);
        bridge(1);
        bridge(2);
        bridge(3);
        bridge(4);
      }      
    }
    
    wedge_cut();
  }
}

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
  
  // Tabs.
  color("orange")
  for (a = [-1, 1])
  linear_extrude(tab_height)
  scale([a, 1])
  translate([82, 0])
  circle(d=8);
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


  // TODO: tabs?
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

bottom();
translate([0, 80]) top();