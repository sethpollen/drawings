eps = 0.001;

// Cavity dimensions.
major_width = 133;
major_height = 82;
minor_width = 89;
minor_height = 40;

cavity_length = 120;

wall = 5;
roundoff = min(1.9, wall*0.45);

module cavity_2d(boxy=false) {
  flat = 1;
  for (a = [-1, 1]) {
    scale([a, 1]) {
      polygon([
        [-eps, boxy ? 0 : minor_width*tan(30)/4],
        [minor_width/4, 0],
        [minor_width/4 + flat, 0],
        [minor_width/2 + flat, boxy ? 0 : minor_width*tan(30)/4],
        [minor_width/2 + flat, boxy ? 0 : minor_height],
        [major_width/2 + flat, boxy ? 0 : minor_height + (major_width-minor_width)*tan(30)/2],
        [major_width/2 + flat, major_height],
        [-eps, major_height],
      ]);
      
      // Flare the bottom to make it easier to drop the cards in.
      translate([-minor_width/2, minor_height-13])
        rotate([0, 0, 17])
          square([20, 35]);
    }
  }
}

module inner_profile_2d(boxy=false) {
  offset(roundoff, $fn=30) {
    offset(-roundoff) {
      translate([0, wall]) {
        difference() {
          offset(delta=wall)
            cavity_2d(boxy=boxy);
          cavity_2d(boxy=false);
          
          // Cut off the ceiling.
          translate([-500, major_height - eps])
            square(1000);
        }
      }
    }
  }
}

module end_profile_2d() {
  hull()
    inner_profile_2d(boxy=true);
}

module tray() {
  end_wall = wall;

  rotate([90, 0, 0]) {
    for (a = [-1, 1]) {
      scale([1, 1, a]) {
        translate([0, 0, cavity_length/2]) {
          linear_extrude(end_wall - roundoff)
            end_profile_2d();
            
          steps = 30;
          for (b = [0 : 1/steps : 1-1/steps])
            translate([0, 0, end_wall + (b-1)*roundoff])
              linear_extrude(0.1)
                offset(-roundoff * (1-sqrt(1-b*b)))
                  end_profile_2d();
        }
      }
    }
      
    translate([0, 0, -cavity_length/2])
      linear_extrude(cavity_length)
        inner_profile_2d(boxy=true);
  }
}

divider_top = 4;

module divider_2d() {
  slack = 0.15;
  small_roundoff = 1.5;
  top_width = major_width + 2*wall + 1;

  offset(small_roundoff, $fn=30) {
    offset(-small_roundoff - slack) {
      cavity_2d();
      
      translate([-top_width/2, major_height])
        square([top_width, divider_top]);
    }
  }
}

module divider() {
  length = 12;

  linear_extrude(0.2)
    offset(-0.33)
      divider_2d();
  translate([0, 0, 0.2])
    linear_extrude(length - 0.2)
      divider_2d();
}

module main() {
  divider();
}

main();