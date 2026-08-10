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
    
    translate([-200, top]) square(400);
    translate([-200, -bottom-400]) square(400);
  }
}

module strakes_2d() {
  steps = 30;
  for (i = [0:steps-1])
  strake(13*i/steps, 48-47*i/steps, 62-38*i/steps);
}

module preview() {
  color("cyan")
  translate([0, 0, -2])
  linear_extrude(1)
  paddle_profile(0);
  
  strakes_2d();
}

module strakes() {
  linear_extrude(40)
  strakes_2d();
}

module print() {
  positioning_square();

  print_position()
  strakes();
}

print();