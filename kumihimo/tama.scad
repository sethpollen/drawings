length = 41;
diam = 35;
roundoff = 3.8;
pennies = 22;

// Nominal values.
penny_thickness = 1.5;
penny_diam = 19.05;

penny_stack_thickness = penny_thickness * pennies;

module profile_2d() {
  for (a = [-1, 1])
  scale([1, a])
  translate([0, length/2 - roundoff])
  hull() {
    translate([diam/2 - roundoff, 0])
    intersection() {
      // Flatten the top and bottom, to avoid shallow overhangs.
      flatten = 0.24;
      
      translate([0, flatten])
      circle(r=roundoff+flatten+0.1, $fn=25);
      
      translate([-10, roundoff-20])
      square(20);
    }
    
    translate([0, -roundoff])
    square(roundoff*2);
  }
  
  middle_length = length - roundoff*4;
  
  difference() {
    translate([0, -middle_length/2])
    square([diam/2, middle_length + 0.1]);
    
    translate([length + diam/2 - 5, 0])
    circle(r=length+1, $fn=100);
  }
}

module whole() {
  translate([0, 0, length/2])
  difference() {
    rotate_extrude($fn=50)
    profile_2d();
    
    translate([0, 0, -penny_stack_thickness/2])
    cylinder(d=penny_diam+0.4, h=penny_stack_thickness, $fn=30);
  }
}

module cut(extra_ring_diam=0) {
  linear_extrude(length-roundoff*2-0.1)
  square(diam+1, center=true);
  
  // Ring that intrudes into the cap.
  linear_extrude(length/2 + penny_stack_thickness/2)
  circle(d=penny_diam+3.9+extra_ring_diam, $fn=30);
}

module bottom() {
  intersection() {
    whole();
    cut();
  }
}

module top() {
  scale([1, 1, -1])
  translate([0, 0, -length])
  difference() {
    whole();
    cut(extra_ring_diam=0.4);
  }
}

module print() {
  render() {
    bottom();

    translate([diam+2, 0])
    top();
  }
}

print();