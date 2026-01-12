$fn = 100;

inner_id = 27.9;
outer_id = 46;
lap = 4.5;

inner_height = 4;
outer_height = 8;

module inner_2d() {
  intersection() {
    difference() {
      union() {
        circle(d=inner_id+10);
        square([1000, inner_id*0.85], center=true);
      }
      circle(d=inner_id);
    }
    circle(d=outer_id+lap);
  }
}

module outer_2d(cut=false) {
  difference() {
    circle(d=outer_id+16);
    circle(d=outer_id);
    
    offset_range = cut ? [-0.15, 0.3] : [0.3, 0.3];
    angle_range = cut ? [0, 100] : [100, 100];
    steps = 30;

    for (i = [0:steps]) {
      offs = offset_range[0] + (i/steps)*(offset_range[1]-offset_range[0]);
      angle = angle_range[0] + (i/steps)*(angle_range[1]-angle_range[0]);
      
      offset(offs)
      rotate([0, 0, angle])
      inner_2d();
    }
  }
}

module outer() {
  z_slack = 0.4;
  
  linear_extrude(outer_height)
  outer_2d(cut=true);
  
  translate([0, 0, inner_height+z_slack])
  linear_extrude(outer_height-inner_height-z_slack)
  outer_2d(cut=false);
}

module inner() {
  linear_extrude(inner_height)
  inner_2d();
}

module print() {
  translate([0, 0, outer_height])
  rotate([180, 0, 0])
  outer();

  translate([0, 51.5])
  inner();
}

print();