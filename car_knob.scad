$fn = 90;

hull() {
  scale([1, 1, 0.4])
    sphere(6);
  scale([1, 1, -1])
    cylinder(h=4, r=4);
}