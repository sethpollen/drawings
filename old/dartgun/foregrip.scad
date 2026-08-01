include <common.scad>
include <barrel.scad>
include <post.scad>

// TODO:
slider_width = barrel_width + 2*enclosure_wall;
slider_height = barrel_height + 2*enclosure_wall;

grip_length = 53;
grip_height = 85;
grip_circle_diameter = slider_width*0.9;

// 3/8" aluminum or steel rod.
roller_diameter = 0.375 * 25.4;
roller_cavity_diameter = roller_diameter + 0.4;

// How far into the barrel does the roller intrude? One quarter of
// its diameter.
roller_intrusion = roller_diameter / 4;
roller_x = -7;

module handle() {
  difference() {
    intersection() {
      hull() {
        for (y = (grip_length/2 - grip_circle_diameter/2) * [-1, 1]) {
          translate([0, y, 0]) {
            linear_extrude(eps)
              circle(grip_circle_diameter/2-2);
            translate([0, 0, 2])
              linear_extrude(eps)
                circle(grip_circle_diameter/2);
            translate([0, 0, grip_height])
              linear_extrude(eps)
                circle(grip_circle_diameter/2);
          }
        }
      }
        
      translate([-slider_width/2 + 4, -100, 0])
        cube([slider_width/2 - 4, 200, grip_height + grip_circle_diameter/2]);
    }
  }
}

// TODO: make this wider. 10mm?
button_width = 8;
button_cavity_width = button_width + extra_loose;

button_pivot_od = 7;
button_pivot_y = -grip_height + enclosure_wall + 22;

button_stop_offset = [-7, 42];
button_stop_od = 6;

button_front_height = 25;
button_ring_thickness = 8;
button_ring_od = button_pivot_od + button_ring_thickness;
button_rod_length = -button_pivot_y + enclosure_wall - roller_cavity_diameter;

pull_angle = 9.3;

module foregrip() {
  difference() {
    intersection() {
      union() {
        translate([0, slider_height/2, 0])
          rotate([0, 90, 90])
            slider(grip_length, slot=100, zip_channels=[6, grip_length-6], zip_orientation=false);
        
        translate([0, -grip_height, 0])
          rotate([0, -90, -90])
            handle();
      }
      
      translate([0, 0, -100])
        cube(200, center=true);
    }
    
    // Interior cavity for the button mechanism.
    translate([0, enclosure_wall - grip_height/2 + eps, 0])
      cube([grip_length - 12, grip_height, button_cavity_width], center=true);
        
    // Vertical guide for the roller. Slightly recessed so that the roller stays in
    // place even without the barrel above it.
    translate([roller_x, 0, -barrel_width/2 - 2.2])
      linear_extrude(slider_width)
        hull()
          for (y = [0, roller_intrusion])
            translate([0, enclosure_wall - roller_cavity_diameter/2 + y])
              circle(d=roller_cavity_diameter);
          
    // Button pivot root.
    translate([roller_x, button_pivot_y])
      translate([0, 0, -button_cavity_width/2 - 3])
        cylinder(h=button_cavity_width/2, d=button_pivot_od-3.5);
          
    // Button stop root.
    translate([roller_x, button_pivot_y] + button_stop_offset)
      translate([0, 0, -button_cavity_width/2 - 3])
        cylinder(h=button_cavity_width/2, d=button_stop_od-3.5);
          
    // Opening in front for the button.
    translate([-grip_length, -34.5, -button_cavity_width/2])
      cube([grip_length, 34, button_cavity_width]);
          
    // Rubber band post holes.
    translate([0, 0, -button_cavity_width/2 - post_hole_depth])
      linear_extrude(post_hole_depth + eps)
        for (xy = [
          [14, -5],
          [14, -15],
          [14, -25],
          [14, -35],
          [14, -45],
        ])
          translate(xy)
            square(post_hole_width, center=true);
  }
  
  // Button pivot.
  translate([roller_x, button_pivot_y]) {
    translate([0, 0, -button_cavity_width/2]) {
      difference() {
        cylinder(h=button_cavity_width/2, d=button_pivot_od);
        translate([0, 0, -eps])
          cylinder(h=button_cavity_width/2+2*eps, d=button_pivot_od-3.5);
      }
    }
  }
  
  // Button stop.
  translate([roller_x, button_pivot_y] + button_stop_offset) {
    translate([0, 0, -button_cavity_width/2]) {
      difference() {
        cylinder(h=button_cavity_width/2, d=button_stop_od);
        translate([0, 0, -eps])
          cylinder(h=button_cavity_width/2+2*eps, d=button_stop_od-3.5);
      }
    }
  }
  
