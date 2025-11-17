eps = 0.001;

pipe_od = 21.5;
pipe_id = 16.3;
clearance = 70;

// Distance from pipe center to top of plate.
height = clearance + pipe_od/2
  // Allowance for 3/4" board above.
  - 25.4*0.75;

plate_depth = 60;
plate_thickness = 6;

middle_plate_width = 45;
stem_width = 11;
plug_od = pipe_id - 0.5;
plug_full_length = 6;
plug_taper1_length = 11;
plug_taper2_length = 3;

end_lip = 8;
end_lip_length = 12;
hole_id = pipe_od + 0.6;
end_wall = 11;
end_plate_width = end_wall + end_lip_length + 18;

// #10 x 3/4" wood screw.
module screw_cavity() {
  $fn = 20;
  
  translate([0, 0, -5])
    cylinder(d=9, h=5+eps);
  cylinder(d1=9, d2=4.6, h=3.7);
  cylinder(d=4.6, h=20);
}

module stem_2d() {
  hull() {
    // Shave of a little bit so that the round underside has more plate contact.
    circle(d=plug_od-1);
    translate([0, height])
      square([plate_depth, eps], center=true);
  }
}

module plate_2d() {
  translate([-plate_depth/2, height-plate_thickness])
    square([plate_depth, plate_thickness]);
}

module screws() {
  for (x = plate_depth*0.25 * [-1, 1])
    translate([x, height-plate_thickness, 0])
      rotate([-90, 0, 0])
        screw_cavity();
}

module middle_piece_half() {
  $fn = 50;
  
  // Plug.
  hull() {
    linear_extrude(stem_width/2 + plug_full_length)
      circle(d=plug_od);
    linear_extrude(stem_width/2 + plug_full_length + plug_taper1_length)
      circle(d=plug_od-1.5);
    linear_extrude(stem_width/2 + plug_full_length + plug_taper1_length + plug_taper2_length)
      circle(d=plug_od-3);
  }
  
  // Stem.
  linear_extrude(stem_width/2)
    stem_2d();
  
  // Plate.
  difference() {
    linear_extrude(middle_plate_width/2) {
      intersection() {
        stem_2d();
        plate_2d();
      }
    }
    
    translate([0, 0, middle_plate_width*0.31])
      screws();
  }
}

module middle_piece() {
  for (a = [-1, 1])
    scale([1, 1, a])
      middle_piece_half();
}

module end_block_2d(channel=true) {
  $fn = 60;

  difference() {
    hull() {
      circle(d=hole_id+2*end_lip);
      translate([0, height])
        square([plate_depth, eps], center=true);
    }
    
    // Channel.
    if (channel) {
      hull() {
        circle(d=hole_id);
        translate([0, 25]) circle(d=hole_id);
      }
      hull() {
        translate([0, 25]) circle(d=hole_id);
        translate([100, 25]) circle(d=hole_id);
      }
    }
  }
}

module end_piece() {
  linear_extrude(end_wall)
    end_block_2d(false);
  linear_extrude(end_wall + end_lip_length)
    end_block_2d();
  
  // Plate.
  difference() {
    linear_extrude(end_plate_width) {
      intersection() {
        end_block_2d();
        plate_2d();
      }
    }
    
    translate([0, 0, (end_wall + end_lip_length + end_plate_width)/2])
      screws();
  }
}

end_piece();