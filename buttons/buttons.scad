module base_2d() {
  projection()
  import("preprocessed.stl", 4);
}

module exterior_2d() {
  roundoff = 5;
  $fn = 10;
  offset(r=-roundoff)
  offset(r=roundoff)
  base_2d();
}

module holes_2d() {
  difference() {
    union() {
      translate([40, 45]) circle(22);
      translate([155, 42]) circle(22);
    }
    base_2d();
  }
}

// A couple of holes need to be made bigger.
module enlarged_holes_2d() {
  offset(delta=0.8)
  intersection() {
    union() {
      translate([165, 55]) circle(8);
      translate([145, 30]) circle(8);
    }
    holes_2d();
  }
}

thickness = 4;

module round_extrude() {
  layer_height = 0.2;
  layers = thickness/(2*layer_height);
  
  for (i = [0:layers-1])
  translate([0, 0, i*layer_height])
  linear_extrude(layer_height + 0.001)
  offset(layer_height*sqrt(layers*layers-i*i)-layer_height*layers)
  children();
}

module piece() {
  shrink = 0.425;

  translate([0, 0, thickness/2])
  for (a = [-1, 1])
  scale([1, 1, a])
  round_extrude()
  scale(shrink * [1, 1])
  difference() {
    exterior_2d();
    holes_2d();
    enlarged_holes_2d();
  }
}

piece();