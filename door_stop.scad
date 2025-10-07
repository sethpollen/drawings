$fn = 50;

shaft_od = 18;
length = 63;

screw_hole_id = 2.4;
screw_head_hole_id = 7.5;
screw_depth = 9;

module basic() {
  difference() {
    cylinder(d=shaft_od, h=length);
      
    translate([0, 0, screw_depth])
      cylinder(d=screw_head_hole_id, h=1000);
    
    translate([0, 0, -1])
      cylinder(d=screw_hole_id, h=1000);
  }
}

module tipped() {
  intersection() {
    translate([0, 0, shaft_od/2 - 2])
      rotate([90, 0, 0])
        basic();

    translate([0, 0, 100])
      cube(200, center=true);
    
    nudge = 20;
    translate([0, -nudge, shaft_od/2 - 2])
      sphere(length - nudge, $fn=300);
  }
}

tipped();