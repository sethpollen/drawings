layer = 0.2;
eps = 0.001;
$fn = 20;

module base() {
  // Get it to the center.
  translate([25.8, -90])
    import("fixed/base.stl");
}

module bottom_layer() {
  projection(cut = true)
    translate([0, 0, -layer/2])
      base();
}

module base_hole_2d() {
  difference() {
    square([20, 10], center=true);
    bottom_layer();
  }
}

module base_modified() {
  difference() {
    base();

    // Widen the hole slightly.
    translate([0, 0, -eps])
      linear_extrude(10)
        offset(0.1)
          base_hole_2d();
    
    // Widen the top of the hole even more.
    for (x = [-0.3, 0.3])
      translate([x, 0, 3.2])
        linear_extrude(10)
          offset(0.1)
            base_hole_2d();

    // Chop off the bottom layer.
    translate([0, 0, layer - 500])
      cube(1000, center=true);
  }
  
  // Add a new bottom layer, inset slightly.
  linear_extrude(layer)
    offset(-0.2)
      bottom_layer();
}

