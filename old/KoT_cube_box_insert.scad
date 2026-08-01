eps = 0.001;
width = 82;
thickness = 2.7;

difference() {
  linear_extrude(thickness)
    square(width, center=true);
  
  translate([0, 0, thickness+eps])
    scale([1, 1, -1])
      linear_extrude(width/2, scale=0)
        square(width, center=true);
  
  for (a = [0, 1, 2, 3])
    rotate([0, 0, a*90])
      translate([0, width/2])
        rotate([45, 0, 0])
          cube([200, 0.75, 0.75], center=true);
}