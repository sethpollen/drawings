// Deck box is 96x72x20 mm.
// Add clearance of 1.3mm in the x and y directions.

eps = 0.001;
$fn = 50;

height = 40;
interior_dims = [3*72 + 0.8, 96 + 0.8];
wall = 6;

module interior_2d() {
  square(interior_dims, center=true);
}


module exterior_2d() {
  offset(wall*0.4)
    offset(delta=wall*0.6)
      interior_2d();
}

coffer_depth = wall - 3;

module long_coffer_2d() {
  square([interior_dims.x - 5*coffer_depth, height - 2*wall - 2*coffer_depth], center=true);
}

module short_coffer_2d() {
  square([height - 2*wall - 2*coffer_depth, interior_dims.y - 5*coffer_depth], center=true);
}

difference() {
  translate([0, 0, -height/2])
    linear_extrude(height)
      exterior_2d();
  
  for (a = [-1, 1]) {
    scale([1, 1, a]) {
      hull() {
        translate([0, 0, -eps])
          linear_extrude(eps)
            interior_2d();
        
        translate([0, 0, height/5])
          linear_extrude(eps)
            interior_2d();
      }
      hull() {
        translate([0, 0, height/5])
          linear_extrude(eps)
            interior_2d();
        
        translate([0, 0, height/2])
          linear_extrude(eps)
            offset(1)
              interior_2d();
      }
    }
  }
  
  // Build plate chamfers.
  translate([0, 0, -height/2-eps]) {
    linear_extrude(0.3) {
      offset(1.3)
        interior_2d();
      
      difference() {
        offset(10)
          exterior_2d();
        offset(-0.3)
          exterior_2d();
      }
    }
  }
  
  // Long wall coffers.
  for (a = [-1, 1]) {
    scale([1, a, 1]) {
      translate([0, -interior_dims.y/2 - wall + coffer_depth - eps, 0]) {
        rotate([90, 0, 0]) {
          hull() {
            linear_extrude(eps)
              long_coffer_2d();
            translate([0, 0, coffer_depth])
              linear_extrude(eps)
                offset(coffer_depth)
                  long_coffer_2d();
          }
        }
      }
    }
  }
  
  // Short wall coffers.
  for (a = [-1, 1]) {
    scale([a, 1, 1]) {
      translate([interior_dims.x/2 + wall - coffer_depth + eps, 0, 0]) {
        rotate([0, 90, 0]) {
          hull() {
            linear_extrude(eps)
              short_coffer_2d();
            translate([0, 0, coffer_depth])
              linear_extrude(eps)
                offset(coffer_depth)
                  short_coffer_2d();
          }
        }
      }
    }
  }
}


// Brims.
for (a = [-1, 1], b = [-1, 1])
  scale([a, b, 1])
    translate([interior_dims.x/2 - 4, interior_dims.y/2 + wall/2, -height/2])
      linear_extrude(0.4)
        square([6, wall+10], center=true);
