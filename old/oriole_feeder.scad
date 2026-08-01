eps = 0.01;

hole_top_diameter = 87;
slope = 2.3;

hole_diameter_adjustment = 9;

inner_rail = 20;
moat = 15;
outer_rail = 16;

od = hole_top_diameter + 2 * (inner_rail + moat + outer_rail);

height = 12;
roundover_top_r = 5;
roundover_bottom_r = 1.5;

hole_bottom_diameter = (hole_top_diameter+hole_diameter_adjustment) - 2 * height/slope;

module profile_2d() {
  hull() {
    square([eps, height]);

    // Top chamfer.
    translate([od/2 - roundover_top_r, 0]) {
      intersection() {
        translate([0, height - roundover_top_r])
          circle(roundover_top_r, $fn=50);
        square(height);
      }
    }
    
    // Bottom chamfer.
    translate([od/2 - roundover_bottom_r, 0]) {
      intersection() {
        translate([0, roundover_bottom_r])
          circle(roundover_bottom_r, $fn=20);
        square(height);
      }
    }
  }
}

hook_major_r = 7;
hook_minor_r = 2.5;
hook_id = 2 * (hook_major_r - hook_minor_r);

module hook(minor_r=hook_minor_r) {
  translate([hole_top_diameter/2 + inner_rail + moat/2 + 15, 0, height + hook_major_r/2])
    rotate([90, 0, 0])
      rotate_extrude($fn=40)
        translate([hook_major_r, 0])
          circle(minor_r, $fn=20);
}

module moats_2d() {
  $fn = 90;
  moat_center_r = hole_top_diameter/2 + inner_rail + moat/2 + 6.3;
  
  offset(moat/2) {
    difference() {
      circle(moat_center_r+0.05);
      circle(moat_center_r-0.05);
      
      strut_width = 33;
      for (a = 120 * [0, 1, 2])
        rotate([0, 0, a])
          translate([-strut_width/2, 0])
            square([strut_width, 1000]);
    }
  }
}

module piece() {
  difference() {
    // Exterior.
    rotate_extrude($fn=90)
      profile_2d();
    
    translate([0, 0, -eps]) {
      // Main hole.
      $fn = 60;
      cylinder(h=height+2*eps, d1=hole_bottom_diameter, d2=hole_top_diameter+hole_diameter_adjustment);
      cylinder(h=1, d1=hole_bottom_diameter+2, d2=hole_bottom_diameter);
      
      // Moats.
      linear_extrude(height+2*eps)
        moats_2d();
      
      // Slightly chamfer top of moats.
      for (a = [1:4])
        translate([0, 0, height - a*0.2])
          linear_extrude(0.2 + eps)
            offset((4-a)*0.2)
              moats_2d();
    }
  }
  
  // Hooks.
  for (a = 120 * [0, 1, 2])
    rotate([0, 0, a + 90])
      hook();
}

module signature() {
  txt = "To Mom     From Seth     2O24";
  
  translate([0, 0, -eps])
    linear_extrude(2)
      for (i = [0:100])
        rotate([0, 0, i*10])
          translate([4, 52])
            offset(0.5)
              scale([-1, 1])
                text(txt[i], size=10, font="Consolas");
}

module main() {
  difference() {
    piece();

    signature();

    // Piercings for strength.
    for (a = 120 * [0, 1, 2])
      rotate([0, 0, a + 90])
        hook(minor_r=0.3);
  }
}

translate([0, 0, 1])
main();
