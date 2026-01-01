module bevel_extrude(h, i=0) {
  face = h/(1+sqrt(2));
  bevel = (h-face)/2;
  offs = i*0.2;
  
  if (i == 0) {
    translate([0, 0, -h/2])
    linear_extrude(h)
    offset(-bevel)
    children();
  }

  if (offs < bevel) {
    translate([0, 0, bevel-offs-h/2])
    linear_extrude(h - 2*(bevel-offs))
    offset(-offs)
    children();
    
    // Recurse.
    bevel_extrude(h, i+1)
    children();
  }
}

gauge = 3.8;

module link() {
  od = 28.5;
  $fn = od;
  
  difference() {
    bevel_extrude(gauge)
    difference() {
      circle(d=od);
      circle(d=od-2*gauge);
    }
    
    translate([-od/2, 0, 0])
    cube([od, 0.7, od], center=true);
  }
}

module hole_2d(dim) {
  $fn = 30;

  scale(dim)
  circle(d=1);
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

module plate() {
  od = 60;
  
  bevel_extrude(gauge)
  difference() {
    circle(d=od);
    
    for (a = [-1, 1], b = [-1, 1])
    scale([a, b])
    translate([7.5, od/2-10.2])
    hole_2d([8, 12]);
  }
}

module print_test() {
  scale(0.65) {
    translate([75, 0]) {
      plate();
      translate([-45, 0]) link();
    }
  }
}

print_test();