  // Reinforce the barrel lug; it's going to be under pressure
  // when the roller is engaged.
  translate([-grip_length/2, enclosure_wall + barrel_height/2, -slider_width/2 + enclosure_wall - 1])
    cube([grip_length, barrel_height/2 + 1, barrel_lug_intrusion + 1]);
  
  // Temporary connectors to bracket.
  // TODO: remove this
  for (y = [enclosure_wall - link_height - main_diameter/2, slider_height + link_height - enclosure_wall + main_diameter/2]) {
    translate([grip_length/2 + main_diameter/2 + 0.2, y, -5]) {
      difference() {
        union() {
          hull() {
            cylinder(h=5, d=main_diameter);
            translate([-main_diameter/2-5, 0])
              linear_extrude(5)
                square([eps, main_diameter], center=true);
          }
          
          // Connector on top.
          if (y > 0) {
            hull() {
              translate([-main_diameter/2-5, 0])
                linear_extrude(5)
                  square([9, main_diameter], center=true);
              translate([-15.5 - main_diameter/2, -main_diameter-0.7])
                linear_extrude(5)
                  square([30, eps], center=true);
            }
          }
        }
        
        // Hole.
        translate([0, 0, -1])
          cylinder(h=10, d=pin_hole_diameter);
      }
    }
  }
}

module button_2d() {  
  difference() {
    union() {
      // Ring around the pivot.
      circle(d=button_ring_od);
      
      // Main rod.
      translate([0, button_rod_length/2 - 1])
        square([button_ring_od, button_rod_length - 2], center=true);
      
      // Side rod for rubber band.
      side_rod_length = 21.8;
      side_rod_width = button_ring_od*0.7;
      translate([0, -(button_ring_od - side_rod_width)/2]) {
        translate([side_rod_length/2, 0])
          square([side_rod_length, side_rod_width], center=true);
        translate([side_rod_length, 0])
          circle(d=side_rod_width);
      }
      
      // Cam surface.
      slope = 0.51;
      polygon([
        [0, 0],
        each [for (a = [7 : -0.5 : -2.5]) (button_rod_length + roller_intrusion) * [sin(a), cos(a)]],
        each [for (a = [-2.5 : -0.5 : -7.5]) (button_rod_length + roller_intrusion + slope*(a+2.5)) * [sin(a), cos(a)]],
        each [for (a = [-7.5 : -0.5 : -15]) (button_rod_length + roller_intrusion - slope*5) * [sin(a), cos(a)]],
      ]);
        
      // Front protrusion.
      intersection() {
        outer_radius = button_rod_length + 3;
        difference() {
          $fn = 100;
          
          circle(outer_radius);
          circle(outer_radius - button_front_height);
          
          // Round off the front.
          rotate([0, 0, 10])
            translate([-42, 0])
              square([20, 80]);
        }
        
        a1 = -15;
        a2 = -37;
        chamfer_a = 2;
        polygon([
          [0, 0],
          (outer_radius-1) * [sin(a1+1), cos(a1+1)],
          (outer_radius) * [sin(a1+eps), cos(a1+eps)],
          (outer_radius+10) * [sin(a1), cos(a1)],
          (outer_radius+10) * [sin(a2), cos(a2)],
        ]);
      }
    }
    
    // Hole for pivot.
    circle(d=button_pivot_od+loose);
    
    // Arc for button stop pin.
    for (a = [0 : 0.5 : pull_angle])
      rotate([0, 0, a])
        translate(button_stop_offset)
          circle(d=button_stop_od + extra_loose);
  }
}

module button() {
  difference() {
    union() {
      chamfer_layers = 4;
      
      for (a = [-1, 1])
        scale([1, 1, a])
          translate([0, 0, -button_width/2])
            for (i = [1:chamfer_layers])
              translate([0, 0, (4-i)*0.2])
                linear_extrude(0.2)
                  offset(-i*0.2)
                    button_2d();
      
      translate([0, 0, 0.2*chamfer_layers - button_width/2])
        linear_extrude(button_width-0.4*chamfer_layers)
          button_2d();
    }
    
    difference() {
      hull() {
        translate([14, -10, -1])
          cube(20);
        translate([9, -10, button_width/2])
          cube(20);
      }
      
      translate([23, -2, -1])
        cylinder(h=button_width/2+1, r1=3, r2=4.5);
    }
    
    translate([23, -2, -2.6])
      cylinder(h=button_width, r=1);
  }
}

module preview(pulled=false) {
  foregrip();
  
  color("lightblue")
    translate([roller_x, button_pivot_y, 0])
      rotate([0, 0, pulled ? -pull_angle : 0])
        button();
  
  color("pink")
    translate([roller_x, enclosure_wall - roller_diameter/2 + (pulled ? 0 : roller_intrusion), -10])
      cylinder(h=10, d=roller_diameter);
}

preview(false);
