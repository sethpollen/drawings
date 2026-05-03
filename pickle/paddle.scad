use <finger.scad>

$fn = 60;

// Parameters for the overall shape.
width = 194;
length = 352;
fan_length = 220;
fan_roundoff = 69;
handle_length = 86;
handle_width = 35;
grip_length = handle_length + 15;

// Parameters for slicing into printable sections. Have
// to save about 20mm more for the fingers.
top_length = 193;

// Parameters for thickness.
thickness = 13;
finger_floor = 2;
finger_z_slack = 0.4;

bottom_bevel = 2.6;

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

module top_2d() {
  intersection() {
    whole_2d();
    
    translate([-100, -top_length])
    square(250);
  }
}

module top() {
  difference() {
    linear_extrude(thickness)
    top_2d();

    // Negative fingers.
    translate([0, -top_length, finger_floor])
    linear_extrude(thickness - 2*finger_floor)
    finger_cavity_2d();
  }
  
  // Positive fingers.
  translate([0, -top_length, finger_floor + finger_z_slack])
  linear_extrude(thickness - 2*finger_floor - 2*finger_z_slack)
  rotate([0, 0, 180])
  finger_2d(true);
  
  // Tabs.
  for (a = [-1, 1])
  linear_extrude(0.6)
  scale([a, 1])
  translate([83, -top_length])
  circle(d=8);
}

module bottom_2d() {
  difference() {
    whole_2d();
    
    translate([-100, -top_length])
    square(250);
  }
}

module bottom_exterior() {
  bevel_layers = bottom_bevel*5;
  
  for (a = [0:bevel_layers])
  translate([0, 0, a*0.2])
  linear_extrude(thickness-a*0.4)
  intersection() {
    offset((a-bevel_layers)*0.2){
      bottom_2d();
      
      for (y = [-top_length-bottom_bevel-10, -length-200])
      translate([-100, y])
      square([200, 200]);
    }
    bottom_2d();
  }
}

module bottom() {
  difference() {
    bottom_exterior();

    // Negative fingers.
    translate([0, -top_length, finger_floor])
    linear_extrude(thickness - 2*finger_floor)
    rotate([0, 0, 180])
    finger_cavity_2d(true);
  }
  
  // Positive fingers.
  translate([0, -top_length, finger_floor + finger_z_slack])
  linear_extrude(thickness - 2*finger_floor - 2*finger_z_slack)
  intersection() {
    finger_2d();
    union() {
      bottom_2d();
      translate([-100, 0])
      square(200);
    }
  }
  
  // Tabs.
  for (a = [-1, 1])
  linear_extrude(0.6)
  scale([a, 1]) {
    translate([81, -top_length])
    circle(d=8);
    
    translate([handle_width/2 - bottom_bevel - 6, -length-5])
    square(6);
  }
}

module test() {
  intersection() {
    union() {
      translate([0, 30])
      top();

      bottom();
    }
    
    translate([-100, -top_length-22])
    cube([200, 74, 200]);
  }
}

bottom_exterior();