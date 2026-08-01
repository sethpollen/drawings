eps = 0.0001;

// 0 for fast, 1 for full render.
quality = 1;

blade_length = 146;
blade_width = 7;
blade_depth = 32;
tip_blunt = 3;

tang_depth = 18;
tang_length = 70;
tang_offset = 5;

handle_width = 18;
handle_depth = 32;
handle_length = 80;

crossbar_depth = blade_depth + 20;
crossbar_width = 22;
crossbar_thickness = 4.6;

module blade_2d() {
  edge_depth = 10;
  for (a = [-1, 1])
    scale([a, 1])
      polygon([
        [-eps, 0],
        [blade_width/2, 0],
        [blade_width/2, blade_depth-edge_depth],
        [0.25, blade_depth],
        [-eps, blade_depth],
      ]);
}

module extrude_blade() {
  straight_length = blade_length - blade_depth + tip_blunt;
  linear_extrude(straight_length)
    children();
  translate([0, 0, straight_length-eps])
    rotate([0, 90, 180])
      rotate_extrude(angle=90, $fn=30+quality*30)
        rotate([0, 0, 90])
          children();
}

module pill(r, length) {
  hull()
    for (a = [-1, 1])
      scale([1, 1, a])
        translate([0, 0, length/2 - r])
          sphere(r); 
}

module blade() {
  difference() {
    intersection() {
      extrude_blade()
        blade_2d();
      translate([0, 0, -tip_blunt])
        extrude_blade()
          translate([-blade_width/2, 0])
            square([blade_width, blade_depth]);
      translate([0, blade_length*sqrt(2)-blade_width/4, 0])
        rotate([0, 0, 45])
          cube(blade_length*2, center=true);
    }
    
    depression_r = 10;
    depression_depth = 0.8;
    for (a = [-1, 1])
      scale([a, 1, 1])
        translate([blade_width/2 + depression_r - depression_depth, 10, blade_length*0.4])
          pill(r=depression_r, length=blade_length*0.6, $fn=25+quality*45);
  }
}

module tang(expand=0) {
  translate([-blade_width/2, tang_offset, eps-tang_length])
    linear_extrude(tang_length)
      offset(expand)
        square([blade_width, tang_depth]);
}

module tombstone_2d(r, length) {
  translate([length-r, 0])
    circle(r=r);
  translate([0, -r])
    square([length-r, r*2]);
}

module crossbar_2d() {
  hull()
    for (y = [crossbar_width/2, crossbar_depth-crossbar_width/2])
      translate([0, y - crossbar_depth*0.19])
        circle(r=crossbar_width/2, $fn=20+quality*50);
}

module crossbar() {
  bevel = 0.8;
  hull() {
    translate([0, 0, bevel])
      linear_extrude(crossbar_thickness - bevel*2)
        crossbar_2d();
    linear_extrude(crossbar_thickness)
      offset(-bevel)
        crossbar_2d();
  }
}

module handle() {
  $fn = 30 + quality*30;
  r = handle_width/2;

  difference() {
    union() {
      difference() {
        translate([0, handle_depth + 1, -handle_length]) {
          rotate([0, 0, -90]) {
            intersection() {
              linear_extrude(handle_length)
                tombstone_2d(r, handle_depth);
              
              grip_r = handle_length * 2.5;
              translate([grip_r, 0, handle_length/2])
                rotate([90, 0, 0], $fn=100+quality*250)
                  rotate_extrude()
                    tombstone_2d(r, grip_r);
            }
          }
        }
        
        // Finger sculpts.
        translate([0, handle_depth, 0]) {
          translate([0, 6.8, -7.5]) finger_sculpt();
          translate([0, 8.7, -26]) finger_sculpt();
          translate([0, 8.7, -46]) finger_sculpt();
          translate([0, 7.5, -66]) finger_sculpt();
        }
        
        // Knurling.
        knurl = 0.6;
        knurl_spacing = 5;
        for (a = [-1, 1], b = [0:20])
          translate([a*handle_width/2, 0, 30 - b*knurl_spacing])
            rotate([-30, 0, 0])
              rotate([0, 45, 0])
                cube([knurl, 100, knurl], center=true);
      }

      // Pommel.
      translate([0, handle_depth/2+1, -handle_length])
        scale([1, 1, 0.7])
          rotate([90, 0, 0])
            pill(handle_width*0.75, handle_depth+3);
      
      translate([0, 0, -eps])
        crossbar();
    }
    
    // Flatten bottom of pommel.
    translate([0, 0, -handle_length-40-handle_width*0.4])
      cube(80, center=true);
    
    // Cavity for tang.
    for (z = [2, -2])
      translate([0, 0, z])
        tang(expand=0.3);
    
    // Cavity in crossbar for blade.
    translate([0, 0, 1.2])
      linear_extrude(crossbar_thickness)
        offset(0.25)
          blade_2d();
    
    // Air hole in base of pommel.
    translate([0, handle_depth/2, -500])
      cylinder(h=1000, d=1.1);
  }
}

module finger_sculpt() {
  $fn = 30 + quality*40;

  scale([handle_width/2, 5, 10]) {
    translate([0, -1, 0]) {
      rotate([90, 0, 90]) {
        rotate_extrude() {
          difference() {
            translate([0, -1])
              square(2);
            translate([2, 0])
              circle(d=2);
          }
        }
      }
    }
  }
}

module blade_print() {
  rotate([90, 0, 0]) {
    blade();
    tang();
  }
}

blade_print();