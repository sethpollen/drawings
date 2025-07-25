// Roz is 48.5mm across the shoulders.
width = 60;
shoulder_height = 17; 
arm_spacing = 2;
arm_width = (width - 3*arm_spacing)/4;
arm_length = 40;
leg_length = 67;
head_width = 20;
head_height = 17;
eye = 5.4;

module torso_2d() {
  $fn = 50;
  intersection() {
    circle(d=width);
    translate([-width/2, -width]) square(width);
  }
  translate([-width/2, 0]) square([width, shoulder_height]);
}

module arms_2d() {
  $fn = 30;
  for (a = [-1, 1]) {
    scale([a, 1]) {
      translate([width/2-arm_width, -arm_length]) {
        square([arm_width, arm_length]);
        translate([arm_width/2, 0])
          circle(d=arm_width);
      }
    }
  }
}

module legs_2d() {
  $fn = 30;
  for (a = [-1, 1]) {
    scale([a, 1]) {
      translate([arm_spacing/2, -leg_length]) {
        square([arm_width, leg_length]);
        translate([arm_width/2, 0])
          circle(d=arm_width);
      }
    }
  }
}

module head_2d() {
  $fn = 50;
  difference() {
    translate([-head_width/2, shoulder_height])
      square([head_width, head_height]);
    for (a = [-1, 1])
      scale([a, 1])
        translate([eye*0.85, shoulder_height + head_height*0.75])
          circle(d=eye);
  }
  // Dome.
  translate([0, shoulder_height + head_height])
    scale([1, 0.4])
      circle(d=head_width);
}

module reco() {
  linear_extrude(5.6) {
    torso_2d();
    arms_2d();
    legs_2d();
    head_2d();
  }
  translate([0, 0, 5.6])
    for (i = [0:6])
      translate([0, 0, i*0.2])
        linear_extrude(0.2001)
          offset(-i*0.2)
            torso_2d();

  // Crest.
  crest_width = 1.8;
  translate([-crest_width/2, shoulder_height + 7, 0])
    cube([crest_width, 15.4, 7]);
  mouth_width = head_width*0.55;
  translate([-mouth_width/2, shoulder_height + 2.3, 0])
    cube([mouth_width, crest_width, 7]);
}

reco();