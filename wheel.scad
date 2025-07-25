eps = 0.001;
layer = 0.2;

height = 77;

// Add 3mm to the radius to account for wear.
diam = 190;

shell = 0.8;

rim_thickness = 11;

tread_depth = 3.5;
tread_width = 4;
tread_count = 25;

axle_hole_diam = 11.6;

spline_cutout_height = 15;
spline_count = 10;
spline_outer_diam = 47;
spline_inner_diam = 35;

edge_bevel = 12;

// A large enough core cylinder to contain the splines and axle hole,
// but not so large that it approaches the rim cavity.
core_diam = diam/2;

module roundoff_2d(r) {
  offset(r)
    offset(-r)
      children();
}

module shell_2d() {
  difference() {
    children();
    offset(-shell)
      children();
  }
}

module exterior_2d() {
    roundoff_2d(2, $fn=12) {
    difference() {
      circle(d=diam, $fn=120);
      
      for (a = [0:tread_count-1])
        rotate([0, 0, a * 360 / tread_count])
          translate([diam/2, 0])
            scale([tread_depth, tread_width])
              circle(1, $fn=12);
    }
  }
}

module rim_2d() {
  shell_2d()
    exterior_2d();
    
  difference() {
    scale(((diam - 2*rim_thickness) / diam) * [1, 1])
      exterior_2d();
    
    // Space for the core.
    circle(d=core_diam);
  }
}

module spline_cutouts_2d() {
  wall = 2.5;
  
  difference() {
    $fn = 32;
    circle(d=spline_outer_diam);
    circle(d=spline_inner_diam);

    for (a = [0:spline_count-1])
      rotate([0, 0, a * 360 / spline_count])
        translate([0, 500])
          square([wall, 1000], center=true);
  }
}

module spline_cutouts() {
  translate([0, 0, height - spline_cutout_height + eps])
    linear_extrude(spline_cutout_height)
      spline_cutouts_2d();
}

module rim() {
  bevel_scale = 0.96;
  
  difference() {
    union() {
      // Bottom plate.
      linear_extrude(shell) {
        difference() {
          scale(bevel_scale * [1, 1])
            exterior_2d();
          circle(d=core_diam);
        }
      }
      
      // Top bevel.
      translate([0, 0, height - edge_bevel - eps])
        linear_extrude(edge_bevel, scale=bevel_scale)
          rim_2d();
      
      // Bottom bevel.
      translate([0, 0, edge_bevel + eps])
        scale([1, 1, -1])
          linear_extrude(edge_bevel, scale=bevel_scale)
            rim_2d();
      
      // Middle.
      translate([0, 0, edge_bevel])
        linear_extrude(height - 2*edge_bevel) 
          rim_2d();
    }

    // A toroidal groove to help anchor the epoxy.
    translate([0, 0, height/2])
      rotate_extrude($fn=40)
        translate([diam/2 - rim_thickness + 1.5, 0])
          circle(4);
  }
}

module struts_2d(phase) {
  intersection() {
    // A ring that includes the rim cavity.
    difference() {
      exterior_2d();
      circle(d=core_diam);
    }
    
    count = 25;
    for (a = [1:count])
      rotate([0, 0, (a + phase) * 360 / count])
        translate([-0.5, 0])
          square([1, 1000]);
  }
}

module struts() {
  strut_height = 1;
  
  for(a = [0:3])
    translate([0, 0, edge_bevel + (a/3) * (height - strut_height - 2*edge_bevel)])
      linear_extrude(strut_height)
        struts_2d(a/4);
}

module spline_fins_2d() {
  count = 10;
  for (a = [1:count])
    rotate([0, 0, (a + 0.5) * 360 / count])
      square([spline_outer_diam, 0.1]);
}

module spline_fins() {
  fin_height = 0.2;
  
  for(a = [0:4])
    translate([0, 0, 1 + height - spline_cutout_height + (a/4) * (spline_cutout_height - 2)])
      linear_extrude(fin_height)
        spline_fins_2d();
}

// 20% cubic subdivision seems reasonable.
module wheel() {
  difference() {
    cylinder(h=height, d=core_diam+5);
    
    spline_cutouts();
    spline_fins();
      
    translate([0, 0, -eps]) {
      $fn = 50;
      cylinder(h=height+1, d=axle_hole_diam);
      cylinder(h=0.4, d=axle_hole_diam+0.6);
    }
  }
  
  rim();
  struts();
}

wheel();