// Parameters for the overall shape.
width = 192;
length = 395;
fan_length = 220;
fan_roundoff = 69;
handle_length = 122;
handle_width = 34;

module fan_2d() {
  translate([0, -fan_length/2])
  hull()
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate(-fan_roundoff*[1,1] + [width, fan_length]/2)
  circle(r=fan_roundoff, $fn = 100);
}

module whole_2d() {
  // Position the top edge at the origin.
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
      translate([0, 5])
      offset(-27) fan_2d();
      
      // Hole.
      translate([0, -top_length])
      circle(d=20);
    }
    
    translate([0, -top_length-5])
    square([500, 150], center=true);
  }
}

color("red") linear_extrude(1) top_2d();
color("blue") linear_extrude(1) bottom_2d();
color("green") linear_extrude(2) core_2d();