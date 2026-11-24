$fn = 50;

difference() {
  sphere(d=40);
  sphere(d=37);
  translate([0, 0, -100]) cube(200, center=true);
}