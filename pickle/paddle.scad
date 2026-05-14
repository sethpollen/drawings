/* Printing this in PETG (Mk.3)

Infill: 10% grid. Mk.2 used 11% (PLA). 10% is probably fine, especially
  with the vaunted material properties of PETG.
  
Layer height: 0.15mm. Mk.2 used 0.2mm. Thinner layers will give better
  bonding (which seems like it might be tougher with PETG). It also
  enables finer adjustments to the finger fit.
  
Top and bottom: 5 layers of 100% plus 3 layers of 50%. Mk.2 (with
  0.2mm layers) used 4 layers of 100% plus 2 layers of 50%.
  
Walls: 3 lines. Mk.2 used 2 lines and had some trouble with denting on
  the outer edges.
  
Bottom layer inset: 0.2mm. I tested 0.3mm and it was too much for
  the bulging parts. 0.15mm was not quite enough.
  
Head temp: 240 C (right in the middle of the stated range for my
  PETG roll).

Print speed: 40 mm/s (also right in the middle of the nominal range).
*/

// TODO: add one more layer of 50% fill to the ceiling. The first couple
// of 50% layers struggle to bridge, so they probably don't provide as
// much strength.

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

module fan_2d() {
  translate([0, -fan_length/2])
  hull()
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate(-fan_roundoff*[1,1] + [width, fan_length]/2)
  circle(r=fan_roundoff);
}

module whole_2d(widen_cut=false) {
  neck_steps = 7;
  neck_factor = 2;
  
  translate([0, top_length]) {
    for (i = [0:neck_steps])
    hull() {
      scale([(i+neck_steps)/(2*neck_steps), 1])
      fan_2d();

      // Top of the handle.
      translate([0, handle_length - length + i*neck_factor])
      square([handle_width + (widen_cut ? 20 : 0), 0.0001],
             center=true);
    }
    
    // Handle tang.
    tang_width = handle_width - 5;
    translate([0, -length])
    hull() {      
      translate([-tang_width/2, handle_length])
      square([tang_width, 0.0001]);
 
      // Slightly tapered, to make it fit easier.
      translate([0, grip_floor])
      square([tang_width - 4, 0.0001], center=true);
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

module bottom_2d(offs=0, widen_cut=false) {
  difference() {
    offset(delta=offs)
    whole_2d(widen_cut=widen_cut);
    
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

module bottom_exterior(widen_cut=false) {
  translate([0, 0, thickness/2])
  for (a = [-1, 1])
  scale([1, 1, a])
  for (i = [0:bulge_layers-1]) {
    z = i*layer_height;

    translate([0, 0, z])
    linear_extrude(layer_height + 0.0001)
    bottom_2d(offs=bulge_offset(z, bottom_bulge_r),
              widen_cut=widen_cut);
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
    
      translate([11, top_length-length+grip_floor+2])
      circle(d=10);
    }
  }
}

// Only produces half of the profile.
module grip_2d(widen=0, offs=0) {
  flats = thickness*0.8;
  width = handle_width;
  
  offset(delta=offs) {
    // Back it into the negative y-coordinate so that the
    // `offset` above doesn't cause is to detach from the
    // x-axis.
    translate([-width/2, -1])
    square([width, flats/2 + widen + 1]);

    translate([0, flats/2 + widen])
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
    makelayer(0) grip_2d(offs=offs, widen=-1.2);
    
    // Main column.
    makelayer(2.4) grip_2d(offs=offs);
    makelayer(grip_length-8) grip_2d(offs=offs);
    
    // Shelf.
    makelayer(grip_length-4) grip_2d(offs=offs, widen=3);
    makelayer(grip_length-1.2) grip_2d(offs=offs, widen=3);
    makelayer(grip_length-0.5) grip_2d(offs=offs, widen=2.2);
    makelayer(grip_length) grip_2d(offs=offs, widen=-2);
  }
}

// These steps are computationally expensive, so we provide a convenient
// way to disable them during development.
knurl = false;  // Knurling.
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
    bottom_exterior(widen_cut=true);
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

bottom();