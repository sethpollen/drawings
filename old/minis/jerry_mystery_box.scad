include <common.scad>

side = 100;
engrave = 10;

module question_mark() {
  translate([0, -3, 0]) {
    polygon([
      [-7, -10],
      [-7, 0],
      [0, 8],
      [10, 8],
      [10, 18],
      [-10, 18],
      [-12, 16],
      [-12, 10],
      [-22, 10],
      [-22, 22],
      [-14, 30],
      [15, 30],
      [22, 22],
      [22, 6],
      [14, -2],
      [9, -2],
      [7, -4],
      [7, -10],
    ]);
    polygon([
      [-7, -26],
      [-7, -16],
      [7, -16],
      [7, -26],
    ]);
  }

  // Studs around question mark.
  for (a = [-1, 1], b = [-1, 1])
    scale([a, b, 1])
      translate([37, 37, 0])
        circle(5);
}

module big_j() {
  offset(0.2)
    text("J", 70, "Bookman");
}

eps = 0.01;

scale(0.7 * [1, 1, 1]) {
  difference() {
    chamfered_box([side, side, 15], chamfer=5);

    translate([0, 0, 5]) {
      for (a = [-1, 1]) {
        scale(1.1*[a, 1, 1]) {
          // Hair.
          translate([-eps, 20-eps, 0]) cube([40, 20, 20]);
          translate([30, 10, 0]) cube([10, 10, 20]);
          // Eyes.
          translate([10, -10, 0]) cube([20, 10, 20]);
          // Nose.
          translate([-eps, -20, 0]) cube([10, 10, 20]);
          // Mouth.
          translate([10, -30, 0]) cube([10, 10, 20]);
          translate([-eps, -40, 0]) cube([20, 10+eps, 20]);
        }
      }
    }
  }
}