$fn = 350;

wall = 2;
id = 2 * (11 + 11/16) * 25.4 - 10;
height = 10.5 * 25.4;

module piece_2d(angle) {
  intersection() {
    difference() {
      circle(d=id+2*wall);
      circle(d=id);
    }
    polygon(1000 * [
      [0, 0],
      [1, 0],
      [cos(angle), sin(angle)],
    ]);
  }
}

module tag() {
  // Floor.
  linear_extrude(0.6)
    translate([(id+wall)/2, 0])
      square([40, 8], center=true);
  
  // Riser.
  linear_extrude(height)
    for (x = [-wall/2-8.5, wall/2+8.5])
      translate([(id+wall)/2 + x, 0.4])
        square([9, 1.8], center=true);
    
  // Bridge.
  for (z = [1:(height-4)/13])
    translate([(id+wall)/2, 0.4, z*13-4])
      linear_extrude(4)
        square([16 + wall, 0.8], center=true);
}

perforation_length = 35;

module perforation_2d() {
  hull()
    for (a = [-1, 1])
      scale([a, 1])
        translate([perforation_length/2, 0])
          rotate([0, 0, 45])
            square(3, center=true);
}

module perforation() {
  translate([0, 0, perforation_length/2])
    rotate([0, 90, 0])
      linear_extrude(id)
        perforation_2d();
}

module piece(angle) {
  linear_extrude(0.2000001)
    offset(-0.35)
      piece_2d(angle);
  
  difference() {
    translate([0, 0, 0.2])
      linear_extrude(height-0.2)
        piece_2d(angle);

    for (b = [0, 1, 2, 3])
      translate([0, 0, 45+(perforation_length+23)*b])
        for (a = [0:14])
          rotate([0, 0, 1.5+3*a])
            perforation();
  }
  
  tag();
  rotate([0, 0, angle])
    mirror([0, 1, 0])
      tag();
}

module print() {
  translate([-id/2, 0])
    piece(45);
}

print();