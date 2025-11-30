od = 30;
aspect_ratio = 6.5;
gauge = od / (aspect_ratio + 2);

module octagon_2d(gauge) {
  intersection_for(a = [0, 45])
    rotate([0, 0, a])
      square(gauge, center=true);
}

module torus(od, gauge, gap_angle) {
  rotate([0, 0, gap_angle])
    rotate_extrude($fn=24, angle=360-2*gap_angle)
      translate([od/2-gauge/2, 0])
        octagon_2d(gauge);
}

module ring(gap=true) {
  gap_angle = gap ? 7 : 0;
  
  torus(od, gauge, gap_angle);
  
  // Round tips.
  if (gap)
    for (a = [-1, 1])
      scale([1, a, 1])
        hull()
          for (packet = [[1.2, 0.6], [gap_angle, 1]])
            rotate([0, 0, -packet[0]])
              translate([od/2-gauge/2, 0])
                rotate([90, 0, 0])
                  linear_extrude(0.0001)
                    scale(packet[1])
                      octagon_2d(gauge);
}

module border_link() {
  my_od = gauge*3.5;
  length = od*0.83;
  
  for (a = [-1, 1]) {
    scale([a, 1, 1]) {
      translate([length/2-my_od/2, 0, 0]) {
        intersection() {
          torus(my_od, gauge, 0);
          translate([(my_od+1)/2, 0, 0])
            cube(my_od+1, center=true);
        }
      }
      
      for (b = [-1, 1])
        translate([0, b*(my_od/2-gauge/2), 0])
          rotate([0, 90, 0])
            linear_extrude(length/2-my_od/2)
              octagon_2d(gauge);
    }
  }
}

border_link();