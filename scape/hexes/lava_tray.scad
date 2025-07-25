use <lava.scad>

$fn = 30;

exterior_r = 29.6;

// If true, make a rack for a single column of "double" ice tiles. Otherwise,
// make a rack for three columns of single lava/water tiles.
double = true;

function height() = double ? 93 : 85;

module maybe_triple() {
  if (double) {
    // Don't triple anything.
    children();
  } else {
    for (a = [0:2])
      rotate([0, 0, a*120])
        translate([sin(30)*exterior_r, cos(30)*exterior_r, 0])
          children();
  }
}

module maybe_double() {
  // This does nothing if `double` is false.
  for (a = (double ? [-1, 1] : [0]))
    translate([0, lava2_spacing()*a/2])
      children();
}

module tile_profile_2d() {
  offset(1.5)
    maybe_double()
      projection()
        scale(25.4 * [1, 1, 1])
          rotate([-90, 0, 0])
            import("originals/glacier_1hex.stl", 5);
}

module exterior_2d() {
  difference() {
    maybe_double()
      circle(r = exterior_r, $fn = 6);
    
    if (double) {
      hull()
        maybe_double()
          for (x = [10, 100])
            translate([x, 0])
              circle(d=25);
    } else {
      rotate([0, 0, -30])
        translate([0, 50])
          square([29.5, 100], center=true);
      circle(d=29.5);
    }
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

module triple_exterior_2d() {
  maybe_triple() exterior_2d();
}

module triple_tile_profile_2d() {
  maybe_triple() tile_profile_2d();
}

module floor_2d() {
  offset(0.4)
    offset(1.3)
      triple_exterior_2d();
}

module walls_2d() {
  offset(0.4) {
    difference() {
      offset(1.3) triple_exterior_2d();
      triple_tile_profile_2d();
    }
  }
}

module main() {
  translate([0, 0, -0.2])
    linear_extrude(2)
      offset(-0.3)
        floor_2d();
  linear_extrude(2)
    floor_2d();
  linear_extrude(height())
    walls_2d();
  for (a = [1:10])
    translate([0, 0, height() + (a-1)*0.2])
      linear_extrude(0.200001)
        offset(-a*0.07)
          walls_2d();
}

main();