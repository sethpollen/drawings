$fa = 5;
$fs = 0.5;
eps = 0.001;

tube_id = 11;
tube_od = tube_id + 4;
tube_length = 50;

loom_width = 20.9;
loom_gap = 5;
loom_wall = 2.2;
lip = 1.4;
loom_height = 13;

join = 5;

difference() {
  union() {
    translate([0, 0, -tube_length])
      cylinder(tube_length + join, d=tube_od);
    
    hull() {
      translate([0, 0, loom_height/2 - eps])
        cube([loom_width + 2*lip, loom_gap + 2*loom_wall, loom_height], center=true);
      translate([0, 0, -18])
        cube([1, 4, 1], center=true);
    }
  }
  
  // Inside of tube.
  translate([0, 0, -tube_length-eps])
    cylinder(tube_length*2, d=tube_id);
  
  // Transverse gap.
  translate([0, 0, loom_height/2 + join - eps])
    cube([loom_width + 2*lip + eps, loom_gap, loom_height + eps], center=true);
  
  // Cross gap.
  translate([0, -10, loom_height/2 - eps])
    cube([tube_id*0.88, 20, loom_height + eps], center=true);
  
  // Lips.
  for (a = [-1, 1]) {
    scale([a, 1, 1]) {
      hull() {
        translate([loom_width/2, -10, 1.5*lip])
          cube([20, 20, loom_height - 3*lip]);
        translate([loom_width/2 + lip, -10, lip])
          cube([20, 20, loom_height - 2*lip]);
      }
    }
  }
  
  // Observation ports.
  translate([-10, loom_gap/2 + loom_wall + eps, -10])
    cube(20);
  translate([-10, -loom_gap/2 - loom_wall - eps - 20, 0])
    cube(20);
  translate([-tube_id*0.44, loom_gap/2 + eps, -10])
    cube([tube_id*0.88, 20, 30]);
  
  // Gap between lips for hook.
  for (a = [-1, 1])
    scale([a, 1, 1])
      translate([tube_od*0.47, -loom_gap/2, -7.7-2*eps])
        cube([20, loom_gap, 20]); 
  
  // Inner chamfer on bottom.
  translate([0, 0, -tube_length-eps])
    linear_extrude(0.7, scale=(tube_id-0.7)/tube_id)
      circle(d=tube_id+0.7);
}

