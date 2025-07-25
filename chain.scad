gauge = 2;
long_straight = 6;
short_straight = 3.4;

module octahedron(major_radius=1) {
  // Top and bottom halves.
  for (a = [-1, 1])
    scale([1, 1, a])
      // Extrude a square into a pyramid.
      linear_extrude(major_radius, scale=0)
        rotate([0, 0, 45])
          square(sqrt(2)*major_radius, center=true);
}

module chamfered_cube(dims, chamfer=1) {
  assert(dims.x >= 2*chamfer);
  assert(dims.y >= 2*chamfer);
  assert(dims.z >= 2*chamfer);

  hull()
    for (a = [0, 1], b = [0, 1], c = [0, 1])
        translate([
          (dims.x - 2*chamfer) * a + chamfer,
          (dims.y - 2*chamfer) * b + chamfer,
          (dims.z - 2*chamfer) * c + chamfer
        ])
          octahedron(chamfer);
}

module raw_quarter_link() {
  $fn = 20;
  
  translate([0, long_straight/4, 0])
    rotate([0, 45, 0])
      cube([gauge, long_straight/2, gauge], center=true);
      
  translate([-short_straight/4 - gauge/sqrt(2), long_straight/2 + gauge/sqrt(2), 0])
    rotate([0, 45, 90])
      cube([gauge, short_straight/2, gauge], center=true);

  translate([-gauge/sqrt(2), long_straight/2, 0])
    rotate_extrude(angle=90)
      translate([gauge/sqrt(2), 0, 0])
        rotate([0, 0, 45])
          square(gauge, center=true);
}

// Sand off rough edges.
module quarter_link() {
  difference() {
    raw_quarter_link();
  
    // Flatten inner surfaces.
    nip = 0.4;
    translate([-short_straight - gauge/sqrt(2) + nip, -long_straight/2 + nip, -gauge/2])
      chamfered_cube([short_straight, long_straight, gauge], nip);
  }
}

module link() {
  translate([-gauge/2 - short_straight/2/sqrt(2), 0, 0])
    rotate([0, -45, 0])
      translate([short_straight/2 + gauge/sqrt(2), 0, 0])
        for (a = [-1, 1], b = [-1, 1])
          scale([a, b, 1])
            translate([short_straight/2 + gauge/sqrt(2), 0, 0])
              quarter_link();
}

// Recommend printing with 0.1mm layers.
module chain(links) {
  for (i = [1:links])
    translate([0, i*(long_straight), 0])
      scale([2*(i%2)-1, 1, 1])
        link();
}

chain(5);