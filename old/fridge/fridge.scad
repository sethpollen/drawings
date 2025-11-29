module fridge() {
  color("#7b9fb3") {
    difference() {
      import("Retro_Fridge.stl", 5);
      
      translate([5, -8.215, 0])
      cube([10, 10, 7]);
    }
  }
}

module cjp() {
  color("white")
  translate([6.4, 5.45, 4])
  rotate([90, 0, 0])
  linear_extrude(4)
  scale([1.4, 1] * 0.11)
  offset(delta=0.5)
  text("C  J  P", font="Aegyptus");
}

module smeg() {
  color("white")
  translate([1.6, 5.45, 29])
  rotate([90, 0, 0])
  linear_extrude(4)
  scale([1.4, 1] * 0.17)
  offset(delta=0.5)
  text("S   M   E   G", font="Aegyptus");
}

module longevity() {
  color("white")
  translate([14.25, 8.7, 31.5])
  rotate([0, 90, 0])
  linear_extrude(4)
  scale([1, 1] * 0.4)
  text("innovation", font="Alexander");
}

module reliability() {
  color("white")
  translate([3.75, 11.5, 31.5])
  rotate([0, 90, 180])
  linear_extrude(4)
  scale([1, 1] * 0.45)
  text("reliability", font="Alexander");
}

smeg();
fridge();
longevity();
reliability();
cjp();