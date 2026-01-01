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

gauge = 3.6;

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

module plate() {
  od = 50;
  
  bevel_extrude(gauge)
  difference() {
    circle(d=od);
    
    // Slightly cut off the sides.
    for (a = [-1, 1])
    translate([0, a*(50+od/2-1.2)])
    square(100, center=true);
    
    // Cut off much of the top.
    translate([50+od/2-6, 0])
    square(100, center=true);
    
    // Holes.
    for (a = [-1, 1], b = [-1, 1])
    scale([a, b])
    translate([7.5, od/2-10.2])
    hole_2d([8, 12]);
  }
}

module print_test() {
  translate([75, 0]) {
    translate([37, 20]) plate();
    link();
  }
}

print_test();