$fn = 6;

module ext(h) {
  translate([0, 0, -h/2])
  linear_extrude(h)
  children();
}

module setting() {
  difference() {
    hull() {
      ext(3) circle(d=45);
      ext(10) circle(d=40.2);
    }
    linear_extrude(20) circle(d=35);
  }
}

module gem() {
  slack = 0.4;
  h = 15;
  
  difference() {
    hull() {
      ext(8.5) circle(d=35-slack);
      ext(h) circle(d=25);
    }

    translate([0, 0, -25])
    cube(50, center=true);
    
    translate([0, 0, h/2-0.8])
    linear_extrude(2)
    difference() {
      circle(d=22);
      circle(d=19.9);
    }
  }
}

setting();
gem();