module octagon_2d(gauge) {
  intersection_for(a = [0, 45])
    rotate([0, 0, a])
      square(gauge, center=true);
}

module torus(od, aspect_ratio, gap=true) {
  gauge = od / (aspect_ratio + 2);
  gap_angle = gap ? 7 : 0;
  
  rotate([0, 0, gap_angle])
    rotate_extrude($fn=24, angle=360-2*gap_angle)
      translate([od/2-gauge/2, 0])
        octagon_2d(gauge);
  
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


module ring() {
  torus(30, 6.5, false);
}

ring();
