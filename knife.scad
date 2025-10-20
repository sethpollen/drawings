eps = 0.0001;

// 0 for fast, 1 for full render.
quality = 1;

blade_length = 150;
blade_width = 7;
blade_depth = 35;
tip_blunt = 3;

tang_depth = 18;
tang_length = 70;
tang_offset = 5;

handle_width = 15;
handle_depth = 28;
handle_length = tang_length;

ring_id = 20;
ring_od = 27;
ring_width = 8;
ring_offset = handle_depth + ring_id*0.3;

include_ring = true;

module blade_2d() {
  edge_depth = 10;
  for (a = [-1, 1])
    scale([a, 1])
      polygon([
        [-eps, 0],
        [blade_width/2, 0],
        [blade_width/2, blade_depth-edge_depth],
        [0.25, blade_depth],
        [-eps, blade_depth],
      ]);
}

module extrude_blade() {
  straight_length = blade_length - blade_depth + tip_blunt;
  linear_extrude(straight_length)
    children();
  translate([0, 0, straight_length-eps])
    rotate([0, 90, 180])
      rotate_extrude(angle=90, $fn=30+quality*30)
        rotate([0, 0, 90])
          children();
}

module pill(r, length) {
  hull()
    for (a = [-1, 1])
      scale([1, 1, a])
        translate([0, 0, length/2 - r])
          sphere(r); 
}

module blade() {
  difference() {
    intersection() {
      extrude_blade()
        blade_2d();
      translate([0, 0, -tip_blunt])
        extrude_blade()
          translate([-blade_width/2, 0])
            square([blade_width, blade_depth]);
      translate([0, blade_length*sqrt(2)-blade_width/4, 0])
        rotate([0, 0, 45])
          cube(blade_length*2, center=true);
    }
    
    depression_r = 10;
    depression_depth = 0.8;
    for (a = [-1, 1])
      scale([a, 1, 1])
        translate([blade_width/2 + depression_r - depression_depth, 10, blade_length*0.4])
          pill(r=depression_r, length=blade_length*0.6, $fn=25+quality*45);
  }
}

module tang() {
  translate([-blade_width/2, tang_offset, eps-tang_length])
    cube([blade_width, tang_depth, tang_length]);
}

module tombstone_2d(r, length) {
  translate([length-r, 0])
    circle(r=r);
  translate([0, -r])
    square([length-r, r*2]);
}

module handle() {
  $fn = 30 + quality*30;
  r = handle_width/2;

  difference() {
    translate([0, handle_depth + 1, -handle_length]) {
      rotate([0, 0, -90]) {
        intersection() {
          linear_extrude(handle_length)
            tombstone_2d(r, handle_depth);
          
          grip_r = handle_length * 5;
          translate([grip_r, 0, handle_length/2])
            rotate([90, 0, 0], $fn=100+quality*150)
              rotate_extrude()
                tombstone_2d(r, grip_r);
        }
      }
    }
    
    if (include_ring)
      translate([-15, ring_offset, -ring_od/2])
        rotate([0, 90, 0])
          cylinder(d=(ring_id+ring_od)/2, h = 30);
  }
}

module ring() {
  small_r = (ring_od - ring_id) / 4;
  
  translate([0, ring_offset, -ring_od/2])
    rotate([0, 90, 0])
      rotate_extrude($fn=30+quality*50)
        hull()
          for (a = [-1, 1])
            scale([1, a])
              translate([ring_id/2 + small_r, ring_width/2 - small_r])
                circle(small_r, $fn = 18);
}

module blade_print() {
  rotate([90, 0, 0]) {
    blade();
    tang();
  }
}

module preview() {
  blade();
  color("red") tang();
  color("blue") {
    handle();
    if (include_ring)
      ring();
  }
}

blade_print();
