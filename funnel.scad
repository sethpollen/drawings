mouth_id = 40;
tube_id = 5;
tube_length = 11;

$fn = 120;

module piece(offs, hadj) {
  cylinder(h=mouth_id/2+hadj, d1=mouth_id+offs*2, d2=tube_id+offs*2);
  translate([0, 0, mouth_id/2])
    cylinder(h=tube_length+hadj, d=tube_id+offs*2);
}

difference() {
  union() {
    piece(0.8, 0);
    cylinder(h=0.4, d=mouth_id+4);
  }
  translate([0, 0, -0.001])
    piece(0, 0.002);

  translate([0, 0, tube_length + mouth_id/2 - tube_id*0.26])
    rotate([30, 0, 0])
      translate([0, 0, 15])
        cube(30, center=true);
}