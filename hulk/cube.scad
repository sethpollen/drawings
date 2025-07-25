module octahedron(s, flat=true) {
  translate([0, 0, flat ? s*0.4082 : 0])
    rotate([flat ? 109.47122/2 : 0, 0, 0])
      for (a = [-1, 1])
        scale([1, 1, a])
          linear_extrude(s*sqrt(2)/2, scale=0)
            square(s, center=true);
}

module small_cube() {
  cube_side = 8;
  intersection() {
    linear_extrude(cube_side)
      square(cube_side, center=true);
    translate([0, 0, cube_side/2])
      rotate([0, 0, 45])
        octahedron(cube_side*1.94, false);
  }
}

module large_cube() {
  cube_side = 16;
  chamfer = 0.6;
  
  translate([0, 0, cube_side/2]) {
    difference() {
      hull()
        for (a = [-1, 1], b = [-1, 1], c = [-1, 1])
          translate((cube_side/2 - chamfer) * [a, b, c])
            rotate([0, 0, 45])
              octahedron(chamfer*sqrt(2), flat=false);
      
      coffer = cube_side - 4.5;
      for (r = [
        [0, 0, 0],
        [0, 90, 0],
        [90, 90, 0],
        [180, 90, 0],
        [270, 90, 0],
        [0, 180, 0]
      ])
        rotate(r)
          translate([0, 0, -cube_side/2-0.001])
            linear_extrude(coffer*0.35, scale=0.35)
              square(coffer, center=true);
    }
  }
}

module print() {
  linear_extrude(0.2)
    offset(-0.25)
      projection(cut=true)
        translate([0, 0, -0.1])
          children();
  
  difference() {
    children();
    translate([0, 0, -0.001])
      linear_extrude(0.2)
        square(1000, center=true);
  }
}

print() large_cube();