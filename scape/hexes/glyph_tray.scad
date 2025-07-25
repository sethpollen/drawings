$fn = 30;

height = 46;
interior_r = 22 + 1.1;
exterior_r = interior_r + 1;

module tile_profile_2d() {
  circle(r = interior_r, $fn = 6);
}

module exterior_2d() {
  difference() {
    circle(r = exterior_r, $fn = 6);
    
    rotate([0, 0, -30])
      translate([0, 50])
        square([27.5, 100], center=true);
    circle(d=27.5);
  }
}

module shell_2d() {
  offset(0.4) {
    difference() {
      exterior_2d();
      tile_profile_2d();
    }
  }
}

module floor_2d() {
  offset(0.4)
    offset(1.3)
      exterior_2d();
}

module walls_2d() {
  offset(0.4) {
    difference() {
      offset(1.3) exterior_2d();
      tile_profile_2d();
    }
  }
}

module main() {
  translate([0, 0, -0.2])
    linear_extrude(1.8)
      offset(-0.3)
        floor_2d();
  linear_extrude(1.8)
    floor_2d();
  linear_extrude(height)
    walls_2d();
  for (a = [1:10])
    translate([0, 0, height + (a-1)*0.2])
      linear_extrude(0.200001)
        offset(-a*0.07)
          walls_2d();
}

main();