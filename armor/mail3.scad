// This ring is closed using the 3D pen to inject a glob of PLA into a
// specially shaped cavity. I guess it's soldering? The joint seems to
// be quite strong and requires little finishing.

// https://www.mailleartisans.org/weaves/weavedisplay.php?key=6 defines the AR
// as ring ID over wire diameter.
gauge = 4.8;
id = 20.5;
od = id + gauge*2;
$fn = 80;

module octagon_2d() {
  intersection_for(a = [0, 45])
  rotate([0, 0, a])
  square(gauge, center=true);
}

// Cross-section of the ring exterior.
module ring_2d() {
  // Layers to remove from the middle, to make the ring thinner
  // while keeping its width. This makes it somewhat faster to
  // print and easier to snap together. It remains close enough
  // to a circular cross section not to disrupt the look of the
  // mail.
  chop = 0.4;
  
  for (a = [-1, 1])
  scale([1, a])
  translate([0, -chop/2])
  intersection() {
    octagon_2d();

    translate([-5, 0])
    square(10);
  }
}

module ring(split=false) {
  difference() {
    rotate_extrude()
    translate([id/2+gauge/2, 0])
    ring_2d();
    
    if(split) {
      gap = 0.5;
      
      translate([15, 0, 0])
      cube([30, gap, 50], center=true);
      
      cavity();
    }
  }
}

module cavity_2d(neck=true) {
  pit_d = gauge*0.7;
  bar_width = gauge * (neck ? 0.47 : 0.7);
  
  for (a = [-1, 1])
  scale([1, a])
  rotate([0, 0, 8.2])
  translate([id/2+gauge/2, 0])
  scale([1, 0.7])
  circle(d=pit_d, $fn=30);
  
  intersection() {
    difference() {
      $fn = 60;
      circle(d=id+gauge+bar_width);
      circle(d=id+gauge-bar_width);
    }

    scale([1, 2.8])
    polygon([[0, 0], [20, 1], [20, -1]]);
  }
}

module cavity() {
  // Roughen the sides of the cavity, so that the injected PLA sticks
  // to the walls.
  offsets = [0, 0, 0, -0.23, 0, -0.23, 0, -0.23, 0, -0.3, -0.6];
  
  for (a = [0:len(offsets)-1])
  translate([0, 0, -gauge/2 + 0.8 + a*0.4])
  linear_extrude(0.4001)
  offset(offsets[len(offsets)-1-a])
  cavity_2d(neck=a<8);
}

module print() {
  ring(true);
  
  translate([id*3.04, -0.8])
  ring(false);
  
  for (a = [1:6])
  rotate([0, 0, a*60])
  translate(id * [1.52, 0]) {
    rotate([0, 0, 180])
    ring(true);
    
    translate(id * [0.8, 1.3])
    ring(false);
  }
}

print();
