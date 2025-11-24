eps = 0.001;
thickness = 1.6;
width = 8;

sizer_steps = 10;
sizer_step_size = 0.5;

module sizer_distribution(min_id) {

  for (i = [0:sizer_steps-1]) {
    $id = min_id + i*sizer_step_size;
    x = i*(min_id + thickness-0.2) + i*i*sizer_step_size/2;
    translate([x, 0])
      children();
  }
}

module sizer_2d(min_id) {
  $fn=90;

  difference() {
    hull()
      sizer_distribution(min_id)
        circle(d=$id+thickness*2);
    
    sizer_distribution(min_id)
      circle(d=$id);
  }
}

module sizer(min_id) {
  linear_extrude(width)
    sizer_2d(min_id);
  
  color("red")
    translate([36, min_id/2+thickness-eps, width*0.15])
      rotate([90, 0, 180])
        linear_extrude(1.5)
          offset(0.2, $fn=60)
            text(str(min_id + (sizer_steps-1)*sizer_step_size, " — ", min_id), size=width*0.7);
}

module ring_blank_2d(id) {
  bevel = 0.18;
  
  for (a = [-1, 1]) {
    scale([1, a]) {
      hull() {
        translate([id/2, 0])
          square([thickness, width/2-1]);
        translate([id/2+bevel, 0])
          square([thickness-2*bevel, width/2]);
      }
    }
  }
}

module ring_blank(id) {
  rotate_extrude($fn=90)
    ring_blank_2d(id);
}

module crown_cutouts(id) {
  $fn = 40;
  
  breadth = id*0.3;
  depth = 2 + id*0.15;
  count = 7;
  
  for (a = [1:count])
    rotate([0, 0, a*360/count])
      translate([0, 0, width/2+depth*0.1])
        scale([breadth, 1, depth])
          rotate([90, 0, 0])
            cylinder(d1=0, d2=1, h=id/2+thickness+eps);
}

module crown_ring(id) {
  difference() {
    ring_blank(id);
    crown_cutouts(id);
  }
}

module sizers() {
  sizer(12);
  translate([170, -22])
    rotate([0, 0, 180])
      sizer(17);
}

sizers();