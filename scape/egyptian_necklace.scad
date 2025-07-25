$fn = 90;

linear_extrude(1)
difference() {
  circle(r=10);
  circle(r=4);
  translate([0, -50])
    square(100);
}