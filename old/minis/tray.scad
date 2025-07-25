include <common.scad>

// Just tall enough to fit an enderman with no chips on top.
height = 64;

module tray() {
  difference() {
    union() {
      // Exterior.
      hull()
        for (a = [-1, 1], b = [-1, 1])
          translate([68*a, 68*b, 0])
            chamfered_disk(height, 26);
        
      // Crenellations.
      for (a = [0, 90, 180, 270]) {
        rotate([0, 0, a]) {
          translate([89, 0, height-10]) {
            intersection() {
              cube([21.8, 100, 100], center=true);
              rotate([0, 45, 0]) {
                chamfered_box([7, 40, 30], chamfer=1.1);
              }
            }
            translate([8.75, 0, 6])
              chamfered_box([6.5, 40, 12], chamfer=1.1);
          }
        }
      }
    }

    // Main interior volume.
    hull()
      for (a = [-1, 1], b = [-1, 1])
        translate([67*a, 67*b, 49])
          cylinder(80, r=23, center=true);
      
    // Chamfer on inner top edge.
    hull()
      for (a = [-1, 1], b = [-1, 1])
        translate([67*a, 67*b, height-1.1])
          chamfered_disk(100, 24);

    // Sockets.
    translate([-67.5, -67.5, 3]) {
      repeatx(4, 45) {
        repeaty(4, 45) {
          chamfered_disk(10, 20.5);
          translate([0, 0, 5])
            chamfered_disk(10, 21.5);
        }
      }
    }
  }
}

module lid() {
  hull()
    for (a = [-1, 1], b = [-1, 1])
      translate([68*a, 68*b, 0])
        chamfered_disk(8, 26);
}

// 1 for tray; 2 for lid; 3 for preview of both.
resin = 3;

if (resin == 1) {
  tray();
}
if (resin == 2) {
  lid();
}
if (resin == 3) {
  tray();
  translate([0, 0, height]) lid();
}
