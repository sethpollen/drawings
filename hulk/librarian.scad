use <backpack.scad>

width = 14;
height = 2;
points = 2;
$fn = 30;
eps = 0.0001;

module profile() {
  difference() {
    union() {
      circle(d = width - 2*points);
      for (a = [-90, -45, 0, 45, 90]) {
        rotate([0, 0, a]) {
          hull() {
            square([6, eps], center=true);
            translate([0, width/2])
              square([0.7, 0.4], center=true);
          }
        }
      }
      hull() {
        circle(d=6);
        translate([0, -9])
          circle(d=6);
      }
    }
    circle(d=5.5);
  }
}

linear_extrude(0.2)
  offset(-0.2)
    profile();
translate([0, 0, 0.2])
  linear_extrude(height - 0.4)
    profile();
translate([0, 0, height - 0.2])
  linear_extrude(0.2)
    offset(-0.1)
      profile();

translate([0, -8])
  rotate([0, 0, -90])
    print();