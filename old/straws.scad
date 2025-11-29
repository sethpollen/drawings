length = 30;
wall = 0.4;
$fn = 90;

module straw() {
  linear_extrude(length) {
    difference() {
      children();
      offset(-wall) children();
    }
  }
}

module heart_top() {
  for (a = [-1, 1])
    scale([a, 1])
      translate([2.1, 0]) circle(d=5);
}

module heart() {
  scale([1, 1] * 0.9) {
    heart_top();
    hull() {
      intersection() {
        heart_top();
        translate([0, -50]) square(100, center=true);
      }
      translate([0, -5.4]) square(0.00001);
    }
  }
}

straw() circle(d=7*2);
translate([17, 0, 0]) straw() circle(d=7.3*2, $fn=6);
translate([10, 13, 0]) straw() circle(d=8*2, $fn=4);
