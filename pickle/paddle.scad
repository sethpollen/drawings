$fn = 60;

// Parameters for the overall shape.
width = 194;
length = 352;
fan_length = 220;
fan_roundoff = 69;
handle_length = 86;
handle_width = 35;
grip_length = handle_length + 15;

// Parameters for slicing into printable sections.
top_length = 205;

// Parameters for thickness.
thickness = 13;

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
  for (i = [0:neck_steps])
  hull() {
    scale([(i+neck_steps)/(2*neck_steps), 1])
    fan_2d();

    // Top of the handle.
    translate([0, handle_length - length + i*neck_factor])
    square([handle_width, 0.0001], center=true);
  }
  
  // Handle.
  translate([0, handle_length/2 - length ])
  square([handle_width, handle_length], center=true);
}

linear_extrude(thickness)
whole_2d();
