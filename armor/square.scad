tile_width = 37;
tile_thickness = 1.4;
tile_spacing = 7;

ring_gauge = 3.8;

rib_width = 3.8;
rib_bottom_plate = 1.6;
rib_top_plate = 1.4;
rib_outer_wall = 13.3;

ring_id = tile_spacing + rib_outer_wall;
ring_slack = 0.8;

rib_thickness = ring_gauge + rib_bottom_plate + rib_top_plate + ring_slack*2;

module tile_2d(hole=false) {
  $fn = 32;
  roundoff = 3;
  border = 4;
  
  difference() {
    offset(roundoff)
      square(tile_width-roundoff*2, center=true);
    
    if (hole)
      offset(roundoff)
        square(tile_width-roundoff*2-border*2, center=true);
  }
}

module ribs_2d() {
  intersection() {
    tile_2d();
    for (r = [-45, 45])
      rotate([0, 0, r])
        square([rib_width, 100], center=true);
  }
}

module ring(offs=0, extend=0) {
  translate(
    [0, 0, ring_gauge/2 + tile_thickness + ring_slack + rib_bottom_plate] +
    (tile_width/2 + tile_spacing/2) * [1, 1, 0]
  )
    rotate_extrude($fn=40)
      hull()
        for (x = [0, extend])
          translate([ring_id/2 + ring_gauge/2 + x, 0])
            offset(offs)
              intersection_for(r = [0, 45])
                rotate([0, 0, r])
                  square(ring_gauge, center=true);
}

module tile() {
  linear_extrude(0.4)
    tile_2d(true);
  translate([0, 0, 0.4])
    linear_extrude(tile_thickness - 0.4)
      tile_2d();
  
  difference() {
    translate([0, 0, tile_thickness]) {
      union() {
        bevel = 1.8;

        linear_extrude(rib_thickness-bevel)
          ribs_2d();

        translate([0, 0, rib_thickness-bevel]) {
          intersection() {
            linear_extrude(bevel)
              ribs_2d();
            linear_extrude(bevel, scale=0.94)
              tile_2d();
          }
        }
      }
    }
    
    for (a = 90*[0, 1, 2, 3])
      rotate([0, 0, a])
        ring(offs=ring_slack-0.001, extend=ring_gauge*1.5);
    
    // Cut out some material from the intersection point of the ribs.
    cut = 10.4;
    leaving = 3.2;
    rotate([0, 0, 45]) {
      translate([0, 0, cut/2 + tile_thickness + leaving]) {
        hull() {
          cube(cut, center=true);
          translate([0, 0, 20])
            cube(cut+20, center=true);
        }
      }
    }
  }
}

module demo() {
  for (x = [0, 1], y = [0, 1])
    translate((tile_width + tile_spacing)*[x, y])
      tile();
  for (x = [-1, 0, 1], y = [-1, 0, 1])
    if (x*y == 0)
      translate((tile_width + tile_spacing)*[x, y])
        ring();
}

demo();