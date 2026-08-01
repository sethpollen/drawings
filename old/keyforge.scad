eps = 0.0001;
$fn = 30;

coin_d = 19;
coin_height = 2.4;

foot = 0.5;

module coin_2d() {
  $fn = 100;
  difference() {
    circle(d=coin_d);
    scale([0.75, 1])
      rotate([0, 0, 45])
        square(coin_d*0.42, center=true);
  }
}

module coin() {
  linear_extrude(0.2)
    offset(-foot)
      coin_2d();
  translate([0, 0, 0.2])
    linear_extrude(coin_height - 0.2)
      coin_2d();
}

card_width = 63;
card_height = 89.4;

cavity_slack = 0.8;
wall = 1.5;
flor = 1.4;
deck_thickness = 13;
height_slack = 4.2;

roundoff = 1.6;
protrusion = 1.8;

module cavity_2d() {
  offset(roundoff)
    offset(-roundoff)
      square([card_width + cavity_slack, card_height + cavity_slack], center=true);
}

module protrusion_2d() {
  offset(roundoff)
    offset(-roundoff)
      square([card_width, card_height], center=true);
}

module box_2d() {
 offset(roundoff + wall)
   offset(-roundoff - wall)
     square([card_width + cavity_slack + wall*2, card_height + cavity_slack + wall*2], center=true);
}

module fingers_2d() {
  $fn = 100;
  for (a = [-1, 1])
    scale([a, 1])
      translate([card_width*0.55, 0, 0])
        circle(15);
}

module box() {
  linear_extrude(0.4)
    offset(-foot)
      protrusion_2d();
  
  translate([0, 0, 0.4])
    linear_extrude(protrusion - 0.4)
      protrusion_2d();
  
  translate([0, 0, protrusion]) {
    linear_extrude(flor)
      box_2d();
  
    translate([0, 0, flor]) {
      linear_extrude(deck_thickness + height_slack) {
        difference() {
          box_2d();
          cavity_2d();
        }
      }
    }
  }
}

module piece() {
  difference() {
    box();
    translate([0, 0, -1])
      linear_extrude(100)
        fingers_2d();
  }
}

piece();