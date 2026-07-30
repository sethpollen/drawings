length = 41;
diam = 35;
roundoff = 3.8;
pennies = 22;

// Nominal values.
penny_thickness = 1.5;
penny_diam = 19.05;

penny_stack_thickness = penny_thickness * pennies;
cap_thickness = length/2 - penny_stack_thickness/2;
cap_diam = diam - roundoff*2 - 1.4;

module profile_2d() {
  for (a = [-1, 1])
  scale([1, a])
  translate([0, length/2 - roundoff])
  hull() {
    translate([diam/2 - roundoff, 0])
    circle(r=roundoff, $fn=25);
    
    translate([0, -roundoff])
    square(roundoff*2);
  }
  
  middle_length = length - roundoff*4;
  
  difference() {
    translate([0, -middle_length/2])
    square([diam/2, middle_length + 0.1]);
    
    depression_radius = length + 5;
    
    translate([depression_radius+diam/2-5.5, 0])
    circle(r=depression_radius, $fn=100);
  }
}

module tama() {
  translate([0, 0, length/2])
  difference() {
    rotate_extrude($fn=50)
    profile_2d();
    
    translate([0, 0, -penny_stack_thickness/2])
    cylinder(d=penny_diam+0.4, h=100, $fn=30);
    
    translate([0, 0, penny_stack_thickness/2])
    cylinder(d=cap_diam+0.4, h=cap_thickness, $fn=40);
  }
}

module cap() {
  cylinder(d=cap_diam, h=cap_thickness, $fn=40);
}

module together() {
  tama();
  translate([diam, 0]) cap();
}

together();

