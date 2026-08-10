use <paddle.scad>

positioning_square();

print_position() {
  // The main part of the core.
  intersection_for(z = [
    // The very first layer is 0.2mm instead of 0.16mm. The floor consists of two
    // solid layers, three 50% layers, and one final solid layer.
    0.2 + 4*0.16,
    // The ceiling consists of two solid layers, two 50% layers, and two solid layers.
    -4*0.16
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