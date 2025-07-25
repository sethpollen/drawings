$fn = 30;

module profile() {
  circle(d=23);
}

hull()
  linear_extrude(30)
    profile();