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

module bar(length) {
  rotate([0, 90, 0])
  linear_extrude(length)
  hull()
  octagon_2d();
}

module link() {
  od = 28.5;
  
  difference() {
    torus(od);
    
    translate([-od/2, 0, 0])
    cube([od, 0.8, od], center=true);
  }
}

module plate() {
  od = 60;
  inner_od = od-gauge*6;
  bars = 10;
  
  torus(od);
  torus(inner_od);
  
  for (a = [0:bars])
  rotate([0, 0, 360*a/bars])
  translate([inner_od/2-gauge/2, 0, 0])
  bar((od-inner_od)/2);
}

scale(0.65) {
  link();
  plate();
}
