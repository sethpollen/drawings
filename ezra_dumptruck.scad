eps = 0.001;
$fn = 30;

// Cavity for a #8 x 1/2" screw.
module screw() {
  h1 = 0.4;
  d1 = 8.1;
  
  h2 = 2.8;
  d2 = 4.1;
  
  translate([0, 0, -20])
  cylinder(h=20+h1+eps, d=d1);
  
  translate([0, 0, h1])
  cylinder(h=h2+eps, d1=d1, d2=d2);
  
  cylinder(h=20, d=d2);
}

pin_d = 6;
pin_h = 16;

bracket_l = 59;
bracket_h = 19;
bracket_w = 11.4;

module hinge() {
  cylinder(h=pin_h, d=pin_d);
  
  difference() {
    translate([0, 0, -bracket_w])
    linear_extrude(bracket_w+eps)
    hull() {
      circle(d=pin_d);
      
      tip = 2.2;
      tuck = 8;
      translate([tuck-pin_d/2, bracket_h-tip])
      square([bracket_l-tuck, tip]);
    }
  
    for (x = bracket_l * [0.2, 0.75])
    translate([x, bracket_h-3.5, -bracket_w/2])
    rotate([-90, 0, 0])
    screw();
  }
}

hinge();