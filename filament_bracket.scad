base = [80, 50];
leg = [26, 110];
foot = [83, 26];
toe = [6, 7];

main_thickness = 22;

module octahedron(bevel) {
  for (a = [-1, 1])
  scale([1, 1, a])
  linear_extrude(bevel, scale=0)
  rotate([0, 0, 45])
  square(bevel*sqrt(2), center=true);
}

module block(xy, thickness=main_thickness, bevel=4) {
  hull()
  for (
    x = [bevel, xy.x-bevel],
    y = [bevel, xy.y-bevel],
    z = [bevel, thickness-bevel]
  )
  translate([x, y, z])
  octahedron(bevel);
}

module exterior() {
  translate([leg.x - base.x, 0, 0])
  block(base);
  
  translate([0, -leg.y - foot.y])
  block(leg + [0, base.y + foot.y]);
  
  translate([-foot.x - toe.x, -leg.y - foot.y])
  block(foot + [leg.x + toe.x, 0]);
  
  translate([-foot.x - toe.x, -leg.y - foot.y + 4, 3])
  block(toe + [0, foot.y], thickness=14, bevel=1);
}

module screw_hole() {
  $fn = 16;

  translate([0, 0, main_thickness + 0.01])
  scale([1, 1, -1]) {
    linear_extrude(1.1)
    circle(d=7.5);
    
    translate([0, 0, 1.1 - 0.01])
    linear_extrude(4, scale=0)
    circle(d=7.5);
    
    cylinder(h=30, d=4.2);
  }
}

module piece() {
  difference() {
    exterior();
    
    translate([leg.x - base.x/2, base.y-10])
    screw_hole();
    
    for (x = [leg.x/2, leg.x*1.5-base.x])
    translate([x, 16])
    screw_hole();
  }
}

piece();