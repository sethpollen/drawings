eps = 0.00001;
$fn = 50;

hole_diam = 33.5;
hole_depth = 3.2;

fence = 4.6;
rows = 3;
cols = 4;
gap = 6;
extra_gap = 1;
outer_gap = 5.2;

module gridify() {
  for (r = [1:rows], c = [1:cols])
    translate([(c-1) * (hole_diam + gap), (r-1) * (hole_diam + gap + extra_gap)])
      children();
}

module fence_2d() {
  difference() {
    gridify()
      offset(fence)
        circle(d=hole_diam);
    gridify()
      circle(d=hole_diam);
  }
}

module floor_2d() {
  roundoff = 4;
  
  offset(roundoff) offset(-roundoff) {
    translate([-hole_diam/2 - outer_gap, -hole_diam/2 - outer_gap]) {
      square([
        cols*hole_diam + (cols-1)*gap + 2*outer_gap,
        rows*hole_diam + (rows-1)*(gap+extra_gap) + 2*outer_gap
      ]);
    }
  }
}

module wall_2d() {
  wall = 1;
  
  difference() {
    floor_2d();
    offset(-wall) floor_2d();
  }
}

module main() {  
  difference() {
    color("orange")
      linear_extrude(hole_depth)
        fence_2d();

    gridify()
      translate([0, 0, hole_depth - 0.8])
        cylinder(h=1.01, d1=hole_diam, d2=hole_diam+2);
  }
  
  floor_thickness = 1;
  translate([0, 0, -floor_thickness])
    linear_extrude(0.2)
      offset(-0.6)
        floor_2d();
  translate([0, 0, 0.2-floor_thickness])
    linear_extrude(0.2)
      offset(-0.2)
        floor_2d();
  translate([0, 0, 0.4-floor_thickness])
    linear_extrude(floor_thickness-0.4)
      floor_2d();
  
  wall_height = 59;
  translate([0, 0, -eps])
    linear_extrude(wall_height)
      wall_2d();
}

module marvel() {
  color("red") {
    translate([27, -21, 18]) {
      rotate([90, 0, 0]) {
        scale([0.08, 0.08, 0.05]) {
          intersection() {
            translate([0, 0, -50])
              surface("marvel_logo.png");
            translate([0, 0, 1000])
              cube(2000, center=true);
          }
        }
      }
    }
  }
}

module lid() {
  slack = 0.4;
  edge = 1;
  
  plate = 1.4;

  linear_extrude(0.2)
    offset(edge + slack - 0.3) floor_2d();
  translate([0, 0, 0.2])
    linear_extrude(plate - 0.2)
      offset(edge + slack) floor_2d();

  translate([0, 0, plate]) {
    linear_extrude(2.4) {
      difference() {
        offset(edge + slack) floor_2d();
        offset(slack) floor_2d();
      }
    }
  }
}

lid();