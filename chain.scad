gauge = 8;
gap_width = 9.4;
gap_length = gap_width * 2;

module half_link() {
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
      
      interface();
    }
    
    scale([-1, -1, 1])
    interface(offs=0.15);
  }
}

module interface(offs=0) {
  $fn = 8;

  d = gauge-1.9;
  h = gauge*0.93;
  
  translate([-gap_length/2 - gap_width/2 - gauge/2, 0])
  rotate([90, 0, 0])
  intersection() {
    hull() {
      translate([0, 0, -0.001])
      rotate([0, 0, 360/16])
      cylinder(d=d+2*offs, h=0.001);
      
      translate([1, 0, h])
      rotate([0, 0, 360/16])
      cylinder(d=1+2*offs, h=0.001);
    }
    
    // Truncate the pyramid.
    if(offs == 0)
    translate([0, 0, h-50-0.6])
    cube(100, center=true);
  }
}

module print() {
  intersection() {
    translate([0, 0, gauge*1.42])
    rotate([-90, 0, 0])
    half_link();
    
    translate([0, 0, 50])
    cube(100, center=true);
  }
}

print();