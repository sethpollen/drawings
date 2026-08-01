disk_d = 25;
disk_h = 7.2;
roundoff_r = 2;
cutoff = 3.5;

module stone_2d() {
  $fn = 30;
  hull() {
    for (a = [-1, 1])
      translate([disk_d/2 - roundoff_r, a * (disk_h/2 - roundoff_r)])
        circle(roundoff_r);
    translate([1, 0])
      square([2, disk_h], center=true);
  }
}

module stone() {
  $fn = 110;
  intersection() {
    rotate([90, 0, 0])
      rotate_extrude(angle=360)
        stone_2d();
    translate([0, 0, cutoff])
      cube(disk_d, center=true);
  }
}

module capstone() {
  $fn = 110;
  translate([0, 0, cutoff - disk_d/2]) {
    difference() {
      cylinder(h=disk_d*0.6, d=disk_d*0.7);
      translate([0, 0, disk_d*0.4]) {
        cylinder(h=disk_d*0.6, d=disk_d*0.44);
        sphere(d=disk_d*0.44);
      }
      translate([0, 0, disk_d*0.44]) {
        translate([0, 0, 50])
          for (a = [0, 120, 240], b = 5.5*[-2, -1, 0, 1, 2])
            rotate([0, 0, a+b])
              cube([100, 1, 100], center=true);
      }
    }
  }
}

module dense_fill() {
  width = 40;
  height = disk_h*0.9;
  translate([0, 0, height/2 - disk_d/2 + cutoff])
    cube([width, width, height], center=true);
  
  translate([0, 0, disk_d*0.15])
    cube([2, width, 1.2], center=true);
}

module grid(r, c) {
  for (a = [1:r], b = [1:c])
    translate([(a-1)*(disk_d+1), (b-1)*(disk_h+1), 0])
      children();
}

capstone();
