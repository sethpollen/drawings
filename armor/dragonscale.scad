module bevel_extrude(h, i=0) {
  face = h/(1+sqrt(2));
  bevel = (h-face)/2;
  offs = i*0.2;
  
  if (i == 0) {
    translate([0, 0, -h/2])
    linear_extrude(h)
    offset(-bevel)
    children();
  }

  if (offs < bevel) {
    translate([0, 0, bevel-offs-h/2])
    linear_extrude(h - 2*(bevel-offs))
    offset(-offs)
    children();
    
    // Recurse.
    bevel_extrude(h, i+1)
    children();
  }
}

gauge = 3.6;

module link(od) {
  $fn = od;
  
  difference() {
    bevel_extrude(gauge)
    difference() {
      union() {
        circle(d=od);
        
        // Nubs to provide extra material for welding.
        translate([gauge/2-od/2, 0, 0])
        square([gauge*1.2, 3], center=true);
      }
      circle(d=od-2*gauge);
    }
    
    translate([-od/2, 0, 0])
    cube([od, 0.6, od], center=true);
  }
}

module main_link() {
  link(26.3);
}

module border_link() {
  link(23);
}

module hole_2d(dim) {
  $fn = 30;

  scale(dim)
  circle(d=1);
}

plate_od = 50;

module holes_2d() {
  for (a = [-1, 1], b = [-1, 1])
  scale([a, b])
  translate([7, plate_od/2-9.1])
  hole_2d([6.6, 10.3]);
}

half_plate_height = 32;

module plate(ridge=true, half=false) {
  bevel_extrude(gauge)
  difference() {
    circle(d=plate_od);
    
    // Slightly cut off the sides.
    for (a = [-1, 1])
    translate([0, a*(50+plate_od/2-1.5)])
    square(100, center=true);
    
    // Holes.
    holes_2d();
    
    // A half-plate for housing magnets.
    if(half) {
      translate([0, plate_od/2+7.8])
      square([plate_od, plate_od], center=true);

      for (a = [-1, 1])
      scale([a, 1]) {
        translate([half_plate_height/2, 7.8])
        rotate([0, 0, 45])
        square(1.7, center=true);
        
        translate([(plate_od+half_plate_height)/2, 0])
        square([plate_od, plate_od], center=true);
      }
    }
  }
  
  if(ridge)
  translate([6, 0, gauge/2-0.001])
  linear_extrude(gauge*0.6, scale=0)
  scale(plate_od * [0.62, 0.35])
  rotate([0, 0, 45])
  square(1/sqrt(2), center=true);
}

module shoulder_plate() {
  difference() {
    union() {
      bevel_extrude(gauge)
      difference() {
        offset(gauge*0.86)
        hull()
        holes_2d();
        
        holes_2d();
      }
      
      translate([0, 0, gauge/2-0.001])
      linear_extrude(gauge*0.6, scale=0)
      scale(plate_od * [0.47, 0.31])
      rotate([0, 0, 45])
      square(1/sqrt(2), center=true);
    }
  
    translate([plate_od*0.66, 0, -5])
    cylinder($fn=60, h=10, d=plate_od*0.95);
  }
}

magnet_hole_depth = 2.2;
magnet_hole_id = 10.4;
magnet_hole_floor = 0.6;

cover_plate_dims = [28, 12.5];
cover_plate_thickness = 1;
cover_plate_roundoff = 3;

module stud_2d() {
  $fn = 20;

  offset(0.7)
  offset(-0.7)
  square([4.3, 10], center=true);
}

module magnet_plate(tab=false) {
  $fn = 60;
  magnet_hole_slack = 0.4;

  difference() {
    union() {
      plate(ridge=false, half=true);
      
      if(tab)
      translate([0, 5.5, 0.4])
      rotate([135, 0, 0])
      intersection() {
        tab_length = 6;

        bevel_extrude(gauge)
        square([half_plate_height, tab_length*2], center=true);
        
        translate([0, -tab_length])
        cube([half_plate_height, tab_length*2, gauge], center=true);
      }
    }
    
    for (a = [-1, 1])
    scale([a, 1, 1])    
    translate([8.5, 0, gauge/2-5-magnet_hole_floor])
    cylinder(d=magnet_hole_slack+9.5+0.5*a, h=5);
    
    translate([0, 0, -5])
    linear_extrude(10)
    offset(0.2)
    stud_2d();
    
    translate([0, 0, cover_plate_thickness-5-gauge/2])
    linear_extrude(5)
    offset(cover_plate_roundoff)
    offset(-cover_plate_roundoff)
    square(cover_plate_dims, center=true);
  }
}

module magnet_plate_cover() {
  $fn = 60;

  linear_extrude(cover_plate_thickness-0.2)
  offset(cover_plate_roundoff-0.35)
  offset(-cover_plate_roundoff)
  square(cover_plate_dims, center=true);
}

module magnet_plate_stud() {
  hull() {
    linear_extrude(5)
    offset(-0.8)
    stud_2d();
    
    translate([-0, 0, 0.7])
    linear_extrude(3.6)
    offset(-0.25)
    stud_2d();
  }
}

module print_magnet_plates() {
  magnet_plate(tab=true);
  
  translate([34, 0])
  magnet_plate();
}

magnet_plate_stud();
