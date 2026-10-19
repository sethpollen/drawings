use <paddle.scad>

module paddle_profile(inset) {
  offset(-inset)
  projection() {
    wedge();
    grip();
  }
}

module strake(width, top, bottom) {
  difference() {
    paddle_profile(0);
    paddle_profile(width);
    
    translate([-200, top])
    square(400);
    
    translate([0, -bottom-200])
    square(400, center=true);
  }
}

module strakes_2d() {
  steps = 30;
  for (i = [0:steps-1])
  strake(15*i/steps, 76-53*i/steps, 87-60*i/steps);
}

module preview() {
  color("cyan")
  translate([0, 0, -2])
  linear_extrude(1)
  paddle_profile(0);
  
  strakes_2d();
}

module strakes() {
  linear_extrude(100)
  strakes_2d();
}

module print() {
  color("cyan")
  positioning_square();

  difference() {
    print_position()
    strakes();
    
    // Don't add any material to the hooked part; it is not under
    // high stress.
    translate([0, -325, -1])
    linear_extrude(110)
    square(400, center=true);
  }
}

print();
