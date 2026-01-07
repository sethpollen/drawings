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

module link(od) {
  $fn = od;
  
  difference() {
    bevel_extrude(gauge)
    difference() {
      union() {
        circle(d=od);
        
        // Nubs to provide extra material for welding.
        translate([gauge/2-od/2, 0, 0])
        square([gauge*1.2, 3], center=true);
      }
      circle(d=od-2*gauge);
    }
    
    translate([-od/2, 0, 0])
    cube([od, 0.6, od], center=true);
  }
}

module main_link() {
  link(26.3);
}

module border_link() {
  link(23);
}

module hole_2d(dim) {
  $fn = 30;

  scale(dim)
  circle(d=1);
}

plate_od = 50;

module holes_2d() {
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate([7, plate_od/2-9.1])
  hole_2d([6.6, 10.3]);
}

module plate(ridge=true) {
  bevel_extrude(gauge)
  difference() {
    circle(d=plate_od);
    
    // Slightly cut off the sides.
    for (a = [-1, 1])
    translate([0, a*(50+plate_od/2-1.5)])
    square(100, center=true);
    
    // Holes.
    holes_2d();
  }
  
  if(ridge)
  translate([6, 0, gauge/2-0.001])
  linear_extrude(gauge*0.6, scale=0)
  scale(plate_od * [0.62, 0.35])
  rotate([0, 0, 45])
  square(1/sqrt(2), center=true);
}

module top_plate() {
  bevel_extrude(gauge)
  difference() {
    offset(gauge)
    hull()
    holes_2d();
    
    holes_2d();
  }
  
  translate([0, 0, gauge/2-0.001])
  linear_extrude(gauge*0.6, scale=0)
  scale(plate_od * [0.47, 0.31])
  rotate([0, 0, 45])
  square(1/sqrt(2), center=true);
}

module magnet_plate() {
  // TODO:
  intersection() {
    plate();

    translate([0, 50-9.5])
    cube(100, center=true);
  }
}

top_plate();