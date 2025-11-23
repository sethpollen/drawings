ball_d = 12;

module ball() {
  $fn = 30;
  intersection() {
    sphere(d=ball_d);
    translate([0, 0, 25])
      cube(50, center=true);
  }
}

module balls() {
  for (x = [0:4], y = [0:5])
    translate((ball_d + 1) * [x, y])
      ball();
}

balls();