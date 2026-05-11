use <chain.scad>
use <finger.scad>

default_fn = 60;
$fn = default_fn;

// Parameters for the overall shape.
width = 200;
length = 356;
fan_length = 220;
fan_roundoff = 69;
handle_length = 86;
handle_width = 35;
grip_length = handle_length + 20;

// Parameters for slicing into printable sections.
top_length = 216 - finger_length()/2;

// Parameters for thickness.
thickness = 13.2; // Needs to yield an even number of 0.2mm layers.

// Grips.
total_grip_depth = 25.2;
// How much of the total length is just the grip, with no intrustion
// from the `bottom` piece.
grip_floor = 8;

module fan_2d() {
  translate([0, -fan_length/2])
  hull()
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate(-fan_roundoff*[1,1] + [width, fan_length]/2)
  circle(r=fan_roundoff);
}

module whole_2d() {
  neck_steps = 7;
  neck_factor = 2;
  
  translate([0, top_length]) {
    for (i = [0:neck_steps])
    hull() {
      scale([(i+neck_steps)/(2*neck_steps), 1])
      fan_2d();

      // Top of the handle.
      translate([0, handle_length - length + i*neck_factor])
      square([handle_width, 0.0001], center=true);
    }
    
    // Handle.
    translate([0, -length])
    hull() {
      translate([0, grip_floor])
      square([8, 0.0001], center=true);
      
      translate([-handle_width/2, handle_length])
      square([handle_width, 0.0001]);
    }
  }
}

// Chamfer the bottom edge at the finger joint. This avoids elephant
// foot in a critical area.
module joint_chamfer() {
  w = 0.35;
  
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

module bottom_2d(offs=0, bulb=false) {
  difference() {
    offset(delta=offs)
    whole_2d();
    
    translate([-125, 0])
    square(250);
  }
}

// The edge has a circular bulge. The center of that circle is inset
// by this distance from the edge:
bulge_layers = thickness/2 * 5;
top_bulge_r = thickness/(2*sin(45));
bottom_bulge_r = thickness/(2*sin(55));

// `z` is the height from the centerline.
function bulge_offset(z, r) = sqrt(r^2 - z^2) - r;

module top_exterior() {
  translate([0, 0, thickness/2])
  for (a = [-1, 1])
  scale([1, 1, a])
  for (i = [0:bulge_layers-1]) {
    z = i*0.2;
    translate([0, 0, z])
    linear_extrude(0.20001)
    top_2d(bulge_offset(z, top_bulge_r));
  }
}

module bottom_exterior(bulb=false) {
  translate([0, 0, thickness/2])
  for (a = [-1, 1])
  scale([1, 1, a])
  for (i = [0:bulge_layers-1]) {
    z = i*0.2;

    translate([0, 0, z])
    linear_extrude(0.20001)
    bottom_2d(bulge_offset(z, bottom_bulge_r), bulb=bulb);
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
  linear_extrude(0.6)
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
    for (a = [-1, 1])
    linear_extrude(0.6)
    scale([a, 1])
    translate([78, 0])
    circle(d=8);
    
    linear_extrude(0.6)
    translate([0, top_length-length+grip_floor+2])
    circle(d=10);
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
knurl = true;  // Knurling.
cut_grip = false;  // Grip cavity to receive `bottom`.

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
    
    // Jiggle slightly to make the cavity.
    for (y = 0.15 * [-1, 1])
    translate([0, y]){
      if (cut_grip)
      rotate([90, 0, 0])
      translate([0, length-top_length, -thickness/2])
      bottom_exterior(bulb=true);

      // Cut some material from the edges, to avoid a very thin area.
      translate([0, 0, handle_length-4]) {
        translate([0, 0, thickness])
        scale([1, 1, 2])
        rotate([0, 90, 0])
        translate([0, 0, -handle_width])
        cylinder(h=2*handle_width, d=thickness, $fn=80);
        
        // Add some flat to make sure there are no extra intrusions.
        translate([-handle_width, -thickness/2, thickness])
        cube([handle_width*2, thickness, 40]);
      }
    }
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
    cube([56, 77, 100], center=true);
    translate([0, 18]) top();
  }
  intersection() {
    cube([68, 77, 100], center=true);
    translate([0, -18]) bottom();
  }
}

module bulge_test() {
  intersection() {
    cube(90, center=true);

    translate([0, length-top_length])
    bottom();
  }
}
