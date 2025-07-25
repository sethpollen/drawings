use <skull.scad>

layer = 0.2;
eps = 0.001;
chip_height = 5;

// Child is the 2d shape.
module blank_chip(height, chamfer=1) {
  // Bottom 2 layers: Extra chamfer for elephant foot.
  linear_extrude(layer)
    offset(-chamfer - 0.5*layer)
      children();
  translate([0, 0, layer])
    linear_extrude(layer)
      offset(-chamfer + 1.5*layer)
        children();

  for (z = [2*layer : layer : chamfer - layer])
    translate([0, 0, z])
      linear_extrude(layer)
        offset(-chamfer + layer + z)
          children();

  translate([0, 0, chamfer])
    linear_extrude(height - 2*chamfer)
      children();

  for (z = [0 : layer : chamfer - layer])
    translate([0, 0, height - chamfer + z])
      linear_extrude(layer)
        offset(-z)
          children();
}

blip_diameter = 27.2;
blip_height = chip_height - 0.6;
blip_rail_height = 1.4;
blip_rail_width = 1.4;

module blip_exterior_2d(height, diameter) {
  flat = 0.8;
  hull() {
    translate([0, -height/2])
      square([eps, height]);
    translate([diameter/2 - height/2, 0])
      for (y = flat * [-1, 1])
        translate([0, y])
          circle(d=height-flat*2, $fn = 30);
  }
}

blip_rail_cavity_offs = 0.4;

module blip_rail_2d(cavity=false) {
  offset(cavity ? blip_rail_cavity_offs : 0) {
    hull() {
      translate([-blip_rail_width/2, 0])
        square([blip_rail_width, eps]);
      translate([0, blip_rail_height - blip_rail_width/2])
        circle(d=blip_rail_width, $fn = 30);
    }
  }
  
  // Prevent elephant foot.
  if (cavity)
    translate([-blip_rail_width/2 - 0.55, 0])
      square([blip_rail_width + 1.1, 0.2]);
}

module blip_rail(radius, cavity=false) {
  rotate_extrude($fn = 60)
    translate([radius, 0])
      blip_rail_2d(cavity=cavity);
}

module blip(count) {
  outer_rail_radius = 9.4;
  rail_spacing = 4;

  // Top always has 1 rail.
  translate([0, 0, blip_height/2])
    blip_rail(outer_rail_radius, 0);
  
  difference() {
    rotate_extrude($fn = 60)
      blip_exterior_2d(blip_height, blip_diameter);

    translate([0, 0, -blip_height/2-eps]) {
      // Bottom always has outer rail.
      blip_rail(outer_rail_radius, cavity=true);
      
      if (count >= 2)
        blip_rail(outer_rail_radius - rail_spacing, cavity=true);
      
      if (count >= 3) {
        blip_rail(outer_rail_radius - 2*rail_spacing, cavity=true);
        cylinder(h=blip_rail_height + blip_rail_cavity_offs, r=1.28, $fn=30);
      }
    }
    
    // Etch radar on top.
    for (a = [0:14]) {
      rotate([0, 0, 7*a]) {
        translate([-0, 0, blip_height/2 - 1.4 + a*0.1]) {
          hull() {
            translate([-0.5, outer_rail_radius-0.8, 0])
              cube([1.1, eps, 10]);
            cylinder(d=1, h=10, $fn=16);
          }
        }
      }
    }
  }
}

module bullet_2d() {
  width = 3;
  length = 9;
  gap = 0.8;
  $fn = 30;
  
  translate([3 - length/2, 0]) {
    scale([2, 1]) {
      intersection() {
        circle(d=width);
        translate([-width/2, 0])
          square(width, center=true);
      }
    }
    
    translate([gap, -width/2])
      square([length - width - gap, width]);
  }
}

module fist_2d() { 
  translate([-2.8, -3.2]) {
    for (a = [0:3])
      translate([0, 1.8*a])
        square([2.2, 1]);
    translate([2.8, 0])
      square([3, 6.4]);
    translate([2, 7.1])
      square([3, 1]);
  }
}

module circular_recess(diameter) {
  recess_depth = 1.4;
  
  difference() {
    rotate_extrude($fn=32) {
      hull() {
        translate([0, -recess_depth])
          square(2*recess_depth);
        translate([diameter - recess_depth, 0])
          circle(recess_depth);
      }
    }
    
    // Crosshair notches.
    for (a = [0, 90, 180, 270])
      rotate([-30, 0, a+45])
        translate([0, 3.2 + diameter, 0])
          cube([1.8, 10, 10], center=true);
  }
}

module status_chip() {
  height = chip_height;
  
  difference() {
    blank_chip(height, 1)
      circle(d=16, $fn=80);

    translate([0, 0, height])
      circular_recess(6.4);
    
    for (a = [0:4])
      translate([0, 0, 1.8 - a*0.2])
        linear_extrude(height)
          offset(-a*0.2)
            children();
  }
}

module overwatch() {
  status_chip()
    bullet_2d();
}

module guard() {
  status_chip()
    fist_2d();
}

module command_chip(skull=false) {
  diameter = 30;
  outer_rail_radius = 10.7;
  rail_spacing = 4;
  height = blip_height;

  // Top always has 1 rail.
  translate([0, 0, height])
    blip_rail(outer_rail_radius, 0);
  
  translate([0, 0, height/2]) {
    difference() {
      rotate_extrude($fn = 60)
        blip_exterior_2d(height, diameter);

      translate([0, 0, -height/2-eps]) {
        // Bottom always has outer rail.
        blip_rail(outer_rail_radius, cavity=true);
      
        if (skull)
          skull_cavity();
      }
    }
  }
}

command_chip(true);
