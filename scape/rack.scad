eps = 0.00001;
$fn = 50;

small_hole_diam = 33.5;
large_hole_diam = 37.7;

flange = 3.5;

hole_depth = 3.2;
floor_height = 1;
height = floor_height + hole_depth; 

module gridify(hole_diam, wall, rows, cols, gap, extra_gap) {
  for (r = [1:rows], c = [1:cols])
    translate([(c-1) * (hole_diam + gap), (r-1) * (hole_diam + gap + extra_gap)])
      children();
}

module floor(hole_diam, wall, rows, cols, gap, extra_gap) {
  difference() {
    gridify(hole_diam, wall, rows, cols, gap, extra_gap)
      offset(wall)
        circle(d=hole_diam);
    gridify(hole_diam, wall, rows, cols, gap, extra_gap)
      offset(-flange)
        circle(d=hole_diam);
  }
}

module wall(hole_diam, wall, rows, cols, gap, extra_gap) {
  difference() {
    gridify(hole_diam, wall, rows, cols, gap, extra_gap)
      offset(wall)
        circle(d=hole_diam);
    gridify(hole_diam, wall, rows, cols, gap, extra_gap)
      circle(d=hole_diam);
  }
}

module main(hole_diam, wall, rows, cols, gap, extra_gap) {
  difference() {
    union() {
      linear_extrude(0.2)
        offset(-0.3)
          floor(hole_diam, wall, rows, cols, gap, extra_gap);
      
      translate([0, 0, 0.2])
        linear_extrude(floor_height - 0.2)
          floor(hole_diam, wall, rows, cols, gap, extra_gap);
    
      translate([0, 0, floor_height])
        linear_extrude(hole_depth)
          wall(hole_diam, wall, rows, cols, gap, extra_gap);
    }
    gridify(hole_diam, wall, rows, cols, gap, extra_gap) {
      translate([0, 0, 0.6])
        cylinder(h=floor_height, d1=hole_diam-flange*2, d2=hole_diam-flange*2+2.5);
      translate([0, 0, height - 0.8])
        cylinder(h=1.01, d1=hole_diam, d2=hole_diam+2);
    }
  }
}

module basic_single_tray() {
  main(small_hole_diam, 5.6, 3, 3, 5, 4.2);
}

// `cols` should be 2 or 3.
module kyrie_tray(cols) {
  // Internal dimensions at the bottom of the tub:
  //   345.2 mm
  //   221.8 mm
  main(small_hole_diam, 5.9, cols, 4, 9.41, 1.88);
}

module large_single_tray() {
  // Bottom of tub is roughly 150mm x 289mm.
  main(large_hole_diam, 6.4, 3, 3, 9.25, 2.93);
}

large_single_tray();