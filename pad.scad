plate_thickness = 0.8;
wall_thickness = 0.5;
wall_space = 7;

module rib(span, length) {
  $fn = 30;
  d = span*1.35;
  
  linear_extrude(length) {
    translate([0, -d*0.3]) {
      intersection() {
        difference() {
          circle(d=d);
          circle(d=d-wall_thickness*2);
        }
        translate([0, d])
          square([span, d*2], center=true);
      } 
    }
  }
}

module pad(dim) {
  // Top and bottom plates.
  difference() {
    cube(dim);
    translate([-1, -1, plate_thickness])
      cube(dim + [2, 2, -plate_thickness*2]);
  }
  
  tuck = 1;
  cells = round((dim.y - wall_thickness - 2*tuck) / (wall_thickness + wall_space));
  offs = (dim.y - wall_thickness - 2*tuck) / cells;
  space = offs - wall_thickness;
  rib_span = dim.z - plate_thickness*2;

  translate([0, tuck+wall_thickness, plate_thickness+rib_span/2])
    for (i = [0:cells])
      translate([0, i*offs, 0])
        rotate([0, 90 , 0])
          rib(rib_span, dim.x);
}

dim = [10, 30, 5];
pad(dim);
