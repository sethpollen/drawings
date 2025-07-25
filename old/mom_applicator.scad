eps = 0.001;

rod_diameter = 6;
rod_length = 70;
tip_thickness = 0.8;

module octagon(diameter) {
  intersection()
  {
    square(diameter, center=true);

    rotate([0, 0, 45])
    square(diameter, center=true);
  }
}

module rod() {
  difference()
  {
    rotate([0, 90, 0])
    linear_extrude(rod_length)
    octagon(rod_diameter);

    for (a = [-1, 1])
    scale([1, a, 1])
    rotate([0, 0, 10])
    translate([0, tip_thickness/2, -10])
    cube(20);
  
    rotate([90, 0, 0])
    for (a = [-1, 1])
    scale([1, a, 1])
    rotate([0, 0, 45])
    translate([0, rod_diameter*0.28, -10])
    cube(20);
  }
}

handle_diameter = 18;

module handle() {
  $fn = 40;
  
  difference()
  {  
    hull()
    {
      linear_extrude(eps)
      octagon(handle_diameter-6);
   
      translate([0, 0, 3])
      linear_extrude(eps)
      octagon(handle_diameter);
   
      translate([0, 0, 50])
      linear_extrude(eps)
      octagon(handle_diameter);
   
      translate([0, 0, 53])
      linear_extrude(eps)
      octagon(handle_diameter-6);
    }
  
    translate([0, 0, 40])
    rotate_extrude()
    translate([17.5, 0])
    circle(10);
    
    translate([0, 0, 43+2*eps])
    linear_extrude(10)
    octagon(rod_diameter + 0.2);
  }
}

handle();
