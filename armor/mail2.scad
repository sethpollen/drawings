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
      gap = 0.5;
      translate([15, 0, 0])
      cube([30, gap, 50], center=true);
      
      clasp(cavity=true);
    }
  }
}

cavity_floor = 1.2;
cavity_slack = 0.25;

module clasp_2d() {
  angle = 13;
  
  // Cylinders on the ends.
  for (a = [-1, 1])
  rotate([0, 0, angle*a])
  translate([id/2 + gauge/2, 0])
  circle(d=gauge*0.66, $fn=40);
  
  // Connecting bar.
  intersection () {
    translate([15, 0])
    square([30, 7], center=true);
    
    translate([-0.4, 0])
    difference() {
      push = 0.7;
      circle(d=od-gauge*push);
      circle(d=id+gauge*push);
    }
  }
}

module clasp(cavity=false) {
  intersection () {
    translate([0, 0, -gauge/2 + cavity_floor])
    linear_extrude(cavity ? 10 : gauge - cavity_floor)
    offset(cavity ? cavity_slack : 0)
    clasp_2d();
    
    if(!cavity)
    ring();
  }
}

ring(true);
