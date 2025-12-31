side = 40;
spacing = 5.4;
plate = 2;

ring_gauge = 3.4;
ring_id = 2*spacing + 13;

ring_slack_z = 1.3;

tile_height = plate*2 + ring_gauge + ring_slack_z*2;

rosette_spacing = [
  spacing/tan(30) + side,
  2*spacing*sin(30) + 2*spacing + side*sqrt(3)
];

module tile_2d() {
  $fn = 20;
  roundoff = 1.5;
  
  offset(roundoff)
  offset(-roundoff)
  translate([0, -spacing*sin(30) - spacing/2])
  polygon(side*[
    [-1/2, -sqrt(3)/2],
    [1/2, -sqrt(3)/2],
    [0, 0],
  ]);
}

module ring_cavity() {
  ring(offs=ring_slack_z, ext=spacing);
}

module tile_exterior() {
  $fn = 20;
  bevel = plate*0.6;
  
  hull() {
    translate([0, 0, bevel])
    linear_extrude(tile_height-bevel*2)
    tile_2d();
    
    linear_extrude(tile_height)
    offset(0.8)
    offset(-bevel-0.8)
    tile_2d();
  }
}

module tile() {
  difference() {
    tile_exterior();
    
    ring_cavity();

    for (a = [-60, -120])
    rotate([0, 0, a])
    translate([rosette_spacing.x, 0])
    ring_cavity();
  }
}

module rosette_tiles() {
  for (a = 60 * [0, 1, 2, 3, 4, 5])
  rotate([0, 0, a])
  tile();
}

module ring(offs=0, ext=0) {
  $fn = 36;

  translate([0, 0, tile_height/2])
  rotate_extrude()
  translate([ring_id/2 + ring_gauge/2, 0])
  offset(offs)
  hull()
  for (x = [0, ext])
  translate([x, 0])
  intersection_for(r = [0, 45])
  rotate([0, 0, r])
  square(ring_gauge, center=true);
}

module rosette_rings() {
  ring();

  for (a = 60 * [0, 1, 2, 3, 4, 5])
  rotate([0, 0, a])
  translate([rosette_spacing.x, 0])
  ring();
}

module set() {
  children();
  
  for (a = [-1, 1])
  scale([a, 1])
  translate(rosette_spacing/2)
  children();
}


set() rosette_tiles();
color("red") set() rosette_rings();