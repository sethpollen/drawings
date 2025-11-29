width = 50;
height = 90;
depth = 7;

top_inset = depth*0.5;
hole_inset = 2.2;
hole_id = 5.5;

module base_2d() {
  roundoff = 1.5;
  $fn = 16;
  
  offset(roundoff)
    offset(-roundoff)
      square([width, height], center=true);
}

module blank() {
  difference() {
    
    hull()
      // Elements are [height, inset].
      for (a = [[0, 0], [depth*0.3, 0], [depth, top_inset]])
        translate([0, 0, a[0]])
          linear_extrude(0.00001)
            offset(-a[1])
              base_2d();
    
    depress = 3;
    translate([0, 0, depth+0.001])
      scale([1, 1, -1])
        linear_extrude(depress, scale=0, twist=1)
          offset(-top_inset-6)
            base_2d();
  }
}

module hole() {
  flare_x = 2;
  flare_y = (depth-1.3)/2;
  
  difference() {
    translate([0, 0, -1])
      cylinder(d=hole_id+10, h=depth+2);
  
    translate([0, 0, depth/2]) {
      rotate_extrude() {
        hull() {
          for (a = [-1, 1])
            scale([1, a])
              translate([flare_x+hole_id/2, flare_y-depth/2])
                scale([flare_x, flare_y])
                  circle($fn=20, r=1);
          
          translate([20, 0])
            square([0.001, depth], center=true);
        }
      }
    }
  }
}

module holes() {
  for (a = [-1, 1], b = [-1, 1]) {
    scale([a, b, 1]) {
      // Top and bottom holes.
      translate([width/2 -hole_id/2 -hole_inset*2.5, height/2-hole_id/2-hole_inset, 0])
        hole();
      
      // Side holes.
      translate([width/2 -hole_id/2 -hole_inset, 0, 0])
        hole();
    }
  }
}

module piece() {
  difference() {
    blank();
    holes();
  }
}

piece();