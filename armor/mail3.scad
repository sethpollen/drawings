// This ring is closed using the 3D pen to inject a glob of PLA into a
// specially shaped cavity. I guess it's soldering? The joint seems to
// be quite strong and requires little finishing.

// https://www.mailleartisans.org/weaves/weavedisplay.php?key=6 defines the AR
// as ring ID over wire diameter.
gauge = 4.8;
id = 21;
od = id + gauge*2;
$fn = 80;

module octagon_2d(gauge) {
  intersection_for(a = [0, 45])
  rotate([0, 0, a])
  square(gauge, center=true);
}

module ring(split=false) {
  difference() {
    rotate_extrude()
    translate([id/2+gauge/2, 0])
    octagon_2d(gauge);
    
    if(split) {
      gap = 0.5;
      
      translate([15, 0, 0])
      cube([30, gap, 50], center=true);
      
      cavity();
    }
  }
}

module cavity_2d() {
  pit_d = gauge*0.7;
  bar_width = gauge*0.48;
  
  for (a = [-1, 1])
  scale([1, a])
  rotate([0, 0, 8])
  translate([id/2+gauge/2, 0])
  scale([1, 0.7])
  circle(d=pit_d, $fn=20);
  
  intersection() {
    difference() {
      $fn = 60;
      circle(d=id+gauge+bar_width);
      circle(d=id+gauge-bar_width);
    }

    translate([15, 0])
    square([30, 4], center=true);
  }
}

function cavity_layer_offsets(n) =
  n == 0 ? []
  : concat([
    n <= 3 ? (3-n)*-0.3
    : n >= 9 ? 0
    // Roughen the sides of the cavity, so that the injected PLA sticks
    // to the walls.
    : n % 2 == 0 ? -0.23
    : 0
  ], cavity_layer_offsets(n-1));

module cavity() {
  offsets = cavity_layer_offsets(gauge*5);
  
  for (a = [0:len(offsets)-1])
  translate([0, 0, -gauge/2 + 1 + a*0.4])
  linear_extrude(0.4001)
  offset(offsets[len(offsets)-1-a])
  cavity_2d();
}

module print() {
  ring(true);
}

print();
