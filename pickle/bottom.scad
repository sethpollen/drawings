use <paddle.scad>

difference() {
  bottom();
  import("bottom_perforations.stl", convexity=3);
}