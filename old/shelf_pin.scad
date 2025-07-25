length = 19;
d = 5;
$fn = 8;

translate([0, length/2, d*0.462])
  rotate([90, 0, 0])
    rotate([0, 0, 360/16])
      cylinder(h=length, d=d);

for (a = [-1, 1])
  scale([1, a, 1])
    translate([0, length/2 + 2.99])
      linear_extrude(0.4)
        square(6, center=true);