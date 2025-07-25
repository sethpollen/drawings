module imp() {
  translate([0, -3*25.4, 0])
    scale(25.4 * [1, 1, 1])
      import("originals/road_5-hex_260b.stl", 3);
}

imp();