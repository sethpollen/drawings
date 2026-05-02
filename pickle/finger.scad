// A long enough distance in every direction from the originl.
universe = 170;

finger_length = 40;
finger_width = 14;

slack_width = 0.4;
truncate = 1.5;

casing_slack = 0.1;

module finger_2d() {
    // Teeth.
    for (b = [-8:8])
    translate([slack_width/2 + b*(finger_width + slack_width), 0])
    intersection() {
      polygon([
        [finger_width/2, finger_length/2],
        [0, -finger_length/2],
        [finger_width, -finger_length/2],
      ]);
      
      // Chop off the tips.
      translate([0, -truncate])
      square([universe, finger_length], center=true);
    }
}

module backing_2d() {
  translate([-universe, -universe - finger_length/2])
  square([universe*2, universe]);
}

module casing_2d() {
  translate([-universe, -universe - casing_slack])
  square([universe*2, universe]);
}

// TODO: stack it all together.

linear_extrude(1) finger_2d();
color("green") linear_extrude(3) backing_2d();
color("red") linear_extrude(4) casing_2d();