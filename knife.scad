eps = 0.0001;

blade_length = 130;
blade_width = 7;
blade_depth = 35;
tip_blunt = 3;

tang_depth = 20;
tang_length = 95;

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
      rotate_extrude(angle=90, $fn=60)
        rotate([0, 0, 90])
          children();
}

module blade() {
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
}

module tang() {
  translate([-blade_width/2, 4, eps-tang_length])
    cube([blade_width, tang_depth, tang_length]);
}

blade();
color("red") tang();