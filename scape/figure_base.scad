bot_r = 33/2;
top_r = 30/2;

// The real bases are more like 3.7mm, but printing that requires 0.1mm layers,
// which is slow. Also a 3.7mm base fits a bit too snugly in the castle ladders.
// 3.6mm seems fine.
height = 3.6;

$fn = 200;

inlay_depth = 1;
lip = 0.8;
inlay_slack = 0.3;

// Make the inlay 1 layer shorter than the cavity for it, to make sure we don't
// accidentally thicken the overall part.
inlay_thickness = inlay_depth-0.2;

penny_diam = 19.25;
penny_height = 1.63;

module single_base() {
  round_r = 0.75;
  difference() {
    rotate_extrude() {
      hull() {
        translate([bot_r-round_r, round_r])
          circle(round_r);
        square([1, height]);
        translate([top_r-1, 0])
          square([1, height]);
      }
    }
    
    // Elephant foot.
    linear_extrude(0.2) {
      difference() {
        circle(100);
        circle(bot_r - round_r + 0.05);
      }
    }
    
    // Inlay well.
    translate([0, 0, height - inlay_depth])
      cylinder(h=inlay_depth+1, r=top_r-lip);
  }
}

// Large single base (like for the Frost Giant), just scale this up to 113%.
module single_large_base_penny() {
  difference() {
    scale([1.13, 1.13, 1])
      single_base();
    
    translate([5.7, 0, height - inlay_depth - penny_height])
      cylinder(d=penny_diam, h=10);
  }
}

module single_inlay() {
  cylinder(h=inlay_thickness, r=top_r-lip-inlay_slack);
}

module single_large_inlay() {
  scale([1.13, 1.13, 1])
    single_inlay();
}

// Largest profile of the double base.
module double_base_2d(large=false) {
  // Large measurements from Brunak. Small measurements from Major Q10.
  length = large ? 81.9 : 77.8;
  width = large ? 37.4 : 31.9;
  waist = large ? 24.7 : 18.4;
  cut_radius = large ? 23.5 : 27;
  
  difference() {
    union() {
      for (a = [-1, 1])
        translate([a*(length - width)/2, 0])
          circle(d=width);
      square([length - width, width*0.83], center=true);
    }
    for (a = [-1, 1])
      translate([0, a*(waist/2 + cut_radius)])
        circle(cut_radius);
  }
}

module double_base_layer(layers_up, offs, large=false) {
  translate([0, 0, layers_up*0.2])
    linear_extrude(0.20001)
      offset(offs)
        double_base_2d(large=large);
}

double_base_slope = 0.115;
double_base_layer_offsets = [
  -0.6, -0.2,
  0, 0,
  -1*double_base_slope,
  -2*double_base_slope,
  -3*double_base_slope,
  -4*double_base_slope,
  -5*double_base_slope,
  -6*double_base_slope,
  -7*double_base_slope,
  -8*double_base_slope,
  -9*double_base_slope,
  -10*double_base_slope,
  -11*double_base_slope,
  -12*double_base_slope,
  -13*double_base_slope,
  -14*double_base_slope,
];
double_base_layer_top_offset = double_base_layer_offsets[17];

module double_base(large=false, pennies=false, washers=0) {
  difference() {
    // Need a total of 18 layers to make 3.6mm.
    for (i = [0:17])
      double_base_layer(i, double_base_layer_offsets[i], large=large);
        
    // Inlay well.
    translate([0, 0, height - inlay_depth])
      linear_extrude(inlay_depth+1)
        offset(double_base_layer_top_offset - lip)
          double_base_2d(large=large);
    
    if (pennies) {
      for (a = [-1, 1])
        scale([a, 1, 1])
          translate([
            large ? 23 : 23.1,
            large ? 
              0 // Change to 6 to offset the pennies.
              : 3.9,
            height - inlay_depth - penny_height
          ])
            cylinder(d=penny_diam, h=10);
      
      // Notch to show which side has the the pennies.
      translate([0, 12, 0])
        cube([1.3, 10, 0.4], center=true);
    }
    
    washer_diam = 11.35;
    washer_height = 1.12;

    if (washers == 1) {
      for (a = [-1, 1])
        scale([a, 1, 1])
          translate([large ? 25.5 : 23.5, 0, height - inlay_depth - washer_height - 0.11])
            cylinder(d=washer_diam + 0.2, h=10);
    } else if (washers == 2) {
      for (a = [-1, 1], b = [-1, 1])
        scale([a, b, 1])
          translate([large ? 23 : 23.5, large ? 10.4 : 7.71, height - inlay_depth - washer_height - 0.11])
            cylinder(d=washer_diam + 0.2, h=10);
    }
  }
}

module double_inlay(large=false) {
  linear_extrude(inlay_thickness)
    offset(double_base_layer_top_offset - lip - inlay_slack)
      double_base_2d(large=large);
}

// I printed the double bases with 70% fill to help weight the large figures.


single_inlay();
translate([0, 39, 0])     scale([1.13, 1.13, 1])
      single_large_inlay();

