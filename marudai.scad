top_diam = 305;
hole_diam = 48;
outer_thickness = 42;

leg_socket_diam = 25.4;

module top_profile_2d() {
  $fn = 30;

  plateau_width = top_diam * 0.16;
  inner_thickness = outer_thickness - 15;

  outer_r = outer_thickness * 0.4;
  inner_r = outer_thickness * 0.2;
  bottom_bevel = 10;

  hull() {
    translate([top_diam/2, 0]) {
      for (x = [0, plateau_width])
      translate([-outer_r - x, outer_thickness - outer_r])
      circle(r=outer_r);
      
      translate(bottom_bevel/sqrt(2) * [-1, 1])
      rotate([0, 0, 45])
      square(bottom_bevel, center=true);
    }
    translate([hole_diam/2, 0]) {
      translate([inner_r, inner_thickness - inner_r])
      circle(r=inner_r);
      
      translate(bottom_bevel/sqrt(2) * [1, 1])
      rotate([0, 0, 45])
      square(bottom_bevel, center=true);
    }
  }
}

module top() {
  difference() {
    rotate_extrude($fn=70)
    top_profile_2d();
    
    for (a = [0, 90, 180, 270])
    rotate([0, 0, 45+a])
    translate([top_diam/2 - 55, 0, -0.01]) {
      $fn = 24;
      cylinder(d=leg_socket_diam, h=outer_thickness-2);
      cylinder(d1=leg_socket_diam+2, d2=leg_socket_diam, h=1);
    }
  }
}

top();