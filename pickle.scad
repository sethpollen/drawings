$fn = 60;

// Parameters for the overall shape.
width = 194;
length = 370;
fan_length = 220;
fan_roundoff = 69;
handle_length = 104;
handle_width = 35;

module fan_2d() {
  translate([0, -fan_length/2])
  hull()
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate(-fan_roundoff*[1,1] + [width, fan_length]/2)
  circle(r=fan_roundoff);
}

pommel_d = 7;

module pommel_2d() {
  for (a = [-1, 1])
  scale([a, 1])
  translate([handle_width/2 - 0.5, pommel_d/2 - length])
  scale([0.6, 1])
  circle(d=pommel_d);
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
  pommel_2d();
}

// Parameters for slicing into printable sections.
top_length = 210;
cavity_offset = 0.25;

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
  translate([0, -top_length-5])
  square([500, 150], center=true);
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

// Parameters for thickness.
thickness = 10;
lap_thickness = 0.8;
core_thickness = thickness - 2*lap_thickness;

module joint_tabs() {
  for (a = [-1, 1])
  translate([a*65, -top_length])
  linear_extrude(0.6)
  circle(d=7);
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

module handle_cutout_2d() {
  offset(handle_width*0.12)
  offset(-handle_width*0.4)
  difference() {
    square([handle_width, 2*length], center=true);
    core_window_2d();
  }
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

bottom();
