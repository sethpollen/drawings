$fn = 80;

inner_id = 27.9;
outer_id = 46;
lap = 5;
inner_od = outer_id + lap*2;

module inner_2d() {
  intersection() {
    difference() {
      circle(d=inner_od);
      circle(d=inner_id);
    }
    square([1000, inner_id+10], center=true);
  }
}

module outer_2d() {
  difference() {
    circle(d=outer_id+10);
    circle(d=outer_id);
  }
}

module inner() {
  linear_extrude(7.2)
    inner_2d();
}

color("blue") linear_extrude(2) outer_2d();
color("red") linear_extrude(1) inner_2d();