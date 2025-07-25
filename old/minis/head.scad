include <common.scad>

// Studs are 1.6mm high and 2.5mm across.
stud_width = 2.5;

// Studs are spaced 1.7mm in from the edges of an 18x18mm
// square.
stud_inset = 1.7;

// 45 degree beveled top, 0.5mm high.
module stud_top(dims) {
  hull() {
    for (a = [-1, 1], b = [-1, 1]) {
      translate([
        a*(dims.x/2-0.5), b*(dims.y/2-0.5), 0
      ]) {
        pyramid();
      }
    }
  }
}

module stud_piece(dims, column_height) {
  assert(dims.x >= 1);
  assert(dims.y >= 1);
  
  // Rectangular column.
  translate([0, 0, -eps])
    linear_extrude(column_height)
      square(dims, center=true);
  
  // Beveled top.
  translate([0, 0, column_height-2*eps])
    stud_top(dims);
  
  // Beveled bottom, in case any material under the stud
  // is etched away (by the face mask, for instance).
  scale([1, 1, -1])
    stud_top(dims);
}

NO_STUD = 0;
SMALL_STUD = 1;
SMALL_SHORT_STUD = 2;
LARGE_STUD = 3;
LARGE_SHORT_STUD = 4;

module stud(type=NO_STUD) {
  if (type == NO_STUD) {
    // Nothing.
    
  } else if (type == SMALL_STUD ||
             type == SMALL_SHORT_STUD) {
    c = type == SMALL_STUD ? 1.1 : 0;
    stud_piece([stud_width, stud_width], c);
    
  } else if (type == LARGE_STUD ||
             type == LARGE_SHORT_STUD) {
    c = type == LARGE_STUD ? 1.1 : 0;

    // Build an L-shaped stud out of two elongated pieces.
    translate([0, -stud_width/2, 0])
      stud_piece([stud_width, stud_width*2], c);
    translate([-stud_width/2, 0, 0])
      stud_piece([stud_width*2, stud_width], c);
    
  } else {
    assert(false, "bad stud type");
  }
}

module four_studs() {
  displacement = (18/2)-(stud_width/2)-stud_inset;  
  for (a = [0:3])
    rotate([0, 0, a*90])
      translate([displacement, displacement, 0])
        children();
}

// A stackable box, 18x18mm, with optional studs and holes.
module stackable_box(
  height, stud_type=NO_STUD, hole_type=NO_STUD
) {
  translate([0, 0, height - eps]) {
    four_studs()
      stud(stud_type);
  }

  difference() {
    chamfered_box([18, 18, height]);
    
    if (hole_type != NO_STUD) {
      four_studs() {
        // This check is required because minkowski() returns
        // a nonempty result if just one of its arguments is
        // empty.
        minkowski() {
          stud(hole_type);
          sphere(r=0.5, $fn=10);
        }
      }
    }
  }
}

// A head, which is intended to have 2 chips stacked on top.
module head(face_raster, tall=false) {
  difference() {
    // A 10mm head plus two 3.5mm chips comes to 17mm,
    // which is slightly less than the 18mm width. That's
    // by design. It looks better not to have such tall 
    // heads, perhaps because the studs on top give the
    // illusion of added height.
    chamfered_box([18, 18, tall ? 12 : 10]);
    
    // Bring the mask out a bit extra to avoid having it 
    // intersect the studs at all.
    translate([0, -9, 0])
      face(face_raster);
    
    // A socket for gluing to a body.
    locking_socket_bottom();
  }
  
  // Add the studs separately, so they are not gouged by
  // the face engraving.
  translate([0, 0, (tall ? 12 : 10) - eps]) {
    four_studs()
      stud(SMALL_STUD);
  }
}

// 'raster' is an array of 5 rows, where each row has 8
// elements. Each element should be in [0, 1]. A '1' means the
// given position will be fully engraved on the face.
// Returns a mask which should be subtracted from the head.
// The Z axis will coincide with the centerline of the 
// mask's front.
module face(raster) {
  // Below we use a unit of 1 to represent one pixel on
  // the face. Scale up to an 18mm face, 8 pixels wide.
  scale([2.25, 2.25, 2.25]) {
    translate([-4, -eps, -eps]) {
      difference() {
        // Begin with a filled-in face plate.
        translate([-eps, -eps, -eps])
          cube([8+2*eps, 0.9+2*eps, 5+2*eps]);
        
        // Subtract the material which needs to remain on the
        // head. Leave some support under each shelf.
        for (r = [0:4])
          for (c = [0:7])
            translate([c-eps, raster[r][c]-eps, 4-r-eps])
              rotate([90, 0, 90])
                translate([0, 0, -2*eps])
                  linear_extrude(1+4*eps)
                    polygon([
                      [   -2*eps,     -2*eps],
                      [0.9+2*eps, -0.5-2*eps],
                      [0.9+2*eps,    1+2*eps],
                      [   -2*eps,    1+2*eps],
                    ]);
      }
    }
  }
}

module creeper_head() {
  head([
    [0, 1, 1, 0, 0, 1, 1, 0],
    [0, 1, 1, 0, 0, 1, 1, 0],
    [0, 0, 0, 1, 1, 0, 0, 0],
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
  ]);
}

module zombie_head() {
  head([
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0],
    [0.0, 0.0, 0.0, 0.8, 0.8, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.2, 0.2, 0.2, 0.2, 0.0, 0.0],
    [0.0, 0.0, 0.2, 0.2, 0.2, 0.2, 0.0, 0.0],
  ]);
}

module skeleton_head() {
  head([
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 0, 0, 1, 1, 0],
    [0, 0, 0, 1, 1, 0, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
  ]);
}

module spider_head() {
  head([
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
  ]);
}

module hero_head() {
  head([
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0.7, 1, 0, 0, 1, 0.7, 0],
    [0, 0, 0, 0.8, 0.8, 0, 0, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
    [0, 0, 1, 1, 1, 1, 0, 0],
  ]);
}

module enderman_head() {
  head([
    [0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 0, 0, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
  ]);
}

module evoker_head() {
  head([
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0.7, 1, 0, 0, 1, 0.7, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0.4, 0, 0, 0.4, 0, 0],
    [0, 0, 0.4, 0, 0, 0.4, 0, 0],
  ], tall=true);
  
  // Nose.
  translate([0, -9.5, 0])
    chamfered_box([4.5, 4, 6]);
  
  // Eyebrows.
  difference() {
    translate([-8.5, -9+eps, 9])
      rotate([90, 0, 0])
        rotate([0, 90, 0])
          linear_extrude(17)
            polygon([
              [0, 0],
              [-1.3, 1],
              [-1, 2.5],
              [1, 3],
            ]);
    
    // Cut out a space between the two eyebrows.
    cube([4.5, 100, 100], center=true);
  }
}

// Heavy armor cannot stack on a heavy weapon.
module light_weapon() {
  stackable_box(3.5, SMALL_STUD, SMALL_STUD);
}
module heavy_weapon() {
  stackable_box(3.5, LARGE_STUD, SMALL_STUD);
}
module light_armor() {
  stackable_box(3.5, SMALL_SHORT_STUD, LARGE_STUD);
}
module heavy_armor() {
  stackable_box(3.5, LARGE_SHORT_STUD, SMALL_STUD);
}

// Status effect chips go between the weapon and head.
// So their top and bottom match the head's top.
module status_effect() {
  stackable_box(3.5, SMALL_STUD, SMALL_STUD);
}
