module wall() {
  scale(25.4 * [1, 1, 1])
    import("originals/road_bridge.stl", 4);
}

module road() {
  rotate([0, 0, 90])
    scale(25.4 * [1, 1, 1])
      import("originals/road_5hex.stl", 4);
}

module walls() {
  translate([88.1, 21.6])
    wall();
  translate([89.9, -21.6])
    scale([-1, -1])
      wall();
}

module joint() {
  translate([0.3, -25.5, 0])
    rotate([0, 0, 30])
      translate([0, -1.1, 0])
        cube([25.3, 2.2, 8]);
}

module joints() {
  for (a = [-1, 1]) {
    scale([1, a]) {
      for (x = 44.51 * [0, 1, 2, 3])
        translate([x, 0, 0])
          joint();
      
      for (x = 44.51 * [1, 2, 3, 4])
        translate([x, 0, 0])
          scale([-1, 1])
            joint();
    }
  }
}

road();
color("blue") walls();
color("red") joints();