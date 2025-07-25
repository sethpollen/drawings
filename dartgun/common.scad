$fa = 10;
$fs = 0.2;
eps = 0.003;
$zstep = 0.2;

// An inward chamfer sufficient to prevent elephant's foot.
foot = 0.4;

// FINDINGS FROM CLEARANCE TEST
//
// Consider a vertical hole of width X, a layer height of 0.2, and a vertical
// post.
//   * A post of diameter X will not fit in.
//   * A post of diameter X-0.1 will fit in, but is very hard to slide in or out.
//     This is probably due mostly to the transverse grain of the print.
//     It will rotate, but with some resistance.
//   * A post of diameter X-0.2 slides in and out easily. It rotates easily, but
//     still has noticeable resistance at some points.
//   * A post of diameter X-0.3 rotates freely. It also has noticeable play
//     from side to side.
//
// Clearances are expressed as the total across both sides of a joint.
tight = 0.1;  // Intended for stationary joints.
snug = 0.2;   // Moves, but with some resistance.
loose = 0.3;  // Free movement.
extra_loose = 0.4;

// Menards 1/4 inch aluminum rod.
roller_diameter = 6.7;
roller_cavity_diameter = roller_diameter + loose;

// 550 paracord. Make this wide enough to accommodate a melted end.
string_diameter = 4.5;

// Menards 1/8 inch steel rod.
nail_loose_diameter = 3.4;

module octagon(diameter) {
  intersection_for(a = [0, 45])
    rotate([0, 0, a])
      square(diameter, center=true);
}

// A cylinder with chamfered or flared ends, useful for dealing with
// elephant's foot on pins or holes.
module flare_cylinder(height, radius, flare_top, flare_bottom) {
  translate([0, 0, abs(flare_bottom)-eps])
    cylinder(height-abs(flare_bottom)-abs(flare_top)+eps, radius, radius);

  // Bottom flare.
  linear_extrude(abs(flare_bottom), scale=radius/(radius-flare_bottom))
    circle(radius-flare_bottom);
  
  // Top flare.
  translate([0, 0, height-abs(flare_top)])
    linear_extrude(abs(flare_top), scale=(radius-flare_top)/radius)
      circle(radius);
}

// A cube with a chamfered or flared bottom end, useful for dealing
// with elephant's foot on pins or holes.
module flare_cube(dims, flare) {
  translate([0, 0, abs(flare)-eps])
    cube([dims.x, dims.y, dims.z - abs(flare) + eps]);

  translate([dims.x/2, dims.y/2, 0])
    linear_extrude(abs(flare), scale=[dims.x/(dims.x-2*flare), dims.y/(dims.y-2*flare)])
      translate([-(dims.x-2*flare)/2, -(dims.y-2*flare)/2, abs(flare)-eps])
        square([dims.x-2*flare, dims.y-2*flare]);
}

// An approximate circle which can be printed on its side.
module circle_ish(r) {
  // Safe overhang angle.
  q = 45;
  
  intersection() {
    // Add 0.2 (one print layer) in case the bridge is messy and hangs
    // down.
    square(2*r+0.2, center=true);
    hull() {
      circle(r);
      for (a = [-1, 1])
        translate([0, a*r/cos(q), 0])
          square(eps, center=true);
    }
  }
}

// Depth of the sockets used as glue aids.
socket_depth = 5;

module socket() {
  translate([-1.5, -1.5, -eps])
    flare_cube([3, 3, socket_depth], -foot);
}

module lug() {
  flare_cube([3-snug, 3-snug, 2*socket_depth-2], foot);
}

// Nerf darts are 0.50 cal.
dart_diameter = 12.7;
dart_length = 72;

module octahedron(major_radius=1) {
  // Top and bottom halves.
  for (a = [-1, 1])
    scale([1, 1, a])
      // Extrude a square into a pyramid.
      linear_extrude(major_radius, scale=0)
        rotate([0, 0, 45])
          square(sqrt(2)*major_radius, center=true);
}

module chamfered_cube(dims, chamfer=1) {
  assert(dims.x >= 2*chamfer);
  assert(dims.y >= 2*chamfer);
  assert(dims.z >= 2*chamfer);

  hull()
    for (a = [0, 1], b = [0, 1], c = [0, 1])
        translate([
          (dims.x - 2*chamfer) * a + chamfer,
          (dims.y - 2*chamfer) * b + chamfer,
          (dims.z - 2*chamfer) * c + chamfer
        ])
          octahedron(chamfer);
}

function sum(elems, begin, end) = (
  begin == end
  ? 0
  : elems[begin] + sum(elems, begin+1, end)
);

module extrude_stack(heights) {
  for (i = [0:$children-1])
    translate([0, 0, sum(heights, 0, i)])
      linear_extrude(heights[i] + eps)
        children(i);
}

module build_plate_chamfer() {
  rotate([0, 0, 45])
    square(0.7, center=true);
}
