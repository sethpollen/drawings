gauge = 8;
gap_width = 9.4;
gap_length = gap_width * 2;

module half_link(male=true) {
  $fn = 40;

  difference() {
    union() {
      for (a = [-1, 1])
      scale([a, 1, 1])
      translate([gap_length/2, 0])
      rotate_extrude(angle=90)
      translate([gauge/2 + gap_width/2, 0])
      rotate([0, 0, 360/16])
      circle($fn=8, d=gauge);
      
      translate([-gap_length/2, gap_width/2 + gauge/2])
      rotate([0, 90])
      translate([0, 0, -0.001])
      rotate([0, 0, 360/16])
      cylinder($fn=8, d=gauge, h=gap_length+0.002);
      
      if (male)
      for (a = [-1, 1])
      scale([a, 1, 1])
      interface();
    }
    
    if(!male)
    for (a = [-1, 1])
    scale([a, -1, 1])
    interface(cav=true);
  }
}

module interface(cav=false) {
  $fn = 8;

  d = gauge-1.9;
  h = gauge*0.93;
  tilt = 0.9;
  runnel_tilt = 5;

  translate([-gap_length/2 - gap_width/2 - gauge/2, 0])
  rotate([90, 0, 0])
  intersection() {
    union() {
      scale([1, 1, 0] * (cav ? 1.06 : 1) + [0, 0, 1])
      translate([tilt, 0, -0.001])
      linear_extrude(h, scale=(cav ? 0.15 : 0.1))
      translate([-tilt, 0])
      rotate([0, 0, 360/16])
      circle(d=d);
      
      // Runnels.
      if(cav)
      translate([runnel_tilt, 0])
      linear_extrude(1.2, scale=0.96)
      translate([-runnel_tilt, 0])
      circle(d=d, $fn=20);
    }
    
    // Truncate the pyramid.
    if(!cav)
    translate([0, 0, h-50-0.6])
    cube(100, center=true);
  }
}

module printable_half_link(male=true) {
  intersection() {
    translate([0, 0, gauge*1.42])
    rotate([-90, 0, 0])
    half_link(male);
    
    translate([0, 0, 50])
    cube(100, center=true);
  }
}

module interface_preview() {
  interface();

  color("blue")
  translate([1, 0])
  interface(true);
}

module print() {
  printable_half_link(false);
  translate([0, gauge+0.6])
  printable_half_link(true);
}

print();