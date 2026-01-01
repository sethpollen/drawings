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
    cube([od, 0.7, od], center=true);
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

module hole_oblong_2d(dim) {
  $fn = 30;
  d = min(dim);
  
  hull()
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate(0.5 * (dim - [d, d]))
  circle(d=d);
}

module hole_oval_2d(dim) {
  $fn = 30;
  
  scale(dim)
  circle(d=1);
}

module hole_2d(dim) {
  hole_oval_2d(dim);
}

module hole(dim) {
  face = gauge/(1+sqrt(2));

  for (a = [-1, 1])
  scale([1, 1, a]) {
    translate([0, 0, -0.01])
    linear_extrude(gauge)
    hole_2d(dim);
    
    hull() {
      translate([0, 0, face/2])
      linear_extrude(1)
      hole_2d(dim);
      
      translate([0, 0, face/2+gauge])
      linear_extrude(1)
      offset(gauge)
      hole_2d(dim);
    }
  }
}

module plate2() {
  od = 60;

  difference() {
    hull()
    torus(od);
    
    for (a = [-1, 1], b = [-1, 1])
    scale([a, b])
    translate([7.5, od/2-10.2])
    hole([8, 12]);
  }
}

scale(0.65) {
  for (a = [0:5])
  rotate([0, 0, a*60])
  translate([75, 0]) {
    plate2();
    translate([-45, 0]) link();
  }
}
