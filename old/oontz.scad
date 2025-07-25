$fn = 60;
step = 0.2;

triangle_side = 105;
limit_radius = 40.7;

module speaker_cavity_2d() {
  intersection() {
    circle(limit_radius);
    hull()
      for (a = [0, 120, 240])
        rotate([0, 0, a])
          translate([triangle_side * sqrt(3) / 3, 0])
            square(0.001, center=true);
  }
}

wall = 7;

two_by_four = 25.4 * [1.5, 1.5] + [0.1, 0.1];
board_offset = [-32.3 - wall, 5.38 - wall] - two_by_four;

module full_2d() {
  translate(board_offset)
    offset(wall)
      square(two_by_four + [30.5, 0]);
  
  offset(wall)
    speaker_cavity_2d();
}

height = 60 + wall;
window = 47;

module exterior() {
  for (sz = [[1, 0], [-1, height]])
    translate([0, 0, sz[1]])
      scale([1, 1, sz[0]])
        for (z = [0 : step : wall])
          translate([0, 0, z])
            linear_extrude(step + 0.00001)
              offset(sqrt(wall*wall - (wall-z-0.5)*(wall-z-0.5)) - wall - (sz[0] != 1 ? 0 : z == 0 ? 0.3 : z == 0.2 ? 0.15 : 0) )
                full_2d();
  
  translate([0, 0, wall])
    linear_extrude(height - 2*wall)
       full_2d();
}

screw_head_diameter = 8.2;
screw_diameter = 4;

module screw_hole() {
  rotate([90, 0, 0]) {
    cylinder(h=0.301, d=screw_head_diameter);
    translate([0, 0, 0.3])
      cylinder(h=screw_head_diameter/2, d1=screw_head_diameter, d2=0);
    cylinder(h=wall+1, d=screw_diameter);
  }
}

module piece() {
  difference() {
    exterior();
    
    for (a = [-150, -30]) {
      rotate([0, 0, a]) {
        translate([-window/2, 0, wall])
          cube([window, 100, height - 2*wall]);
        
        for (x = -window/2 * [-1, 1], y = [29, 38])
          translate([x, y, wall])
            linear_extrude(height - 2*wall)
              rotate([0, 0, 45])
                square(3, center=true);
      }
    }
    
    translate([0, 0, wall])
      linear_extrude(height)
        speaker_cavity_2d();
    
    translate([board_offset.x - two_by_four.x, board_offset.y, -0.5])
      linear_extrude(height + 1)
        scale([2, 1, 1]) square(two_by_four);

    // Screw holes.
    translate(board_offset + [0, two_by_four.y + wall + 0.001])
      translate([two_by_four.x / 3, 0, height-15]) screw_hole();
    translate(board_offset + [0, -wall - 0.001])
      scale([1, -1, 1])
        translate([two_by_four.x / 3, 0, 15]) screw_hole();
  }
  
  // Print aid.
  linear_extrude(0.4)
    translate(board_offset)
      for (x = [0, 10, 20])
        translate([x, 0])
          square([8, two_by_four.y]);
}

piece();