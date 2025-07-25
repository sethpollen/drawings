include <common.scad>

module forty() {
  difference() {
    union() {
      // Main piece.
      chamfered_disk(5, 20);
      cylinder(39, 5, 5);
      translate([0, 0, 36])
        chamfered_disk(4, 12);

      // Bottom fillet.
      translate([0, 0, 5-eps])
        linear_extrude(12, scale=0)
          circle(12);
          
      // Top fillet.
      translate([0, 0, 37.1+eps])
        scale([1, 1, -1])
          linear_extrude(12, scale=0)
            circle(12);
    }
    
    // Engraving.
    translate([-6.2, -7, 36+eps])
      linear_extrude(4)
        text("4", size=15);
  }
}

module twenty() {
  difference() {
    union() {
      // Main piece.
      chamfered_disk(5, 10);
      cylinder(21, 3, 3);
      translate([0, 0, 18])
        chamfered_disk(4, 6);

      // Bottom fillet.
      translate([0, 0, 5-eps])
        linear_extrude(6, scale=0)
          circle(6);
          
      // Top fillet.
      translate([0, 0, 19.1+eps])
        scale([1, 1, -1])
          linear_extrude(6, scale=0)
            circle(6);
    }
    
    // Engraving.
    translate([-2.4, -2.7, 18+eps])
      linear_extrude(4)
        text("2", size=6);
  }
}

printout = 2;

if (printout == 1) twenty();
if (printout == 2) forty();