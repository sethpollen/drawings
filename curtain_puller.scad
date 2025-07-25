eps = 0.001;
r = 3;

module octagon(radius) {
  intersection_for(a = [0, 45])
    rotate([0, 0, a])
      square(2*radius, center=true);
}

module profile() {
  octagon(r);
}

module straight(l) {
  linear_extrude(l)
    profile();
  translate([0, 0, l])
    children();
}

module curve(r, a) {
  translate([-r, 0, 0])
    rotate([90, 0, 0])
      rotate_extrude(angle=a, $fn=60)
        translate([r, 0, 0])
          profile();
  translate([-r, 0, 0])
    rotate([0, -a, 0])
      translate([r, 0, 0])
        children();
}

module ball() {
  intersection_for(as = [
    [0, 0, 0],
    [0, 0, 45],
    [0, 45, 0],
    [45, 0, 0],
  ])
    rotate(as)
      cube(2*r, center=true);
  
  children();
}

module hook() {
  ball()
  straight(22)
  curve(25.4/2+r + 2, 168)
  straight(66)
  mirror([1, 0, 0])
  curve(9, 150)
  straight(20)
  ball();
}

ferrule_id = 9.65;
ferrule_wall = 3;
ferrule_length = 12;

module ferrule_exterior() {
  linear_extrude(ferrule_length)
    octagon((ferrule_id + ferrule_wall)/2);
  
  translate([0, 0, ferrule_length])
    intersection_for(as = [
      [0, 0, 0],
      [0, 0, 45],
      [0, 45, 0],
      [45, 0, 0],
    ])
      rotate(as)
        cube(ferrule_id + ferrule_wall, center=true);
}

module ferrule_interior() {
  translate([0, 0, -eps])
    linear_extrude(ferrule_length)
      octagon(ferrule_id/2);
}

module hook_plus_ferrule() {
  ferrule_offs = [-57.5, 0, -61.5];
  difference() {
    union() {
      hook();  
      translate(ferrule_offs)
        ferrule_exterior();
    }
    translate(ferrule_offs)
      ferrule_interior();
  }
}

module main() {
  rotate([90, 0, 0])
    hook_plus_ferrule();
}

main();