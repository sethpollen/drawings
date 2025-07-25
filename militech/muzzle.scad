si_length = 90;
si_d = 39;
si_z = 26;
$fn = 90;

module silencer_2d() {
    intersection() {
    circle(d=si_d);
    square([si_d*0.8, 1000], center=true);
  }
}

module silencer() {
  hull() {
    translate([0, 0, si_z])
      linear_extrude(si_length)
        silencer_2d();
    translate([0, 0, si_z-1])
      linear_extrude(si_length+2)
        offset(-1)
          silencer_2d();
  }
  
  cylinder(h=si_length, d=si_d*0.65);
}

module muzzle() {
  translate([0, 19.2, 0])
    import("Muzzle.ipt.stl", 5);
}

difference() {
  union() {
    muzzle();
    silencer();
  }
  translate([0, 0, si_z + si_length - 25])
    cylinder(d=14, h=100);
  translate([0, 0, si_z + si_length - 0.5])
    cylinder(d1=14, d2=16.2, h=1.501);
}