use <morph.scad>

module grip() {
  height = 94;
  
  difference() {
    translate([0, 13, 1-height]) {
      // Fields:
      //   height
      //   front circle radius
      //   back circle radius
      //   back circle offset
      morph(dupfirst([
        // Round out the back corner.
        [0,   13,  -4],
        [3,   13,  -2.5],
        [6,   13,  -2],
        [9,   13,  -1.5],
        // Swell out in back.
        [11,  13,  -1],
        [23,  14,  0],
        [41,  14,  0],
        [57,  12, -1],
        // Divot in back for thumb and finger.
        [62,  12, -2.5],
        [67,  12, -4],
        [72,  12, -5],
        [77,  12, -5],
        [79.5,12, -4],
        [82,  12, -2],
        [84.5,12,  1],
        [87,  12,  5],
        [91,  11,  14],
        [94,  11,  15],
      ])) {
        hull() {
          z = $m[0];
          forward =
            // No tilt up to 8mm. Slight tilt from there to 13mm.
            max(0, z-8)*0.2 +
            // Full 18 degree tilt after 13mm.
            max(0, z-13)*0.133333 -
            // No tilt for top 1mm, which joins to receiver
            max(0, z-93)*0.333333;
          
          // Bottom, chamfered in slightly.
          inset = max(0, 1-z);

          translate([0, forward, 0]) {
            translate([0, 16, 0]) circle(12-inset);
            translate([0, -14-$m[2], 0]) circle($m[1]-inset);
          }
        }
      }
    }
  
    // Divots for thumb and index finger.
    for (a = [-1, 1])
      scale([a, 1, 1])
        translate([-22, 52, -15])
          scale([1, 3, 1])
            sphere(12);
  }
}
