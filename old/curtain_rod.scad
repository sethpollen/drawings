eps = 0.001;

pipe_od = 21.5;
pipe_id = 16.3;
clearance = 70;

// Distance from pipe center to top of plate.
height = clearance + pipe_od/2
  // Allowance for 3/4" board above.
  - 25.4*0.75;

plate_depth = 60;
plate_thickness = 7.5;

middle_plate_width = 45;
stem_width = 12;
plug_od = pipe_id - 0.9;
plug_full_length = 12;
plug_taper_length = 1;

end_lip = 8;
end_lip_length = 14;
hole_id = pipe_od + 1;
end_wall = 9;
end_plate_width = end_wall + end_lip_length + 32;

// #10 x 3/4" wood screw.
module screw_cavity() {
  $fn = 40;
  
  translate([0, 0, -10])
    cylinder(d=9.6, h=10+eps);
  cylinder(d1=9.6, d2=4.6, h=3.7);
  cylinder(d=4.6, h=20);
}

module stem_2d() {
  hull() {
    circle(d=pipe_od-0.5);
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
  linear_extrude(stem_width/2)
    circle(d=pipe_od-0.5);
  hull() {
    linear_extrude(stem_width/2 + plug_full_length)
      circle(d=plug_od);
    linear_extrude(stem_width/2 + plug_full_length + plug_taper_length)
      circle(d=plug_od-plug_taper_length);
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
    
    // Plate chamfer.
    translate([0, height, middle_plate_width/2])
      rotate([45, 0, 0])
        cube([100, 0.6, 0.6], center=true);
  }
}

module middle_piece() {
  for (a = [-1, 1])
    scale([1, 1, a])
      middle_piece_half();
}

module end_block_2d(channel) {
  $fn = 80;

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
    end_block_2d(channel=false);

  // Channel housing.
  roundoff = 1.1;
  linear_extrude(end_wall + end_lip_length)
    offset(roundoff, $fn=16) offset(-roundoff)
      end_block_2d(channel=true);

  plate_protrusion = end_plate_width/2 - end_wall/2 - end_lip_length/2;
  translate([0, 0, -plate_protrusion]) {
    difference() {
      // Plate.
      linear_extrude(end_plate_width) {
       intersection() {
          end_block_2d();
          plate_2d();
        }
      }
      
      for (z = [plate_protrusion/2, end_plate_width-plate_protrusion/2])
        translate([0, 0, z])
          screws();
      
      // Plate chamfer.
      for (z = [0, end_plate_width])
        translate([0, height, z])
          rotate([45, 0, 0])
            cube([100, 0.6, 0.6], center=true);
    }
  }
}

horse_wall = 8;
horse_height = 80;
horse_width = 90;
horse_gap = 1.1;
horse_floor = horse_height*0.3;
horse_hole_id = pipe_od + 0.6;

module saw_horse_sides() {
  $fn = 30;
  
  for (a = [-1, 1]) {
    scale([1, 1, a]) {
      translate([0, 0, horse_wall/2 + horse_gap/2]) {
        hull() {
          // Toroidal disk.
          rotate_extrude() {
            translate([horse_hole_id/2 + horse_wall/2, 0])
              circle(d=horse_wall);
            translate([0, -horse_wall/2])
              square([horse_hole_id/2 + horse_wall/2, horse_wall]);
          }
          
          // Base plate.
          splay = 4;
          translate([horse_height, 0, splay/2])
            cube([eps, horse_width, horse_wall+splay], center=true);
        }
      }
    }
  }
}

module saw_horse() {
  $fn = 70;

  difference() {
    saw_horse_sides();
    
    translate([0, 0, -25])
      cylinder(d=horse_hole_id, h=50);
  }
  
  difference() {
    hull()
      saw_horse_sides();
    cube([(horse_height-horse_floor)*2, 100, 100], center=true);
  }
}

middle_piece();
