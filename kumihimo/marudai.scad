top_diam = 295;
hole_diam = 40;
outer_thickness = 46;
total_height = 420;

outer_r = outer_thickness * 0.4;
inner_r = outer_thickness * 0.2;

notch_diam = 9;

module top_profile_2d() {
  $fn = 40;

  plateau_width = top_diam * 0.16;
  inner_thickness = outer_thickness - 15;

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
    translate([80, 0])
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

module notch_2d() {
  translate([outer_r, 0])
  circle(d=notch_diam, $fn=12);
}

module notch() {
  angle = 80;
  extra_distance = 1.2;
  
  translate([
    top_diam/2 - outer_r + extra_distance,
    0,
    -outer_r + extra_distance
  ])
  rotate([90, 0]) {
    rotate_extrude(angle=angle, $fn=40)
    notch_2d();

    for (r = [[90, 0, 0], [-90, 0, angle]])
    rotate(r)
    translate([0, 0, -0.001])
    linear_extrude(top_diam*0.5)
    notch_2d();
  }
}

module top() {
  difference() {
    translate([0, 0, -outer_thickness])
    rotate_extrude($fn=70)
    top_profile_2d();
    
    legs(extra_diam=0.3);
    
    for (a = [0:6:360])
    rotate([0, 0, a])
    notch();
  }
}

top();
