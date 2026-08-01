eps = 0.001;

// Table parameters.
//
// The folding table is 1.5" thick. Add 0.6mm of slack.
table_thickness = 1.5 * 25.4 + 0.6;
table_width = 29.125 * 25.4;

// Leaf parameters.
screw_spacing = 2 * 25.4;
leaf_screw_spacing = 30.75 * 25.4;

// Add 0.4mm of slack on either side.
screw_offset = (leaf_screw_spacing - table_width) / 2 - 0.4;

gauge = 9.5;
depth = 15;
width = 18;
chamfer = gauge - 2;

flat = screw_offset + screw_spacing + gauge + 12;

module chop_2d() {
  $fn = 40;
  difference() {
    square(1);
    circle(1);
  }
}


module exterior_2d() {  
  // Finger.
  translate([-depth, table_thickness])
    square([depth, gauge]);

  intersection() {
    square([gauge + flat, table_thickness + gauge]);
    
    hull() {
      $fn = 50;
      square(1);
      translate([0, table_thickness + gauge - chamfer])
        circle(chamfer);
      translate([flat - chamfer, gauge - chamfer + 1])
        circle(chamfer);
      translate([flat - chamfer, 0])
        square([chamfer, eps]);
    }
  }
}

module body_2d() {
  difference() {
    exterior_2d();
    translate([1, 1])
      offset(-gauge)
        exterior_2d();
  }
}

module body() {
  chamf_layers = 6;
  layer = 0.2;

  for (a = [-1, 1]) {
    scale([1, 1, a]) {
      translate([0, 0, -width/2]) {
        for (b = [0:chamf_layers-1]) { 
          translate([0, 0, b*layer]) {
            linear_extrude(layer + eps) {
              intersection() {
                body_2d();
                translate((b - chamf_layers)*[layer, layer])
                  exterior_2d();
              }
            }
          }
        }
        
        translate([0, 0, chamf_layers*layer])
          linear_extrude(width/2 - chamf_layers*layer + eps)
            body_2d();
      }
    }
  }
}

screw_shaft_diam = 4;
screw_shaft_length = 4.4;
screw_head_diam = 8.6;
screw_head_height = 4.6;

screw_cav_length = 11;

module octagon(d) {
  intersection() {
    square(d, center=true);
    rotate([0, 0, 45])
      square(d, center=true);
  }
}

module screw_cav() {
  $fn = 30;

  shaft = screw_shaft_diam + 0.4;
  head = screw_head_diam + 1;
  
  translate([0, 0, screw_shaft_length]) {
    translate([0, 0, -10]) {
      linear_extrude(10 + eps) {
        hull() {
          octagon(d=shaft);
          translate([screw_cav_length, 0]) octagon(d=shaft);
        }
        translate([screw_cav_length, 0]) octagon(d=head);
      }
    }

    linear_extrude(screw_head_height) {
      hull() {
        octagon(d=head);
        translate([screw_cav_length, 0]) octagon(d=head);
      }
    }
  }
}

module piercing_2d() {
  intersection() {
    difference() {
      $fn = 40;
      offset(-1.4)
        body_2d();
      offset(-2)
        body_2d();
    }
    union() {
      // Hook.
      translate([-depth, 0])
        square([depth + gauge*0.3, 1000]);
      
      // Screw holes.
      square([flat, gauge/2]);
    }
  }
}

module piece(reinf=true) {
  difference() {
    union() {
      // Foot.
      translate([0, 0, -width/2])
        linear_extrude(0.2)
          offset(-0.2)
            projection(cut=true)
              translate([0, 0, width/2-0.1])
                body();

      intersection() {
        body();
        translate([0, 0, 500.2-width/2])
          cube(1000, center=true);
      }
    }
      
    rotate([-90, 0, 0]) {
      translate([screw_offset, 0])
        screw_cav();
      translate([screw_offset + screw_spacing, 0])
        screw_cav();
    }
    
    if (reinf)
      for (z = width/5 * [-1.6, -0.75, 0.75, 1.6])
        translate([0, 0, z - 0.1])
          linear_extrude(0.2)
            piercing_2d();
  }
}

module print(reinf=true) {
  translate([0, 0, width/2])
    piece(reinf);
  
  // Tags.
  linear_extrude(0.4) {
    translate([-4.4, 0.5]) square(5);
    translate([0.5, -4.4]) square(5);
    translate([flat - 6.5, -4.4]) square(5);
    translate([-depth - 4.4, table_thickness + 0.5]) square([5, gauge-2.5]);
  }
}

print(true);