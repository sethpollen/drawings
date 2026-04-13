$fn = 60;

// Light tank.
tank_w = 12.3;
tank_l = 20.2;

wall_l = 17.5;
slack_w = 0.6;

wall_t = 2.2;
wall_h = 8;
flor = 2;

outer_w = tank_w + slack_w + wall_t*2;

difference() {
  cube([outer_w, wall_l, wall_h + flor]);
  
  translate([wall_t, -1, flor])
  cube([tank_w + slack_w, wall_l*2, 20]);

  translate([9, -8.6, 10*sqrt(2)])
  rotate([45, 0, 0])
  cube(20, center=true);

  translate([0, wall_l])
  scale([1, -1, 1])
  translate([9, -8.6, 10*sqrt(2)])
  rotate([45, 0, 0])
  cube(20, center=true);
}

linear_extrude(flor) {
  intersection() {
    for (a = [0, 1])
    translate([outer_w/2, a*wall_l])
    scale([1, 0.75])
    circle(d=outer_w);
    
    extra = 0.6;
    translate([-50, -wall_l*extra/2])
    square([100, wall_l*(1+extra)]);
  }
}