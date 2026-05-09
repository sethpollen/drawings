use <finger.scad>

default_fn = 60;
$fn = default_fn;

// Parameters for the overall shape.
width = 194;
length = 352;
fan_length = 220;
fan_roundoff = 69;
handle_length = 86;
handle_width = 35;
grip_length = handle_length + 20;
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

// Edging.
edging_joint_lap = 7;
edging_width = 1.2;
edging_ridge_intrusion = 1.8;
edging_ridge_height = 1.4;
edging_z_slack = 0.2;

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
    intersection() {
      whole_2d();
      
      translate([-125, 0])
      square(250);
    }

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
    
    translate([-125, 0])
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
  
  // Lug to fit into socket.
  rotate([90, 0, 0])
  scale([1, 1, -1])
  hull() {
    translate([0, 0, 0.4])
    linear_extrude(thickness/2 + 0.001)
    offset(-1.2)
    grip_socket_2d();
    
    translate([0, 0, 1.3])
    linear_extrude(thickness/2 + 0.001)
    offset(-0.3)
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

module edging_profile_2d() {
  intersection() {
    whole_2d();
    
    translate([-125, -edging_joint_lap])
    square(250);
  }
}

module edging() {
  for (a = [-1, 1])
  scale([1, 1, a])
  difference() {
    hull() {
      linear_extrude(thickness/2 + 0.3)
      offset(edging_width, $fn=16)
      edging_profile_2d($fn=default_fn);
      
      linear_extrude(thickness/2 + edging_ridge_height)
      offset(0.2)
      edging_profile_2d();
    }
    translate([0, 0, -1]) {
      // Inner cutout to actually fit the paddle.
      linear_extrude(thickness/2 + edging_z_slack/2 + 1)
      offset(0.1) // A little room for glue.
      whole_2d();
      
      // Tall cutout to expose the face of the paddle.
      linear_extrude(thickness + 1)
      offset(-edging_ridge_intrusion)
      whole_2d();
    }
  }
}

edging();