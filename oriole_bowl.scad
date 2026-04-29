$fn = 100;
height = 36;
od = 84.5;
wall = 4.5;

module exterior_2d() {
  intersection() {
    flat_bottom = 5;
    
    scale([od/2, height + flat_bottom])
    circle(r=1, $fn=90);

    scale([1, -1])
    square([od/2, height]);
  }
}

module lip_2d() {
  translate([0, -3])
  scale([1, -1])
  square([od/2 + 7.7, 5]);
}

module profile_2d() {
  offset(1.8)
  offset(-1.8)
  difference() {
    union() {
      exterior_2d();
      lip_2d();
    }
    
    hull()
    for (a = [-1, 1], b = [-1, 1])
    scale([a, b])
    offset(-wall)
    exterior_2d();
  }
  
  // Undo roundoff at the bottom.
  translate([0, -height])
  square(wall);
}

module piece() {
  difference() {
    rotate_extrude()
    profile_2d();

    cutouts = 8;    
    cutout_r = 20;
    for (i = [1:cutouts])
    rotate([0, 0, i*360/cutouts])
    translate([od/2 + cutout_r + 0.4, 0, -20])
    cylinder(h=20, r=cutout_r);
  }
}

piece();