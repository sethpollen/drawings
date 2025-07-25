$fn=90;
height=12;

scale([0.8, 0.8, 1]) {
  difference() {
    cylinder(h=height, r=20);
    translate([0, 0, height+10])
      sphere(r=20);
  }
}