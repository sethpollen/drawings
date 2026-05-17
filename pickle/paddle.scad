use <chain.scad>
use <finger.scad>

// TODO: clean out unused stuff

// TODO: remove this; it just leads to trouble. Specify $fn every time.
default_fn = 60;
$fn = default_fn;
bulge_fn = 24;

tab_height = 0.6;

// Parameters for the overall shape.
width = 200;
length = 357;
fan_length = 223;
fan_roundoff = 69;
handle_length = 86;
handle_width = 35;
// TODO: make this '20' is own named constant. This is how much further up
// the paddle the shelf is.
grip_length = handle_length + 20;

// TODO: refactor this to allow more intuitive adjustments
bridge_length = length - fan_length - handle_length;

// Round up to an even number of layers.
//
// TODO: This was the Mk. 3 thickness. Maybe even thicker?
thickness = 13.2;

// Parameters for slicing into printable sections.
top_length = 216 - finger_length()/2;

// Grips.
total_grip_depth = 25.2;
// How much of the total length is just the grip, with no intrustion
// from the `bottom` piece.
grip_floor = 5;

// The tang is slightly tapered, to make it fit easier.
tang_width_max = handle_width - 5;
tang_width_min = tang_width_max * 0.65;

function bulge_radius(intercept_angle) = thickness / (2*sin(intercept_angle));

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
  scale([a, b])
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

module tang_2d(width, z) {
  chamfer = thickness * 0.4;

  translate([0, 0, z])
  linear_extrude(1)
  offset(delta=chamfer, chamfer=true)
  square([width, thickness] - 2*chamfer*[1,1], center=true);
}

module tang(extend=false) {
  translate([0, -length])
  rotate([-90, 0, 0]) {
    hull()
    for (width_z = [[tang_width_min, grip_floor], [tang_width_max, handle_length+5]])
    tang_2d(width_z[0], width_z[1]);
    
    if (extend)
    tang_2d(tang_width_min, grip_floor-0.2);
  }
}

module whole(grip_cut=false) {
  translate([0, top_length, thickness/2]) {
    if (grip_cut) {
      // Just enough for the grip cut, scaled out to make a flat cut.
      scale([5, 1, 1])
      chain() {
        bridge(1);
        bridge(2);
        bridge(3);
        bridge(4);
      }
    } else {
      // The full paddle.
      chain() {
        fan();
        bridge(0);
        bridge(1);
        bridge(2);
        bridge(3);
        bridge(4);
      }
    }

    // For the grip cut, extend the tang to deepen the hole slightly.
    tang(extend=grip_cut);
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
  difference() {
    whole();
    
    translate([0, -200])
    cube([400, 400, 100], center=true);

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

module bottom() {
  difference() {
    translate([0, top_length, thickness/2])
    whole();
    
    translate([0, 200])
    cube([400, 400, 100], center=true);

    joint_chamfer();

    // Negative fingers.
    extrude_fingers(thickness=thickness,
                    cavity=true, complement=true, rot=true);
  }
  
  // Positive fingers.
  extrude_fingers(thickness=thickness,
                  cavity=false, complement=false);
  
  // Tabs.
  color("orange") {
    linear_extrude(tab_height)
    for (a = [-1, 1])
    scale([a, 1]) {
      translate([81, 0])
      circle(d=8);
    
      translate([tang_width_min/2-1, top_length-length+grip_floor])
      circle(d=10);
    }
  }
}

// Only produces half of the profile.
module grip_2d(flare=0, narrow=0, offs=0) {
  flats = thickness*0.8;
  width = handle_width;
  
  offset(delta=offs)
  scale([(width-narrow)/width, 1]) {
    // Back it into the negative y-coordinate so that the
    // `offset` above doesn't cause us to detach from the
    // x-axis.
    translate([-width/2, -1])
    square([width, flats/2 + flare + 1]);

    translate([0, flats/2 + flare])
    scale([width/2, (total_grip_depth-flats)/2])
    intersection() {
      circle($fn=30, r=1);
      
      translate([0, 2])
      square(4, center=true);
    }
  }
}

module grip_exterior(offs=0) {
  radius = 0;
  
  main_column_start = 2.4;
  main_column_end = grip_length-8;
  
  for (a = [-1, 1])
  scale([1, a, -1])
  chain() {
    // Bevelled bottom.
    mklayer(grip_length, radius) grip_2d(offs=offs, flare=-1.2);
    
    // Main column.
    mklayer(grip_length-main_column_start, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_start*0.9-main_column_end*0.1, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_start*0.8-main_column_end*0.2, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_start*0.7-main_column_end*0.3, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_start*0.6-main_column_end*0.4, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_start*0.5-main_column_end*0.5, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_start*0.4-main_column_end*0.6, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_start*0.3-main_column_end*0.7, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_start*0.2-main_column_end*0.8, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_start*0.1-main_column_end*0.9, radius) grip_2d(offs=offs);
    mklayer(grip_length-main_column_end, radius) grip_2d(offs=offs);
    
    // Shelf.
    mklayer(4, radius) grip_2d(offs=offs, flare=3);
    mklayer(1.2, radius) grip_2d(offs=offs, flare=3);
    mklayer(0.5, radius) grip_2d(offs=offs, flare=2.2, narrow=0.6);
    mklayer(0, radius) grip_2d(offs=offs, flare=-2, narrow=2);
  }
}

// These steps are computationally expensive, so we provide a convenient
// way to disable them during development.
knurl = true;  // Knurling.

module knurled_grip_exterior() {
  knurl_width = 2;
  knurl_count = 20;
  knurl_depth = 0.25;
  
  grip_exterior(offs=-knurl_depth);

  if(knurl)
  color("orange")
  intersection() {
    grip_exterior();
    
    translate([0, 0, -grip_length])
    linear_extrude(grip_length, twist=400, convexity=knurl_count, $fn=150)
    for (a = [1:knurl_count])
    rotate([0, 0, a*360/knurl_count])
    square([knurl_width, 50], center=true);
  }
}

module grip() {
  difference() {
    knurled_grip_exterior();
    
    // Jiggle slightly to make the cavity.
    for (x = 0.1 * [-1, 1], y = .15 * [-1, 1])
    translate([x, y, -grip_length])
    rotate([90, 0, 0])
    translate([0, length-top_length, -thickness/2])
    whole(grip_cut=true);
  }
}

//////////////////////////////////////////////////////////////////////////

grip();

