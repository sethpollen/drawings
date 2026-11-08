width = 233;
floor_height = 13;
thickness = 80;
back_wall = 15;

groove_height = 140;
laptop_thickness = 23;
groove_slack = 1;
liner_protrusion = 1;
groove_thickness = laptop_thickness + groove_slack + 2*liner_protrusion;

liner_recess_depth = 1.4;
liner_bezel = 8;

height = floor_height + groove_height;

difference() {
  cube([width, thickness, height]);
  
  // Top side edge bezels.
  for (x = [0, width])
  translate([x, 0, height])
  rotate([0, 45, 0])
  cube([10, 200, 10], center=true);
  
  // Top front bezel.
  top_front_bezel = thickness*sqrt(2) - 72;
  translate([0, thickness, height])
  scale([1, 1, 180/top_front_bezel])
  rotate([45, 0, 0])
  cube([700, top_front_bezel, top_front_bezel], center=true);
  
  translate([-1, back_wall, floor_height])
  cube([width+2, groove_thickness, height]);
  
  translate([liner_bezel, back_wall-liner_recess_depth, floor_height-liner_recess_depth])
  cube([width-2*liner_bezel, groove_thickness+2*liner_recess_depth, height-floor_height+liner_recess_depth-liner_bezel]);
}