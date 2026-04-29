$fn = 60;

// Parameters for the overall shape.
width = 194;
length = 370;
fan_length = 220;
fan_roundoff = 69;
handle_length = 104;
handle_width = 35;
grip_length = handle_length + 15;

pommel_d = 7;

// Parameters for slicing into printable sections.
top_length = 210;
cavity_offset = 0.25;

// Parameters for thickness.
thickness = 10;
lap_thickness = 0.8;
core_thickness = thickness - 2*lap_thickness;

total_grip_depth = 22;

module fan_2d() {
  translate([0, -fan_length/2])
  hull()
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate(-fan_roundoff*[1,1] + [width, fan_length]/2)
  circle(r=fan_roundoff);
}

module pommel_2d() {
  scale([0.6, 1])
  circle(d=pommel_d);
}

module pommel_set_2d() {
  for (a = [-1, 1])
  scale([a, 1])
  translate([handle_width/2 - 0.5, pommel_d/2 - length])
  pommel_2d();
}

module whole_2d() {
  neck_factor = 2;
  for (i = [0:5])
  hull() {
    scale([(i+5)/10, 1])
    fan_2d();

    // Top of the handle.
    translate([0, handle_length - length + i*neck_factor])
    square([handle_width, 0.0001], center=true);
  }
  
  // Handle.
  translate([0, handle_length/2 - length ])
  square([handle_width, handle_length], center=true);
  
  // Pommel.
  pommel_set_2d();
}

module top_slice_2d() {
  translate([0, -top_length/2])
  square([500, top_length], center=true);
}

module top_2d() {
  intersection() {
    whole_2d();
    top_slice_2d();
  }
}

module bottom_2d() {
  difference() {
    whole_2d();
    top_slice_2d();
  }
}

module core_window_2d() {
  translate([0, -top_length-12])
  square([500, 164], center=true);
}

module core_2d() {
  roundoff = 4;
  
  offset(roundoff)
  offset(-roundoff)
  intersection() {
    difference() {
      offset(-12) whole_2d();
      translate([0, 5])
      offset(-24) fan_2d();
      
      // Hole.
      translate([0, -top_length])
      circle(d=20);
    }
    
    core_window_2d();
  }
}

module joint_tabs() {
  for (a = [-1, 1])
  translate([a*65, -top_length])
  linear_extrude(0.6)
  circle(d=7);
}

module handle_cutout_2d() {
  offset(handle_width*0.12)
  offset(-handle_width*0.4)
  difference() {
    translate([-handle_width/2, -length, 0])
    square([handle_width, handle_length]);
    
    core_window_2d();
  }
}

module grip_2d() {
  square([handle_width, thickness], center=true);
  
  for (a = [-1, 1])
  scale([1, a])
  translate([0, thickness/2])
  scale([handle_width/2, (total_grip_depth-thickness)/2])
  circle($fn=40, r=1);
}

module knurled_grip_2d(angle) {
  knurl_depth = 0.25;
  knurl_width = 2;
  knurl_count = 20;
  
  grip_2d();
  
  intersection() {
    offset(knurl_depth)
    grip_2d();
    
    for (a = [1:knurl_count])
    rotate([0, 0, angle + a*360/knurl_count])
    square([knurl_width, 50], center=true);
  }
}

module half_grip() {
  layers = grip_length * 5;
  backoff_layers = 12;
  backoff_factor = 0.1;
  
  for (i = [1:layers])
  translate([0, 0, (i-1)*0.2])
  linear_extrude(0.200001)
  intersection() {
    backoff = (layers-i <= backoff_layers)
              ? (layers-i-backoff_layers)*backoff_factor
              : (i <= backoff_layers)
              ? (i-backoff_layers)*backoff_factor
              : 0;

    translate([0, backoff])
    knurled_grip_2d(i*0.8);
    
    translate([0, 50])
    square(100, center=true);
  }
  
  // Pommels.
  for (a = [-1, 1])
  scale([a, 1.25])
  translate([handle_width/2 - pommel_d/2, 0])
  rotate_extrude(angle=90)
  translate([pommel_d/2, pommel_d/2])
  pommel_2d();
  
  // Cutout lug.
  lug_depth = thickness/2 - 0.35;

  rotate([90, 0, 0])
  translate([0, length])
  linear_extrude(lug_depth)
  offset(-0.35)
  handle_cutout_2d();
}

module top() {
  difference() {
    linear_extrude(thickness/2) top_2d();

    translate([0, 0, lap_thickness])
    linear_extrude(10)
    offset(cavity_offset)
    core_2d();
  }
  
  joint_tabs();
}

module bottom() {
  difference() {
    linear_extrude(thickness/2)
    difference() {
      bottom_2d();
      handle_cutout_2d();
    }

    translate([0, 0, lap_thickness])
    linear_extrude(10)
    offset(cavity_offset)
    core_2d();    
  }
  
  joint_tabs();
  
  // Tabs on the end of the handle.
  for (a = [-1, 1])
  scale([a, 1])
  linear_extrude(0.6)
  translate([handle_width/2-5, -length-4])
  square(5.0001);
}

module core() {
  translate([0, 0, lap_thickness])
  linear_extrude(core_thickness)
  core_2d();
}

half_grip();
