$fn = 60;

/* TODO:
Move pin
Adhesion tabs 0.6mm
*/

// Parameters for the overall shape.
width = 194;
length = 370;
fan_length = 220;
fan_roundoff = 69;
handle_length = 105;
handle_width = 35;

module fan_2d() {
  translate([0, -fan_length/2])
  hull()
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate(-fan_roundoff*[1,1] + [width, fan_length]/2)
  circle(r=fan_roundoff);
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

module core_2d() {
  roundoff = 3;
  
  offset(roundoff)
  offset(-roundoff)
  intersection() {
    difference() {
      offset(-12) whole_2d();
      translate([0, 9])
      offset(-25) fan_2d();
      
      // Hole.
      translate([0, -top_length])
      circle(d=20);
    }
    
    translate([0, -top_length-5])
    square([500, 150], center=true);
  }
}

// Parameters for thickness.
thickness = 10;
lap_thickness = 0.8;
core_thickness = thickness - 2*lap_thickness;

module top() {
  difference() {
    linear_extrude(thickness/2) top_2d();

    translate([0, 0, lap_thickness])
    linear_extrude(10)
    offset(cavity_offset)
    core_2d();
  }
}

module bottom() {
  difference() {
    linear_extrude(thickness/2) bottom_2d();

    translate([0, 0, lap_thickness])
    linear_extrude(10)
    offset(cavity_offset)
    core_2d();
  }
}

module core() {
  translate([0, 0, lap_thickness])
  linear_extrude(core_thickness)
  core_2d();
}

translate([0, 0, -2]) linear_extrude(1) whole_2d();
