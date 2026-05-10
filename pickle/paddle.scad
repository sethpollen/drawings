use <finger.scad>

default_fn = 60;
$fn = default_fn;

// Parameters for the overall shape.
// TODO: increase size, to account for loss of flat area due to bulge.
width = 200;
length = 360;
fan_length = 220;
fan_roundoff = 69;
handle_length = 86;
handle_width = 35;
grip_length = handle_length + 20;

// Parameters for slicing into printable sections.
top_length = 212 - finger_length()/2;

// Parameters for thickness.
thickness = 13.6; // Needs to yield an even number of 0.2mm layers.
finger_floor = 2;
finger_z_slack = 0.4;
bottom_bevel = 2.8;

// Grips.
total_grip_depth = 25;

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
    translate([0, handle_length/2 - length])
    square([handle_width, handle_length], center=true);
  }
}

// Chamfer the bottom edge at the finger joint. This avoids elephant
// foot in a critical area.
module joint_chamfer() {
  w = 0.35;
  
  rotate([45, 0, 0])
  cube([250, w, w], center=true);
}

module extrude_fingers(cavity, complement, rot=false) {
  bevel_layers = floor(2.5*
    (thickness - 2*finger_floor - 2*finger_z_slack - 2)
  );
  
  for (a = [0:bevel_layers])
  translate([
    0,
    0,
    a*0.2 + finger_floor + (cavity ? 0 : finger_z_slack)
  ])
  linear_extrude(
    thickness
    - a*0.4
    - 2*finger_floor
    - (cavity ? 0 : 2*finger_z_slack)
  )
  rotate([0, 0, rot ? 180 : 0]) {
    truncate = (bevel_layers-a)*0.125;
    
    if (cavity) {
      finger_cavity_2d(complement=complement, truncate=truncate);
    } else {
      intersection() {
        finger_2d(complement=complement, truncate=truncate);
        
        // Prevent the backs of the teeth from sticking out.
        translate([-200, -5])
        square([400, 100]);
      }
    }
  }
}

module top_2d(offs) {
  intersection() {
    offset(delta=offs)
    whole_2d();
    
    translate([-125, 0])
    square(250);
  }
}

module bottom_2d(offs=0) {
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
top_bulge_r = thickness * 0.7;
bottom_bulge_r = thickness * 0.62;

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

module bottom_exterior() {
  translate([0, 0, thickness/2])
  for (a = [-1, 1])
  scale([1, 1, a])
  for (i = [0:bulge_layers-1]) {
    z = i*0.2;

    translate([0, 0, z])
    linear_extrude(0.20001)
    bottom_2d(bulge_offset(z, bottom_bulge_r));
  }
}

module top() {
  difference() {
    top_exterior();

    // Negative fingers.
    extrude_fingers(cavity=true);
    
    joint_chamfer();
  }
  
  // Positive fingers.
  extrude_fingers(cavity=false, complement=true, rot=true);
  
  // Tabs.
  for (a = [-1, 1])
  linear_extrude(0.6)
  scale([a, 1])
  translate([83, 0])
  circle(d=8);
}

module bottom() {
  difference() {
    bottom_exterior();

    // Negative fingers.
    extrude_fingers(cavity=true, complement=true, rot=true);

    joint_chamfer();
  }
  
  // Positive fingers.
  extrude_fingers(cavity=false, complement=false);
  
  // Tabs.
  for (a = [-1, 1])
  linear_extrude(0.6)
  scale([a, 1]) {
    translate([81, 0])
    circle(d=8);
    
    translate([handle_width/2 - bottom_bevel - 6, top_length-length-5])
    square(6);
  }
}

module grip_2d(backoff=0, offs=0) {
  flats = thickness*0.8;
  
  translate([0, -backoff])
  offset(offs) {
    square([handle_width, flats], center=true);
    
    for (a = [-1, 1])
    scale([1, a])
    translate([0, flats/2])
    scale([handle_width/2, (total_grip_depth-flats)/2])
    circle($fn=50, r=1);
  }
}

module grip_element(offs=0, up=0, down=0, in=0) {
  translate([0, 0, up])
  linear_extrude(grip_length - up - down)
  grip_2d(offs=offs, backoff=in);
}

module grip(offs=0) {
  // Main part of the grip, with a little bevel on the bottom.
  hull() {
    grip_element(offs=offs, in=1.2, down=1);
    grip_element(offs=offs, up=2.4, down=1);
  }
  
  // Flare at the top.
  shelf = 3;
  hull() {
    grip_element(offs=offs, up=grip_length-4, in=2);
    grip_element(offs=offs, up=grip_length-4, in=0.8-shelf, down=0.5);
    grip_element(offs=offs, up=grip_length-4, down=1.2, in=-shelf);
    grip_element(offs=offs, up=grip_length-8, down=1);
  }
}

module knurled_grip() {
  knurl_width = 2;
  knurl_count = 20;
  knurl_depth = 0.25;
  
  color("green")
  grip(offs=-knurl_depth);

  color("blue")
  intersection() {
    grip();
    
    linear_extrude(grip_length, twist=400, convexity=knurl_count, $fn=200)
    for (a = [1:knurl_count])
    rotate([0, 0, a*360/knurl_count])
    square([knurl_width, 50], center=true);
  }
}

module half_grip() {
  difference() {
    knurled_grip();
    
    // Fit to the rigid "bottom" piece.
    translate([0, 0, -1])
    linear_extrude(200)
    difference() {
      square([handle_width + 0.001, thickness], center=true);
      
      for (a = [-1, 1], b = [-1, 1])
      translate([a*handle_width/2, b*thickness/2])
      rotate([0, 0, 45])
      square(bottom_bevel*sqrt(2), center=true);
    }
    
    // We want only one half of the grip.
    translate([-50, -100, -1])
    linear_extrude(grip_length+2)
    square(100);
    
    // We already cut out the straight part of the handle. But we also
    // need extra cuts at the top for the start of the blade. This
    // intersection() grabs just the part we need, to make the
    // difference operation more efficient.
    intersection() {
      rotate([90, 0, 0])
      translate([0, length-top_length, -thickness/2])
      bottom_exterior();
      
      translate([0, 0, grip_length*0.6])
      linear_extrude(grip_length*0.4+1)
      square(100, center=true);
    }
  }
}

module preview() {
  rotate([90, 0, 0])
  translate([0, length-top_length, -thickness/2])
  bottom();
  
  for (a = [-1, 1])
  scale([1, a, 1])
  half_grip();
}

translate([0, -100]) {
bottom_exterior();
top_exterior();
}
