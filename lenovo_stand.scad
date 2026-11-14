width = 320;
laptop_depth = 242;
angle = 25;

extra_back = 15;
lip = 22;
lift = 10;

module profile_2d() {
  roundoff = 2.5;
  $fn = 20;

  offset(r=roundoff)
  offset(r=-roundoff)
  difference() {
    translate([-lip, -lift])
    square([lip + extra_back + laptop_depth * sin(angle), lift + laptop_depth * cos(angle) - 10]);
    
    rotate([0, 0, 90-angle])
    square(500);
  }

  // Don't round off the bottom corners.
  translate([-lip, -lift])
  square([lip + extra_back + laptop_depth * sin(angle), lift]);
}

module hollow_2d() {
  difference() {
    children();
    
    wall = 15;
    roundoff = 10;
    
    offset(r=roundoff)
    offset(-wall-roundoff)
    children();
  }
}

module piece() {
  front_cutout_width = width * 0.69;
  front_cutout_slope = 25;

  back_cutout_width = width * 0.7;
  back_cutout_slope = 70;
  
  difference() {
    linear_extrude(width)
    hollow_2d()
    profile_2d();
    
    // Front cutout, for the front protrusion on the lid.
    translate([0, 0, (width-front_cutout_width)/2])
    hull() {
      linear_extrude(front_cutout_width)
      translate([-lip-100, 0])
      square(200, center=true);
      
      translate([0, 0, front_cutout_slope])
      linear_extrude(front_cutout_width - 2*front_cutout_slope)
      translate([-100, 0])
      square(200, center=true);
    }
    
    // Back cutout, for fingers.
    translate([0, 0, (width-back_cutout_width)/2])
    hull() {
      linear_extrude(back_cutout_width)
      translate([0, 200 + laptop_depth * cos(angle)])
      square(400, center=true);
      
      translate([0, 0, back_cutout_slope])
      linear_extrude(back_cutout_width - 2*back_cutout_slope)
      translate([0, 200 + laptop_depth * cos(angle) - 80])
      square(400, center=true);
    }
  }
}

render()
rotate([90, 0])
piece();