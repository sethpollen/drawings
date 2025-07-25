use <stack.scad>

side = 30;
height = 3.2;
hook_width = 2.1;
hook_protrusion_length = 5.2;
hook_arm_length = 3.5;

slack = 0.7;
side_loose = 0.8;

chamfer = 0.6;

eps = 0.0001;

module hook_2d(protrude=true, arm=true) {
  $fn = 30;
  
  intersection() {
    chop_top = 1;
    translate([0, chop_top])
      square([hook_width, height - chop_top]);
    
    // Gently rounded.
    translate([hook_width - 4.8, 0])
      rotate([0, 0, 12])
        square(10, center=true);
    
    // Elephant foot.
    translate([hook_width - 4.8, 0])
      rotate([0, 0, 45])
        square(10, center=true);
    
    if (!protrude)
      translate([0, height/2 + 0.2])
        square(10);
  }

  if (arm)
    translate([-hook_width, height/2 + 0.2])
      square([hook_width, height/2 - 0.2]);
}

module hook() {
  difference() {
    rotate([-90, 0, 0]) {
      translate([slack/2, -height, -hook_arm_length - hook_protrusion_length/2]) {
        stack(hook_arm_length - side_loose/2) {
          hook_2d(protrude=false);
          stack(side_loose/2) {
            hook_2d(protrude=false, arm=false);
            stack(hook_protrusion_length) {
              hook_2d(arm=false);
              stack(side_loose/2) {
                hook_2d(protrude=false, arm=false);
                stack(hook_arm_length - side_loose/2) {
                  hook_2d(protrude=false);
                }
              }
            }
          }
        }
      }
    }
    
    cham = chamfer * sqrt(2);
    for (a = [-1, 1])
      translate([0, a * (hook_arm_length + hook_protrusion_length/2), 0])
        rotate([45, 0, 0])
          cube([10, cham, cham], center=true);
    
    // Round off corners.
    for (a = [-1, 1])
      scale([1, a, 1])
        translate([hook_width, hook_arm_length + hook_protrusion_length/2, 0])
          rotate([0, 0, -45])
            cube([10, 0.7, 10], center=true);
  }
  
  translate([0.8, 0, 1.9])
    cube([hook_width + 0.3, hook_protrusion_length - 0.8, 1], center=true);
}

module hole() {
  translate([-hook_width/2, 0, 0]) {
    translate([0, 0, -1])
      linear_extrude(height+2)
        square([hook_width + slack, hook_protrusion_length + side_loose], center=true);
    
    translate([0, 0, height/2 - 0.2])
      linear_extrude(height+2)
        square([hook_width + slack, hook_protrusion_length + side_loose + 2*hook_arm_length], center=true);
    
    // Foot inside hole.
    translate([0, 0, -1])
      linear_extrude(1.2)
        offset(0.25, $fn=12)
          square([hook_width + slack, hook_protrusion_length + side_loose], center=true);
    
    // Chamfer.
    c = chamfer*sqrt(2) * 1.1;
    translate([(hook_width + slack)/-2, 0, height])
      rotate([0, 45, 0])
        cube([c, hook_protrusion_length + side_loose + 2*hook_arm_length, c], center=true);
  }
}

module piece_2d(recede) {
  roundoff = 0.8;
  $fn = 16;

  offset(roundoff)
    offset(-roundoff-recede)
      square(side, center=true);
}

module piece_exterior(knurl=false) {
  difference() {
    hull() {
      translate([0, 0, height/2])
        linear_extrude(height/2)
          piece_2d(chamfer);
      
      // Slightly stronger chamfer on bottom.
      linear_extrude(height/2)
        piece_2d(chamfer*1.2);

      translate([0, 0, chamfer])
        linear_extrude(height - 2*chamfer)
          piece_2d(0);
    }
    
    if (knurl)
      knurling();
  }
}

module piece(knurl=false, flip_link=false, elide_link=false) {
  difference() {
    union() {
      piece_exterior(knurl);
      
      for (a = [0:3]) {
        if (!elide_link || a < 2)
          rotate([0, 0, a*90])
            translate([side/2, 0, flip_link ? height : 0])
              scale([1, 1, flip_link ? -1 : 1])
                hook();
      }
    }
    
    for (a = [0:3]) {
      if (!elide_link || a < 2)
        rotate([0, 0, a*90])
          translate([side/2, 0, flip_link ? height : 0])
            scale([1, 1, flip_link ? -1 : 1])
              hole();
    }
  }
}

module knurl_2d() {
  difference() {
    for (a = [-1, 1])
      scale([1, a])
        for (b = [-0.5, 0, 0.5])
          translate([b * side, 0])
            rotate([0, 0, 45])
              square([1, 80], center=true);

    for (a = [-2:2])
      translate([a*side/2, 0, 0])
        for (b = [0:4])
          translate((side/4) * [b-2, b-2])
            rotate([0, 0, 45])
              square(6, center=true);
  }
}

module knurling() {
  translate([0, 0, -0.8])
    linear_extrude(1)
      offset(0.3)
        knurl_2d();

  translate([0, 0, -0.2])
    linear_extrude(1)
      knurl_2d();
  
  translate([0, 0, height-0.8])
    linear_extrude(1)
      knurl_2d();
}

module terminus_2d(recede) {
  intersection() {
    piece_2d(recede);
    
    hull() {
      translate([side*0.4, 0])
        circle(d=side - 2*recede, $fn=60);
      translate([side, 0])
        square(side, center=true);
    }
  }
}

module terminus() {
  difference() {
    union() {
      hull() {
        translate([0, 0, height/2])
          linear_extrude(height/2)
            terminus_2d(chamfer);
        
        // Slightly stronger chamfer on bottom.
        linear_extrude(height/2)
          terminus_2d(chamfer*1.2);

        translate([0, 0, chamfer])
          linear_extrude(height - 2*chamfer)
            terminus_2d(0);
      }

      translate([side/2, 0, 0])
        hook();
    }
    
    translate([side/2, 0, 0])
      hole();
  }
}

module room(knurl=false) {
  separation = side + 0.2;
  
  difference() {
    union() {
      // Center.
      piece(knurl, flip_link=true);
      
      // Corners.
      for (a = [0:3])
        rotate([0, 0, a*90])
          translate([-separation, -separation])
            piece(knurl, flip_link=true, elide_link=true);
      
      // Sides.
      for (a = [0:3])
        rotate([0, 0, 90*a])
          translate([0, -separation])
            piece(knurl);
      
      // Thick join strips.
      translate([0, 0, chamfer])
        linear_extrude(height - 2*chamfer)
          for (a = [0:3])
            rotate([0, 0, a*90])
              translate([separation/2, 0])
                square([2, 3*separation-2], center=true);
          
      // Thin join plate. Thin enough not to disrupt the knurls.
      translate([0, 0, height/2 - 0.4])
        linear_extrude(0.8)
          square(2.5*separation, center=true);
    }
  }
}

piece(true);