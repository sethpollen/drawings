height = 4;
od = 12;
curve_r = 1.3;
$fn = 40;

module shell() {
  rotate_extrude() {
    hull() {
      square([1, height]);
      translate([od/2 - height/2, 0]) {
        translate([0, curve_r])
          circle(curve_r);
        translate([0, height-curve_r])
          circle(curve_r);
      }
    }
  }
}

module dress() {
  intersection() {
    children();
    translate([-500, -500, 0.2])
      cube(1000);
  }
  linear_extrude(0.2)
    offset(-0.25)
      projection(cut=true)
        translate([0, 0, -0.1])
          children();
}

module S() {
  difference() {
    shell();
    translate([-3.3, -3.3, -1])
      linear_extrude(100)
        offset(-0.1)
          text("S", size=7);
  }
}

module J() {
  difference() {
    shell();
    translate([-2.4, -3.3, -1])
      linear_extrude(100)
        offset(-0.1)
          text("J", size=7);
  }
}

module C() {
  difference() {
    shell();
    translate([-3.7, -3.3, -1])
      linear_extrude(100)
        offset(-0.1)
          text("C", size=7);
  }
}

module M() {
  difference() {
    shell();
    translate([-3.3, -2.7, -1])
      linear_extrude(100)
        offset(-0.05)
          text("M", size=5.7);
  }
}

dress() S();
