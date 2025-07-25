eps = 0.001;
layer = 0.2;

// Same height as a marine figure.
height = 40;
widthx = 25; 
widthy = 28;

base_height = 4;
frame_depth = 7;

module exterior_2d() {
  difference() {
    square([widthx, widthy], center=true);
    
    // Chamfer corners.
    for (a = [-1, 1], b = [-1, 1])
      scale([a, b])
        translate([widthx/2, widthy/2])
          rotate([0, 0, 45])
            square(6, center=true);
  }
}

module exterior() {
  // Base.
  linear_extrude(layer)
    offset(-0.2)
      exterior_2d();
  translate([0, 0, layer])
    linear_extrude(base_height - layer)
      exterior_2d();

  // Above the base.
  translate([0, 0, base_height])
    linear_extrude(height - base_height)
      square([widthx, widthy], center=true);
}

module buttons() {
  $fn = 30;
  
  difference() {
    hull() {
      cube([5, 4, 5.9]);
      translate([3.8, 4, -3])
        cube([1, eps, eps]);
    }
    
    translate([-1.25, 0.75, 2.75])
      cube(2.5);
  
    translate([0, 2, 2.2])
      rotate([0, 90, 0])
        for (a = [-1, 1])
          scale([1, a, 1])
            translate([0.9, 0.9, -eps])
              cylinder(d=1.2, h=1);
  }
}

module crack_atom() {
  linear_extrude(0.3)
    rotate([0, 0, 45])
      square(0.9, center=true);
}

module crack() {
  hull() {
    translate([0, 0, 2]) crack_atom();
    translate([0, 0, 4]) crack_atom();
  }
  hull() {
    translate([0, 0, 4]) crack_atom();
    translate([0, 3, 7]) crack_atom();
  }
  hull() {
    translate([0, 3, 7]) crack_atom();
    translate([0, 3, 11]) crack_atom();
  }
  hull() {
    translate([0, 3, 11]) crack_atom();
    translate([0, 0, 14]) crack_atom();
  }
  hull() {
    translate([0, 0, 14]) crack_atom();
    translate([0, 0, 17]) crack_atom();
  }
  hull() {
    translate([0, 0, 17]) crack_atom();
    translate([0, 3, 20]) crack_atom();
  }
  hull() {
    translate([0, 3, 20]) crack_atom();
    translate([0, 3, 23]) crack_atom();
  }
  hull() {
    translate([0, 3, 23]) crack_atom();
    translate([0, 0, 26]) crack_atom();
  }
  hull() {
    translate([0, 0, 26]) crack_atom();
    translate([0, 0, 29]) crack_atom();
  }
  hull() {
    translate([0, 0, 29]) crack_atom();
    translate([0, 3, 32]) crack_atom();
  }
  hull() {
    translate([0, 3, 32]) crack_atom();
    translate([0, 3, 34.7]) crack_atom();
  }
}

module door() {
  difference() {
    exterior();
    
    // Cut away front and back of frame.
    for (a = [-1, 1]) {
      scale([a, 1]) {
        translate([frame_depth/2, -50, base_height-eps]) {
          hull() {
            fillet = 3;
            translate([fillet, 0, 0]) cube(100);
            translate([0, 0, fillet]) cube(100);
          }
        }
      }
    }
    
    // Chamfer top corners.
    for (a = [-1, 1])
      scale([1, a])
        translate([0, widthy/2, height])
          rotate([45, 0, 0])
            cube([20, 7, 7], center=true);
    
    // Emboss a door.
    for (b = [0, 180]) {
      emboss_width = widthy - 6;
      
      rotate([0, 0, b]) {
        translate([1, -1.5, base_height-2])
          crack();

        difference() {
          translate([1, -emboss_width/2, base_height])
            cube([20, emboss_width, height - 3 - base_height]);
          
          for (a = [-1, 1])
            scale([1, a])
              translate([1, -emboss_width/2, height - 3])
                rotate([45, 0, 0])
                  cube([20, 5, 5], center=true);
        }
      }
    }
  }
  
  // Control buttons.
  for (a = [0, 180])
    rotate([0, 0, a])
      translate([-5.5, 8, 15])
        buttons();
}

door();