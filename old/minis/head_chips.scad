include <common.scad>
use <head.scad>

// Utilities for 1mm-deep graphic or text engravings. 
// Note that dice.scad has its own engraving library
// for dice.

// The clear area in the middle of chip is about 9.6mm 
// on a side.

module sword_2(circ=false) {  
  // Blade and hilt.
  polygon([
    [0.5, -5.5],
    [0.5, 5.5],
    [0, 7.5],
    [-0.5, 5.5],
    [-0.5, -5.5],
  ]);
  
  if (circ) {
    // Rounded pommel.
    translate([0, -5.5, 0]) 
      circle(r = 0.7);
  } else {
    // Square pommel.
    translate([0, -5.5, 0]) 
      rotate([0, 0, 45])
        square(1.3, center=true);
  }
  
  // Crossguard.
  polygon([
    [-2, -2],
    [-2, -3],
    [2, -3],
    [2, -2],
  ]);
  for (a = [-1, 1])
    scale([a, 1, 1])
      translate([2, -2.5, 0])
        circle(r=0.5);
  
  if (circ) {
    // A magic circle around the sword.
    difference() {
      circle(4.5);
      circle(4);
    }
  }
}

module helm_2(circ=false) {
  // Center the whole thing.
  translate([0, circ ? 0 : 0.25, 0]) {
    difference() {
      if (circ) {
        circle(4);
      } else {
        translate([0, -0.5, 0])
          square([8, 7], center=true);
      }
      intersection() {
        if (circ) {
          circle(3.3);
        } else {
          square(6.6, center=true);
        }
        translate([0, 1, 0])
          square([10, 1.5], center=true);
      }
      translate([0, -3, 0])
        square([2, 8], center=true);
    }
  }
}

// First child is the chip. Remaining children are
// the 2-D engravings.
module engrave_chip() {
  if ($flat) {    
    if ($children > 1) {
      children([1:$children-1]);
    }

    // Include the stud pattern as a cue for heavy/light.
    offset(r=-0.2)
      projection(cut=true)
        translate([0, 0, -3.501])
          children(0);
    
    // Add a border.
    difference() {
      square(19, center=true);
      square(17, center=true);
    }

  } else {
    difference() {
      children(0);
      if ($children > 1)
        translate([0, 0, 2.5+eps])
          linear_extrude(1)
            children([1:$children-1]);
    }
  }
}

module magic_sword() {
  engrave_chip() {
    heavy_weapon();
    sword_2(circ=true);
  }
}

module iron_sword() {
  engrave_chip() {
    light_weapon();
    sword_2();
  }
}

module magic_helm() {
  engrave_chip() {
    heavy_armor();
    helm_2(circ=true);
  }
}

module iron_helm() {
  engrave_chip() {
    light_armor();
    helm_2(circ=false);
  }
}

module iron_shield() {
  engrave_chip() {
    light_armor();

    difference() {
      polygon([
        [-4, -3],
        [-4, 3.5],
        [4, 3.5],
        [4, -3],
        [0, -5],
      ]);
      
      // Chevrons.
      for (a = [-1, 1])
        translate([0, a, 0])
          polygon([
            [-3, -1.5],
            [-3, 0],
            [0, 1],
            [3, 0],
            [3, -1.5],
            [0, -0.5],
          ]);
    }
  }
}

module iron_mail() {
  engrave_chip() {
    light_armor();

    for (a = [-2, 0, 2], b = [-1, 1]) {
      translate(2*[a, b, 0]) {
        rotate([0, 0, 45]) {
          difference() {
            square(4, center=true);
            square(2.5, center=true);
          }
        }
      }
    }
  }
}

module wall() {
  engrave_chip() {
    light_armor();

    translate([3.5, 0]) square([5, 1.5], center=true);
    translate([-3.5, 0]) square([5, 1.5], center=true);
    translate([0, 3]) square([5, 1.5], center=true);
    translate([0, -3]) square([5, 1.5], center=true);
  }
}

module fire() {
  engrave_chip() {
    heavy_armor();

    difference() {
      union() {
        circle(r=3);
        translate([0.3, 3, 0]) {
          circle(r=1);
          polygon([[-0.9, 0.4], [0.9, 0.4], [0, 3]]);
        }
      }
      // Cut-out flames.
      translate([-1, -0.5, 0]) {
        circle(r=1);
        polygon([[-0.9, 0.4], [0.9, 0.4], [0, 5]]);
      }
      translate([1.5, 0.5, 0]) {
        circle(r=1);
        polygon([[-0.9, 0.4], [0.9, 0.4], [0, 3]]);
      }
    }
    
    // A ring around everything.
    difference() {
      circle(4.5);
      circle(4);
      offset(0.7)
        translate([0.3, 3, 0])
          polygon([[-0.9, 0.4], [0.9, 0.4], [0, 3]]);
    }
  }
}

module jump_back() {
  engrave_chip() {
    heavy_armor();

    translate([0, 4.6, 0])
      projection()
        rotate([50, 0, 0])
          rotate([0, 0, -20])
            linear_extrude(12, twist=3*360-40)
              translate([2.7, 0, 0])
                circle(0.4);
  }
}

