eps = 0.001;

base = [65, 46];
base_length = 90;
clearance = 97;
lip = 7;
front_wall = 15;
arm_thickness = 26;
tube_length = 90;

// #8 wood screw.
module screw_hole(small=false) {
  $fn = 16;
  
  head_diam = small ? 8 : 8.2;

  scale([1, 1, -1]) {
    translate([0, 0, -100])
    linear_extrude(101.1)
    circle(d=head_diam);
    
    translate([0, 0, 1.1 - 0.01])
    linear_extrude(3.9, scale=0)
    circle(d=head_diam);
    
    cylinder(h=100, d=small ? 3.8 : 4.3);
  }
}

module tube_2d() {
  translate([0, -15])
  intersection() {
    square(30, center=true);
    
    scale([1, 0.9])
    circle(d=36, $fn=40);
  }
}

module lip_2d() {
  minkowski() {
    tube_2d();
    
    intersection() {
      circle(r=lip);
      
      intersection_for (a = [30, 90])
      rotate([0, 0, a])
      square(30);
    }
  }
}

module base_2d() {
  translate([front_wall-base.x, lip + clearance])
  square(base);
}

module cutout_2d() {
  translate([-front_wall, 10])
  base_2d();
}

module piece() {
  difference() {
    union() {
      linear_extrude(arm_thickness + eps)
      hull() {
        tube_2d();
        base_2d();
      }
      
      translate([0, 0, arm_thickness]) {
        linear_extrude(tube_length + eps)
        tube_2d();
        
        // Fillet at lower stress point.
        hull() {
          translate([0, 2, 0])
          linear_extrude(eps) tube_2d();
          
          translate([0, 0, 2])
          linear_extrude(eps) tube_2d();
        }
        
        linear_extrude(base_length - arm_thickness)
        base_2d();

        translate([0, 0, tube_length])
        linear_extrude(5)
        lip_2d();
      }
    }
    
    translate([0, 0, -1])
    linear_extrude(150)
    cutout_2d();
  
    // Front screw holes.
    for (z = [15, base_length-15])
    translate([front_wall, lip + clearance + base.y*0.72, z])
    rotate([0, 90, 0])
    screw_hole();

    // Bottom screw hole.
    translate([front_wall - base.x + 15, lip + clearance, base_length*0.5])
    rotate([90, 0, 0])
    screw_hole(small=true);
  
    // Cut excess material from the furthest corner.
    // TUNED
    translate([0, 100, 60])
    rotate([0, -40, 0])
    translate([0, 0, 100])
    cube(150, center=true);
    
    // Bevel the front.
    translate([front_wall, lip + clearance + base.y + 2])
    rotate([0, 0, 55])
    cube([10, 10, 300], center=true);
  }
  
  // Fillet in the corner by the 2x4.
  translate([0, lip + clearance + 10, base_length/2])
  rotate([0, 0, 45])
  cube([1.5, 1.5, base_length], center=true);
  
  // Fillet at the upper stress point.
  translate([front_wall - base.x/2, lip + clearance, arm_thickness])
  rotate([45, 0, 0])
  cube([base.x - 1.5, 3, 3], center=true);
}

module print() {
  rotate([0, 90, 0])
  piece();
}

module preview() {
  print();
  
  // The 2x4.
  color("red")
  translate([-50, lip + clearance + 10])
  cube([200, 1.5*25.4, 3.5*25.4]);
}
  
print();