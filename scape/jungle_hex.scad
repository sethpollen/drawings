eps = 0.001;

// Height of a normal terrain piece, when stacked.
block_height = 9.6;

// Underbrush is 9*9.6 = 86mm.
// Trees:
//   14*9.6 = 134
//   15*9.6 = 144
//   16*9.6 = 154

tree_trunk_diam = 3.8;

// Minor diameter of the base.
base_minor_diam = 38;
base_major_diam = 43.88;

fern_holes = 8;

module base_2d() {
  roundoff = 4;
  offset(roundoff, $fn = 30)
    offset(-roundoff)
      hull()
        for (a = [0:5])
          rotate([0, 0, a*60])
            translate([base_major_diam/2, 0])
              square(eps, center=true);
}

module shell() {
  shell_wall = 6.5;
  shell_ceiling = 5;
  sphere_down = -22.3;
  
  intersection() {
    linear_extrude(20) {
      difference() {
        base_2d();
        offset(-shell_wall)
          base_2d();
      }
    }
    translate([0, 0, sphere_down])
      sphere(d=base_major_diam*1.6, $fn=30);
  }
  
  intersection() {
    linear_extrude(20)
      base_2d();
    translate([0, 0, sphere_down - 0.5 - shell_ceiling]) {
      difference() {
        union() {
          // Domed top.
          sphere(d=base_major_diam*1.6+2*shell_ceiling, $fn=60);
          
          // Rocks.
          for (a = [0, 110, 280]) rotate([0, 0, a])
            translate([5, 5, 38.5]) rotate([30, 0, 0]) sphere(r=5, $fn=6);
          for (a = [0, 80, 220]) rotate([0, 0, a])
            translate([-10, 7, 35.5]) rotate([30, 0, 40]) scale([1.2, 1, 1]) sphere(r=5, $fn=7);
          for (a = [0, 170, 220, 300]) rotate([0, 0, a])
            translate([0, 13, 35.5]) rotate([80, 0, 40]) scale([1.5, 1.1, 1.5]) sphere(r=5, $fn=8);
          rotate([0, 0, 40])
            translate([-10, 10, 34]) rotate([80, 20, 100]) scale([2, 1.1, 1.5]) sphere(r=5, $fn=9);
          rotate([0, 0, 40])
            translate([-2, -2, 38]) rotate([80, 40, 200]) scale([2, 1.1, 1.5]) sphere(r=5, $fn=9);
        }
        sphere(d=base_major_diam*1.6, $fn=30);
      }
    }
  }
}

module holes() {
  $fn = 30;

  // Central cavity.
  linear_extrude(100)
    circle(d=tree_trunk_diam);

  // Side cavities.
  for (a = [1:fern_holes])
    rotate([0, 0, a*360/fern_holes])
      translate([10, 0, 1.2])
        rotate([0, 12, 0])
          cylinder(h=20, d=2.8);
}

module trunks() {
  $fn = 30;
  tree_trunk_height = 20;
  tree_trunk_wall = 2;

  // Tree trunk.
  lift = 10;
  translate([0, 0, lift]) {
    linear_extrude(tree_trunk_height - lift)
      circle(d=tree_trunk_diam+2*tree_trunk_wall);
    translate([0, 0, tree_trunk_height - lift])
      scale([1, 1, 0.5])
        sphere(d=tree_trunk_diam+2*tree_trunk_wall);
  }
  
  // Hills around foliage bases.
  for (a = [1:fern_holes]) {
    rotate([0, 0, a*360/fern_holes]) {
      translate([10, 0, 1.2]) {
        rotate([0, 12, 0]) {
          translate([0, 0, 9]) {
            intersection() {
              sphere(d=6);
              translate([0, 0, 100])
                cube(200, center=true);
            }
          }
        }
      }
    }
  }
}

module main() {
  difference() {
    union() {
      shell();
      trunks();
    }
    holes();
  }
}

main();
