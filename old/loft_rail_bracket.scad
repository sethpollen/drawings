tight = 0.01;
slack = 0.03;
plate_thickness = 3/8;
bottom_height = 0.8;
finger_thickness = 0.6;

length = 1.5 + 1.5 + finger_thickness + slack;
width = 1.5 + tight + 2*plate_thickness;
height = 3.25 + bottom_height;

head_countersink_diameter = 0.53;
tail_countersink_diameter = 0.78;
countersink_depth = 3/64;
hole_diameter = 0.27;

module octahedron(major_radius=1) {
  // Top and bottom halves.
  for (a = [-1, 1])
    scale([1, 1, a])
      // Extrude a square into a pyramid.
      linear_extrude(major_radius, scale=0)
        rotate([0, 0, 45])
          square(sqrt(2)*major_radius, center=true);
}

module chamfered_cube(dims, chamfer=1) {
  assert(dims.x >= 2*chamfer);
  assert(dims.y >= 2*chamfer);
  assert(dims.z >= 2*chamfer);

  hull()
    for (a = [0, 1], b = [0, 1], c = [0, 1])
        translate([
          (dims.x - 2*chamfer) * a + chamfer,
          (dims.y - 2*chamfer) * b + chamfer,
          (dims.z - 2*chamfer) * c + chamfer
        ])
          octahedron(chamfer);
}

$fn = 50;
chamfer = 3/16;

module bracket() {
  // Fill in the finger with nice chamfers.
  translate([0, -width/2, 0])
    chamfered_cube([finger_thickness, width, height], chamfer);

  translate([0, width/2 - plate_thickness, 0])
    chamfered_cube([length*0.7, plate_thickness, height], chamfer);
  
  // Brim.
  translate([length - chamfer + 0.2/25.4, -1.5, 0])
    cube([0.5, 3, 0.2/25.4]);
  translate([-0.5 + chamfer - 0.2/25.4, -1.5, 0])
    cube([0.5, 3, 0.2/25.4]);
  
  difference() {
    translate([0, -width/2, 0])
      chamfered_cube([length, width, height], chamfer);
    
    // Chamfer.
    translate([1.5 + finger_thickness + slack, 0, height])
      rotate([0, 45, 0])
        cube([chamfer*sqrt(2), 10, chamfer*sqrt(2)], center=true);
    
    // Vertical.
    translate([5 + finger_thickness + 1.5 + slack, 0, 0])
      cube([10, 1.5 + tight, 10], center=true);
    
    // Rail.
    translate([finger_thickness + 0.0001 - chamfer, -10 + 1.5/2 + tight/2 + chamfer, bottom_height])
      cube([1.5 + slack + chamfer, 10, 10]);
    
    // Countersink.
    for (a = [0.2, 0.8]) {
      translate([length*0.8, -width/2, a*height]) {
        rotate([90, 0, 0]) {
          // Head countersink.
          translate([0, 0, -countersink_depth])
            cylinder(1, d=head_countersink_diameter);
          
          // Bolt countersink.
          translate([0, 0, -10])
            cylinder(20, d=hole_diameter);
          
          // Tail countersink.
          translate([0, 0, -1 + countersink_depth - width])
            cylinder(1, d=tail_countersink_diameter);
        }
      }
    }
  }
}

module print() {
  // Convert from inches to millimeters.
  scale([1, 1, 1] * 25.4)
    bracket();
}

print();