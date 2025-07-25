translate([-87, -20, 9.999])
  linear_extrude(10)
    text("Jerry", 50, "Bookman");
    
color("red")
  hull()
    for (a = [-1, 1], b = [-1, 1])
      scale([a, b, 1])
        translate([85, 25, 0])
          cylinder(10, 20, 20);
    
$fa = 5;