od = 19.5;
gap = 0.6;
gauge = 0.4;
h = 5.8;
$fn = 40;

linear_extrude(h)
difference() {
  circle(d=od);
  circle(d=od-2*gauge);
  
  translate([-gap/2, 0])
  square([gap, 10]);
}