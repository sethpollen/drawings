eps = 0.001;
thickness = 1.9;
width = 8;

module ring_blank_2d(id) {
  bevel = 0.18;
  
  for (a = [-1, 1]) {
    scale([1, a]) {
      hull() {
        translate([id/2, 0])
          square([thickness, width/2-1]);
        translate([id/2+bevel, 0])
          square([thickness-2*bevel, width/2]);
      }
    }
  }
}

module ring_blank(id) {
  rotate_extrude($fn=90)
    ring_blank_2d(id);
}

module waves(id) {
  $fn = 40;
  
  breadth = id*0.3;
  depth = 2 + id*0.15;
  count = 7;
  
  for (a = [1:count])
    rotate([0, 0, a*360/count])
      translate([0, 0, width/2+depth*0.1])
        scale([breadth, 1, depth])
          rotate([90, 0, 0])
            cylinder(d1=0, d2=1, h=id/2+thickness+eps);
}

module wave_ring(id) {
  difference() {
    ring_blank(id);
    waves(id);
  }
}

module wave_ring_set() {
  wave_ring(10);
  wave_ring(16);
  
  translate([22, 0, 0]) {
    wave_ring(12);
    wave_ring(18);
  }
  
  translate([0, 23, 0]) {
    wave_ring(14);
    wave_ring(20);
  }
}

wave_ring_set();