eps = 0.0001;

height = 2;
diamx = 16;
diamy = 29;
chamferx = 1;
chamfery = 1;

module profile_2d(diam) {
  translate([diam/2 - chamferx, height - chamfery])
    scale([chamferx, chamfery])
      circle(r=1, $fn=16);
  square([diam/2, height - chamfery]);
  square([diam/2 - chamferx, height]);
}

module base() {
  small_diam = min(diamx, diamy);
  
  hull()
    for(a = [-1, 1], b = [-1, 1])
      scale([a, b, 1])
        translate([(diamx - small_diam)/2, (diamy - small_diam)/2])
          rotate_extrude(angle=90, $fn=64)
            profile_2d(small_diam);
}

module print() {
  difference() {
    base();
    
    translate([0, 0, -eps]) {
      linear_extrude(0.2) {
        difference() {
          square(100, center=true);
          offset(-0.3)
            projection(cut=true)
              base();
        }
      }
    }
  }
}

print();