use <morph.scad>

$fa = 8;
$fs = 0.2;
$zstep = 0.16;  // Matches the layer height.
eps = 0.001;

function circ(x) = 1-sqrt(1-x*x);

module enflesh(height, radius) {
  morph([
    [0,      [0]],
    [height, [1]],
  ])
    offset(r=-radius*circ($m[0]))
      children();
}

module mytext(s) {
  text(s, size=13, font="Anaktoria:style=Bold");
}

layer_thickness = 1.5;

daisy1_center = [20, 40, 0];
daisy1_scale = 0.19;

daisy2_center = [-20, 49.5, 0];
daisy2_scale = 0.15;

daisy3_center = [8, -60, 0];
daisy3_scale = 0.25;

module message() {
  translate([0, 10, 0]) {
    translate([-40, 4, 0]) mytext("Happy");
    translate([-33, -20, 0]) mytext("Birthday,");
    translate([-26, -39, 0]) mytext("Ashia!");
  }
}

module daisy_petals() {
  height = 15;
  petals = 10;
  radius = 100;
  petal_radius = 18;
  
  difference() {
    for (t = [0:(petals-1)]) {
      rotate([0, 0, t*(360/petals)]) {
        hull() {
          translate([radius-petal_radius, 0, 0]) circle(petal_radius);
          translate([10, 0, 0]) circle(eps);
        }
      }
    }
    
    // Remove the center.
    daisy_center();
  }
}

module daisy_center() {
  circle(30);
}

module daisy() {
  daisy_petals();
  daisy_center();
}

inner_dims = [90, 120];

module square_rail(length, major_radius=0.5) {
  rotate([90, 45, 0])
    cube([major_radius*sqrt(2), major_radius*sqrt(2), 1000], center=true);
}

module blank_layer(chamfer=true) {
  difference() {
    translate([0, 0, layer_thickness/2])
      cube([inner_dims.x, inner_dims.y, layer_thickness], center=true);
    
    if (chamfer) {
      // Chamfer bottom edges for elephant foot against case.
      for (x = inner_dims.x/2 * [-1, 1])
        translate([x, 0, 0])
          square_rail();
      for (y = inner_dims.y/2 * [-1, 1])
        translate([0, y, 0])
          rotate([0, 0, 90]) square_rail();
    }
  }
}

module forward_engrave() {
  morph([
    [-eps, [0.2]],
    [0.16, [0]],
    [layer_thickness, [0.7]],
    [layer_thickness+1, [0.7]],
  ])
    offset(r=$m[0])
      children();
}

module back_engrave() {
  morph([
    [-eps, [0.6]],
    [layer_thickness, [0]],
    [layer_thickness+1, [0]],
  ])
    offset(r=$m[0])
      children();
}

module layer1() {
  difference() {
    blank_layer();
    
    // Message.
    forward_engrave() message();
    
    forward_engrave() 
      translate(daisy1_center - [0, 0, eps])
        scale([daisy1_scale, daisy1_scale, 1])
          daisy();
    
    forward_engrave()
      translate(daisy2_center - [0, 0, eps])
        scale([daisy2_scale, daisy2_scale, 1])
          daisy();
    
    forward_engrave()
      translate(daisy3_center - [0, 0, eps])
        scale([daisy3_scale, daisy3_scale, 1])
          daisy();
  }
}

module layer2() {
  translate([0, 0, layer_thickness-eps])
    linear_extrude(0.32)
      offset(r=-0.14) message();

  difference() {
    blank_layer();
    
    back_engrave() 
      translate(daisy1_center - [0, 0, eps])
        scale([daisy1_scale, daisy1_scale, 1])
          daisy_petals();
    
    back_engrave()
      translate(daisy2_center - [0, 0, eps])
        scale([daisy2_scale, daisy2_scale, 1])
          daisy_petals();
    
    back_engrave()
      translate(daisy3_center - [0, 0, eps])
        scale([daisy3_scale, daisy3_scale, 1])
          daisy_petals();
  }
  
  intersection() {
    translate([0, 0, -10])
      scale([1, 1, 100])
        blank_layer(chamfer=false);
    
    translate([0, 0, layer_thickness]) {
      enflesh(3, 5) {
        translate(daisy1_center - [0, 0, eps])
          scale([daisy1_scale, daisy1_scale, 1])
            daisy_center();
      
        translate(daisy2_center - [0, 0, eps])
          scale([daisy2_scale, daisy2_scale, 1])
            daisy_center();
      
        translate(daisy3_center - [0, 0, eps])
          scale([daisy3_scale, daisy3_scale, 1])
            daisy_center();
      }
    }
  }
}

module layer3() {
  blank_layer();
  
  intersection() {
    translate([0, 0, -10])
      scale([1, 1, 100])
        blank_layer(chamfer=false);
      
    translate([0, 0, layer_thickness]) {
      enflesh(4, 5) {
        translate(daisy1_center - [0, 0, eps])
          scale([daisy1_scale, daisy1_scale, 1])
            daisy_petals();
       
        translate(daisy2_center - [0, 0, eps])
          scale([daisy2_scale, daisy2_scale, 1])
            daisy_petals();
        
        translate(daisy3_center - [0, 0, eps])
          scale([daisy3_scale, daisy3_scale, 1])
            daisy_petals();
      }
    }
  }
}

module case() {
  difference() {
    translate([0, 0, 2.7])
      hull()
        for (a = [-1,1], b=[-1,1], c=[-1,1])
          scale([a,b,c])
            translate([inner_dims.x, inner_dims.y, 1.5]/2)
              sphere(3);
      
    translate([-inner_dims.x/2-0.2, -inner_dims.y/2-0.2, 0])
      cube([inner_dims.x+0.4, inner_dims.y+0.4, 100]);
  }
}

module preview() {
  color("purple") translate([0, 0, 2*layer_thickness]) layer1();
  color("yellow") translate([0, 0, layer_thickness]) layer2();
  color("cyan") translate([0, 0, 0]) layer3();
  color("purple") case();
}

case();
