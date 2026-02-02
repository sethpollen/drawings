// https://www.mailleartisans.org/weaves/weavedisplay.php?key=6 defines the AR
// as ring ID over wire diameter.

gauge = 4.8;
id = 23;
od = id + gauge*2;
$fn = 80;

module octagon_2d(gauge) {
  intersection_for(a = [0, 45])
  rotate([0, 0, a])
  square(gauge, center=true);
}

module ring(split=false) {
  difference() {
    rotate_extrude()
    translate([id/2+gauge/2, 0])
    octagon_2d(gauge);
    
    if(split) {
      gap = 0.3;
      translate([15, 0, 0])
      cube([30, gap, 50], center=true);
      
      clasp_cavity();
    }
  }
}

cavity_floor = 1.2;
cavity_slack = 0.25;

module clasp_2d() {
  // Blocks on the ends.
  for (a = [-1, 1])
  scale([1, a])
  translate([id/2 + gauge/2 - 1.5, 2])
  hull() {
    square([2.4, 1]);
    square([2, 1.4]);
  }
  
  // Connecting bar.
  translate([id/2 + gauge/2 - 1.5, -3])
  square([1.2, 6]);
}

module clasp() {
  intersection () {
    translate([0, 0, -gauge/2 + cavity_floor])
    linear_extrude(gauge - cavity_floor)
    clasp_2d();
    
    ring();
  }
  
  // Nub to provide extra material for welding. Only 2 layers.
  translate([0, 0, -gauge/2 + cavity_floor])
  linear_extrude(gauge - cavity_floor + 0.4)
  intersection () {
    clasp_2d();

    translate([15, 0])
    square([30, 3], center=true);
  }
}

module clasp_cavity() {
  translate([0, 0, -gauge/2 + cavity_floor])
  linear_extrude(10)
  offset(cavity_slack)
  clasp_2d();
}

module print() {
  ring(true);
  
  translate([-8, 0, -cavity_floor])
  clasp();
}

print();
