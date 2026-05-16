use <chain.scad>
use <finger.scad>

default_fn = 60;
$fn = default_fn;

layer_height = 0.15;
tab_height = 3*layer_height;

// Parameters for the overall shape.
width = 200;
length = 359;
fan_length = 220;
fan_roundoff = 69;
handle_length = 86;
handle_width = 35;
grip_length = handle_length + 20;

// Parameters for slicing into printable sections.
top_length = 216 - finger_length()/2;

// Round up to an even number of layers.
thickness = ceil(13 / (2*layer_height)) * 2*layer_height;

// Grips.
total_grip_depth = 25.2;
// How much of the total length is just the grip, with no intrustion
// from the `bottom` piece.
grip_floor = 5;

// The tang is slightly tapered, to make it fit easier.
tang_width_max = handle_width - 5;
tang_width_min = tang_width_max * 0.65;

module fan_2d(grip_cut=false) {
  translate([0, -fan_length/2])
  hull()
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate(-fan_roundoff*[1,1] + [width, fan_length]/2)
  circle(r=fan_roundoff);
}

module whole_2d(grip_cut=false) {
  // When making the grip_cut, we only care about the bottom part.
  // Simplify the rest to cut computational cost.
  neck_steps = grip_cut ? 1 : 7;
  neck_factor = 2;
  
  translate([0, top_length]) {
    for (i = [0:neck_steps])
    hull() {
      scale([(i+neck_steps)/(2*neck_steps), 1])
      fan_2d(grip_cut=grip_cut,
             $fn=(grip_cut ? 10 : default_fn));

      // Top of the handle.
      translate([0, handle_length - length + i*neck_factor])
      square([handle_width + (grip_cut ? 20 : 0), 0.0001],
             center=true);
    }
    
    // Handle tang.
    translate([0, -length])
    hull() {      
      translate([0, handle_length])
      square([tang_width_max, 0.001], center=true);
 
      translate([0, grip_floor])
      square([tang_width_min, 0.001], center=true);
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

module top_2d(offs) {
  intersection() {
    offset(delta=offs)
    whole_2d();
    
    translate([-125, 0])
    square(250);
  }
}

module bottom_2d(offs=0, grip_cut=false) {
  difference() {
    offset(delta=offs)
    whole_2d(grip_cut=grip_cut);
    
    translate([-125, 0])
    square(250);
  }
}

// The edge has a circular bulge. The center of that circle is inset
// by this distance from the edge:
bulge_layers = thickness/(2*layer_height);
top_bulge_r = thickness/(2*sin(45));
bottom_bulge_r = thickness/(2*sin(50));

// `z` is the height from the centerline.
function bulge_offset(z, r) = sqrt(r^2 - z^2) - r;

module top_exterior() {
  translate([0, 0, thickness/2])
  for (a = [-1, 1])
  scale([1, 1, a])
  for (i = [0:bulge_layers-1]) {
    z = i*layer_height;
    translate([0, 0, z])
    linear_extrude(layer_height + 0.0001)
    top_2d(offs=bulge_offset(z, top_bulge_r));
  }
}

module bottom_exterior(grip_cut=false) {
  translate([0, 0, thickness/2])
  for (a = [-1, 1])
  scale([1, 1, a])
  for (i = [0:bulge_layers-1]) {
    z = i*layer_height;

    translate([0, 0, z])
    linear_extrude(layer_height + 0.0001)
    bottom_2d(offs=bulge_offset(z, bottom_bulge_r),
              grip_cut=grip_cut);
  }
}

module top() {
  difference() {
    top_exterior();
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
  translate([79, 0])
  circle(d=8);
}

module bottom() {
  difference() {
    bottom_exterior();
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
      translate([78, 0])
      circle(d=8);
    
      translate([tang_width_min/2, top_length-length+grip_floor+2])
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
  for (a = [-1, 1])
  scale([1, a])
  chain() {
    // Bevelled bottom.
    makelayer(0) grip_2d(offs=offs, flare=-1.2);
    
    // Main column.
    makelayer(2.4) grip_2d(offs=offs);
    makelayer(grip_length-8) grip_2d(offs=offs);
    
    // Shelf.
    makelayer(grip_length-4) grip_2d(offs=offs, flare=3);
    makelayer(grip_length-1.2) grip_2d(offs=offs, flare=3);
    makelayer(grip_length-0.5) grip_2d(offs=offs, flare=2.2, narrow=0.6);
    makelayer(grip_length) grip_2d(offs=offs, flare=-2, narrow=2);
  }
}

// These steps are computationally expensive, so we provide a convenient
// way to disable them during development.
knurl = true;  // Knurling.
cut_grip = true;  // Grip cavity to receive `bottom`.

module knurled_grip_exterior() {
  knurl_width = 2;
  knurl_count = 20;
  knurl_depth = 0.25;
  
  grip_exterior(offs=-knurl_depth);

  if(knurl)
  color("orange")
  intersection() {
    grip_exterior();
    
    linear_extrude(grip_length, twist=400, convexity=knurl_count, $fn=150)
    for (a = [1:knurl_count])
    rotate([0, 0, a*360/knurl_count])
    square([knurl_width, 50], center=true);
  }
}

module grip() {
  difference() {
    knurled_grip_exterior();
    
    if (cut_grip)
    // Jiggle slightly to make the cavity.
    for (x = 0.1 * [-1, 1], y = 0.15 * [-1, 1])
    translate([x, y])
    rotate([90, 0, 0])
    translate([0, length-top_length, -thickness/2])
    bottom_exterior(grip_cut=true);
    
    // Version marking.
    translate([-7, -5, -0.01])
    linear_extrude(1.5)
    offset(delta=0.4, chamfer=true)
    rotate([0, 0, 90])
    scale([1, -1])
    text("3", size=15);
  }
}

////////////////////////////////////////////////////////////////////////
// Preview and test packages.

module grip_fit_preview() {
  color("green")
  rotate([90, 0, 0])
  translate([0, length-top_length, -thickness/2])
  bottom_exterior();
  
  grip();
}

module finger_joint_test() {
  intersection() {
    translate([49, 0])
    cube([56, 95, 100], center=true);
    
    translate([0, 15])
    top();
  }
  intersection() {
    translate([49, 0])
    cube([68, 77, 100], center=true);
    
    translate([0, -15])
    bottom();
  }
}

module bulge_test() {
  intersection() {
    cube(90, center=true);

    translate([0, length-top_length])
    bottom();
  }
}

grip();