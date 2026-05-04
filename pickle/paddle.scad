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
grip_cutout_wall = handle_width * 0.3;

// Parameters for slicing into printable sections.
top_length = 212 - finger_length()/2;

// Parameters for thickness.
thickness = 13;
finger_floor = 2;
finger_z_slack = 0.4;

bottom_bevel = 2.8;

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
    translate([0, handle_length/2 - length ])
    square([handle_width, handle_length], center=true);
  }
}

module top_2d() {
  intersection() {
    whole_2d();
    
    translate([-100, 0])
    square(250);
  }
}

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

module top() {
  difference() {
    linear_extrude(thickness)
    top_2d();

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

module bottom_2d() {
  difference() {
    whole_2d();
    
    translate([-100, 0])
    square(250);
  }
}

module bottom_exterior() {
  bevel_layers = bottom_bevel*5;
  
  difference() {
    for (a = [0:bevel_layers])
    translate([0, 0, a*0.2])
    linear_extrude(thickness-a*0.4)
    intersection() {
      offset((a-bevel_layers)*0.2) {
        bottom_2d();
        
        for (y = [-bottom_bevel-9, top_length-length-200])
        translate([-100, y])
        square([200, 200]);
      }
      bottom_2d();
    }
    
    // Cutout for grip lugs.
    translate([
      grip_cutout_wall - handle_width/2,
      top_length - length + grip_cutout_wall,
      -1
    ])
    linear_extrude(thickness+2)
    square([
      handle_width - grip_cutout_wall*2,
      handle_length*0.5 - grip_cutout_wall,
    ]);
  }
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

module test() {
  intersection() {
    union() {
      translate([0, 20])
      top();

      bottom();
    }
    
    translate([-75, -18])
    cube([150, 56, 200]);
  }
}

top();