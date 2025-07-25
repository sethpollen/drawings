module imp() {
  translate([0, 0, 4.8265])
    scale(25.4 * [1, 1, 1])
      rotate([-90, 0, 0])
        import("originals/glacier_1hex.stl", 5);
}

module bottom_2d() {
  projection(cut=true)
    translate([0, 0, -0.1])
      imp();
}

module lava() {
  difference() {
    imp();
    
    translate([-500, -500, -1000 + 0.4])
      cube(1000);
  }

  linear_extrude(0.2)
    offset(-0.5)
      bottom_2d();

  translate([0, 0, 0.2])
    linear_extrude(0.2)
      offset(-0.05)
        bottom_2d();
}

// I verified that hexes are spaced 1.75" on center.
function lava2_spacing() = 1.75 * 25.4;

module lava2() {
  difference() {
    union() {
      for (y = lava2_spacing() * 0.5 * [-1, 1])
        translate([0, y])
          lava();
      
      color("red")
        translate([0, 0, 0.6])
          linear_extrude(4.22)
            square([25, 4.3], center=true);
    }
    
    translate([0, 0, 2.55])
      linear_extrude(4.22)
        square([21.7, 10], center=true);
  }
}

lava2();