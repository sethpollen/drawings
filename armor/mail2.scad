gauge = 3.8;

module octagon_2d() {
  intersection_for(a = [0, 45])
  rotate([0, 0, a])
  square(gauge, center=true);
}

module torus(od) {
  $fn = od;
  
  rotate_extrude()
  translate([od/2-gauge/2, 0])
  octagon_2d();
}

module bar(length, extra_width) {
  rotate([0, 90, 0])
  linear_extrude(length)
  hull()
  for (y = extra_width/2 * [-1, 1])
  translate([0, y])
  octagon_2d();
}

module link() {
  od = 28.5;
  
  difference() {
    torus(od);
    
    translate([-od/2, 0, 0])
    cube([od, 0.9, od], center=true);
  }
}

module plate() {
  od = 60;
  inner_od = od-gauge*6;
  
  torus(od);
  torus(inner_od);
  
  for (a = 90 * [0, 1, 2, 3])
  rotate([0, 0, a])
  translate([inner_od/2-gauge/2, 0, 0])
  bar((od-inner_od)/2, 1);
}

link();
plate();
