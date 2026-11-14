brick_dim = [28, 93, 12];

module brick() {
  cube(brick_dim);
  
  translate([7, -14, -30])
  cube([30, 28, 50]);
}

module shelf_exterior() {
  difference() {
    translate([-5, -5, -25.01])
    cube(brick_dim + [4.99, 10, 25]);
    
    // Chamfer the front bottom.
    translate([-22, 0, -60])
    rotate([0, 50, 0])
    cube([100, 400, 100], center=true);
  }
}

module screw() {
  $fn = 20;
  
  translate([0, 0, -100])
  linear_extrude(100.01)
  circle(d=8.4);
  
  linear_extrude(3.3, scale=3.3/8.3)
  circle(d=8.4);
  
  linear_extrude(100.01)
  circle(d=3.7);
}

module shelf() {
  difference() {
    shelf_exterior();
    brick();
  
    for (y = [28, 84])
    translate([5, y, -9])
    rotate([0, 90, 0])
    screw();
  }
}

shelf();