top_diam = 305;
hole_diam = 49;
outer_thickness = 50;
total_height = 420;

module top_profile_2d() {
  $fn = 40;

  plateau_width = top_diam * 0.16;
  inner_thickness = outer_thickness - 15;

  outer_r = outer_thickness * 0.4;
  inner_r = outer_thickness * 0.2;

  hull() {
    translate([top_diam/2, 0]) {
      for (x = [0, plateau_width])
      translate([-outer_r - x, outer_thickness - outer_r])
      circle(r=outer_r);
      
      translate([-20, 0])
      square(0.0001);
    }
    translate([hole_diam/2, 0]) {
      translate([inner_r, inner_thickness - inner_r])
      circle(r=inner_r);
      
      polygon([
        [12, 0],
        [12, 1],
        [0, 17],
      ]);
    }
  }
}

module legs(extra_diam=0) {
  diam = 25.4 + extra_diam;
  tilt_angle = 14;
  down = 5;
  
  difference() {
    for (a = [0, 90, 180, 270])
    rotate([0, 0, a])
    translate([85, 0])
    rotate([0, -tilt_angle, 0])
    translate([0, 0, -total_height - 100 - down])
    cylinder(d=diam, h=total_height+100, $fn=30);
    
    // Approximate the actual leg length.
    translate([0, 0, -total_height])
    scale([1, 1, -1])
    linear_extrude(100)
    square(500, center=true);
  }
}

module top() {
  difference() {
    translate([0, 0, -outer_thickness])
    rotate_extrude($fn=70)
    top_profile_2d();
    
    legs(extra_diam=0.3);
  }
}

top();
