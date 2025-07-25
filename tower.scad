eps = 0.001;
$fn = 90;

id = 65;
wall = 1.7;
od = id + 2*wall;
height = 109;
brick_height = 11;
door_width = id * 0.9;
fence = 11.5;

module barrel() {  
  difference() {
    linear_extrude(height) {
      difference() {
        circle(od/2);
        circle(id/2);
      }
    }
    
    // Brick joints.
    for (z = [0:brick_height:height]) {
      translate([0, 0, z]) {
        // Horizontal joint.
        rotate_extrude()
          translate([od/2, 0])
            rotate([0, 0, 45])
              square(0.8, center=true);
        
        // Vertical joint.
        for (a = [0:40:360])
          rotate([0, 0, a + ((z / brick_height) % 2) * 20])
            translate([od/2, 0, -brick_height])
              linear_extrude(brick_height)
                rotate([0, 0, 45])
                  square(0.8, center=true);
      }
    }
    
    // Opening at the bottom.
    scale([1, 1, 1.18])
      rotate([0, 90, 0])
        cylinder(h=od, d=door_width);
  }
}

module ramps() {
  angle = 27;
  
  base = 34;
  spacing = 28;
  
  // Bottom ramp.
  translate([30, 0, 0])
    rotate([0, angle, 0])
      translate([0, 0, -100])
        cube(200, center=true);
  
  for (z = [base, base+2*spacing])
    translate([4, 0, z])
      rotate([0, -angle, 0])
        translate([0, -100, wall])
          cube([200, 200, wall]);
  
  translate([-4, 0, base+spacing])
    scale([-1, 1, 1])
      rotate([0, -angle, 0])
        translate([0, -100, wall])
          cube([200, 200, wall]);
}

module constrained_ramps() {
  intersection() {
    ramps();
    
    union() {
      cylinder(h=height, d=id+wall);
      translate([0, -(id-wall)/2, 0])
        cube([id-wall, id-wall, fence]);
    }
  }
}

module parapet() {
  difference() {
    intersection() {
      translate([0, 0, height-1]) {
        cylinder(h=5, d1=od, d2=od+10);
        translate([0, 0, 5-eps])
          cylinder(h=5, d=od+10);
      }
      
      translate([0, 0, 47.3])
        cylinder(h=height, d1=height*2, d2=0);
    }
    
    cylinder(h=1000, d=id);
    
    translate([0, 0, height-26.5])
      cylinder(h=200, d1=0, d2=400);
  }
}

module base() {
  chamfer = 2.6;
  
  difference() {
    hull() {
      for (a = [0, id]) {
        translate([a, 0]) {
          difference() {
            cylinder(h=fence, d=id);
            rotate_extrude()
              translate([id/2, 0])
                rotate([0, 0, 45])
                  square(0.8, center=true);
          }
        }
      }
    }
        
    translate([0, 0, wall]) {
      cylinder(h=height, d=id);
      
      hull()
        for (a = [0, id])
          translate([a, 0])
            cylinder(h=chamfer, d1=id-2*wall-2*chamfer, d2=id-2*wall);

      translate([0, 0, chamfer-eps])
        hull()
          for (a = [0, id])
            translate([a, 0])
              cylinder(h=fence, d=id-2*wall);
    }
  }
}

barrel();
constrained_ramps();
parapet();
base();