module ender_pearl() {
  engrave_chip() {
    heavy_weapon();
    
    difference() {
      circle(4.5);
      circle(4);
    }
    scale([1.1, 0.6, 1]) {
      difference() {
        circle(3);
        circle(2.2);
      }
    }
  }
}

module health_potion() {
  engrave_chip() {
    heavy_weapon();
    
    difference() {
      square([8, 8], center=true);
      square([7, 2.4], center=true);
      square([2.4, 7], center=true);
      for (a = [-1, 1], b = [-1, 1])
        scale([a, b, 1])
          translate([6.9, 6.9, 0])
            rotate([0, 0, 45])
              square(10, center=true);
    }
  }
}

module hammer() {
  engrave_chip() {
    heavy_weapon();
    
    rotate([0, 0, 10]) {
      translate([0, -1, 0]) square([1.5, 8], center=true);
      translate([0, 2, 0]) square([6, 2], center=true);
      translate([-2.5, 2, 0]) square([1, 3], center=true);
    }
  }
}

module trident() {
  engrave_chip() {
    light_weapon();
    
    translate([0, -2, 0]) square([1, 9], center=true);
    translate([0, 0.5, 0]) {
      difference() {
        circle(3);
        circle(2);
        translate([0, 2, 0]) square([10, 4], center=true);
      }
    }
    for (a = [0:1])
      translate([5*(a-0.5), 1.5, 0])
        square([1, 2], center=true);
    for (a = [0:2])
      translate([2.5*(a-1), 2.5, 0])
        polygon([
          [-1, 0],
          [0, 2],
          [1, 0],
        ]);
  }
}

module lightning() {
  engrave_chip() {
    light_weapon();
    
    translate([0, -1, 0]) {
      for (a = [0:2])
        translate([a-2, -a*3, 0])
          polygon([
            [0, 0],
            [0, 6],
            [3-a/2, 6],
          ]);
      for (a = [0:1])
        translate([a-1.5, -a*3+1.5, 0])
          polygon([
            [-0.5, -1.5],
            [-0.5, 1.5],
            [0.5, 1.5],
            [0.5, -1]
          ]);
    }
  }
}

module wind() {
  engrave_chip() {
    light_weapon();
    
    for (a = [-1, 1]) {
      scale([1, a, 1]) {
        translate([0, 3.3, 0]) {
          hull() {
            translate([0, -2.5, 0]) {
              translate([a, 0, 0]) circle(0.3);
              translate([6, 0, 0]) circle(0.3);
            }
          }
          
          translate([a, 0, 0])
            // Give the coil some actual width.
            offset(r=0.3)
              // Project the coil to make a spiral.
              projection()
                difference()
                  // A tapered coil in 3D.
                  linear_extrude(10, scale=0.4, twist=400)
                    translate([0, -2.5, 0])
                      // This coil is very narrow. We just need
                      // a line to feed to offset().
                      circle(0.01);
        }
      }
    }
  }
}

module blank_weapon() {
  engrave_chip() {
    light_weapon();
  }
}

module blank_armor() {
  engrave_chip() {
    light_armor();
  }
}

if (printout == 1) {
  arrange(25) {
    // Heavy weapons.
    magic_sword();
    ender_pearl();
    hammer();
    health_potion();
   
    // Light weapons.
    iron_sword();
    trident();
    lightning();
    wind();

    // Heavy armor.
    magic_helm();
    fire();
    jump_back();

    // Light armor.
    iron_helm();
    iron_shield();
    iron_mail();
    wall();
  }
}

if (printout == 2) {
  arrange(25) {
    blank_weapon();
    blank_weapon();
    blank_weapon();
    blank_weapon();
    blank_weapon();
    blank_weapon();
    blank_weapon();
    blank_weapon();
    blank_weapon();
    blank_weapon();
  }
}

if (printout == 3) {
  arrange(25) {
    blank_armor();
    blank_armor();
    blank_armor();
    blank_armor();
    blank_armor();
    blank_armor();
    blank_armor();
    blank_armor();
    blank_armor();
    blank_armor();
  }
}

// For use by head_chip_pngs.sh.
if (printout == 4) magic_sword();
if (printout == 5) ender_pearl();
if (printout == 6) hammer();
if (printout == 7) health_potion();
if (printout == 8) iron_sword();
if (printout == 9) trident();
if (printout == 10) lightning();
if (printout == 11) wind();
if (printout == 12) magic_helm();
if (printout == 13) fire();
if (printout == 14) jump_back();
if (printout == 15) iron_helm();
if (printout == 16) iron_shield();
if (printout == 17) iron_mail();
if (printout == 18) wall();
  
// 1 to get one of each known chip.
// 2 to get 10 blank weapon chips, also useful as status effect 
//   markers.
// 3 to get 10 blank armor chips.
printout = 16;

// If true, we'll render just the 2D symbols. This is
// useful for producing a PNG to print in the guide.
$flat = false;
