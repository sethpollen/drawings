eps = 0.001;
layer = 0.2;

width = 26; 
height = 6.6;

module exterior_2d() {
  difference() {
    square([width, width], center=true);
    
    // Chamfer corners.
    for (a = [-1, 1], b = [-1, 1])
      scale([a, b])
        translate([width/2, width/2])
          rotate([0, 0, 45])
            square(4, center=true);
  }
}

module exterior() {
  linear_extrude(layer)
    offset(-0.2)
      exterior_2d();
  translate([0, 0, layer])
    linear_extrude(height - layer)
      exterior_2d();
}

module ladder() {
  stair_width = 12;
  
  difference() {
    exterior();
    
    translate([0, 0, height/2]) {
      for (a = [0, 180]) {
        rotate([0, a, 0]) {
          for (s = [0, 1])
            translate([1 + 2*s, 0, 2*s - 2*eps])
              linear_extrude(2 + 2*eps)
                square([width * 0.4, stair_width], center=true);
          
          translate([3, 0, a == 0 ? 2.9 : 2.7])
            linear_extrude(2 + 2*eps, scale=1.5)
              square([width * 0.4, stair_width], center=true);
        }
      }
    }
    
    for (a = [0:3])
      rotate([0, 0, a*90])
        for (x = 4 * [-1, 1])
          translate([x, width/2 + eps, 3.4])
            rotate([90, 0, 0])
              linear_extrude(3.6, scale=0.7)
                arrow_2d();
  }
}

module arrow_2d() {
  scale([1.2, 1.2]) {
    hull() {
      translate([0, 2])
        square(eps, center=true);
      square([4, eps], center=true);
    }
    translate([-0.9, -2])
      square([1.8, 2]);
  }
}

ladder();