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

// Socket for grip lugs.
module grip_socket_2d() {
  translate([grip_cutout_wall - handle_width/2, grip_cutout_wall])
  square([
    handle_width - grip_cutout_wall*2,
    handle_length*0.5 - grip_cutout_wall,
  ]);
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
    
    translate([0, top_length - length, -1])
    linear_extrude(thickness+2)
    grip_socket_2d();
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

module grip(offs=0) {
  hull()
  // Each tuple gives the backoff depth, then height.
  for (backoff = [[1.2, 0], [0.6, 0.8], [0, 2.4]])
  translate([0, 0, backoff[1]])
  linear_extrude(grip_length - backoff[1]*2)
  grip_2d(offs=offs, backoff=backoff[0]);
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
  
  // Lug to fit into socket.
  rotate([90, 0, 0])
  translate([0, 0, -0.4])
  scale([1, 1, -1])
  linear_extrude(thickness/2 + 0.001)
  difference() {
    offset(-0.3)
    grip_socket_2d();
    
    offset(-3)
    grip_socket_2d();
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

preview();