use <paddle.scad>

module core() {
  // The main part of the core.
  intersection_for(z = [
    // The very first layer is 0.2mm instead of 0.16mm. The floor consists of two
    // solid layers, two 50% layers, and two final solid layers.
    0.2 + 3*0.16,
    // The ceiling consists of three solid layers, two 50% layers, and two solid layers.
    -5*0.16
  ])
  translate([0, 0, z]) {
    wedge();
    grip();
  }
  
  // Also reduce shelf infill to 10%.
  difference() {
    shelf();
    
    translate([0, 0, 0.16]) {
      wedge();
      grip();
    }
  }
}

positioning_square();

print_position()
core();
