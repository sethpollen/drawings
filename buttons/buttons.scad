module button_2d() {
  difference() {  
    circle(d=30, $fn=45);
    for (a = [-1, 1], b = [-1, 1])
    translate(4 * [a, b])
    circle(d=3.9, $fn=16);
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
  for (a = [-1, 1])
  scale([1, 1, a])
  round_extrude()
  button_2d();
}

piece();
