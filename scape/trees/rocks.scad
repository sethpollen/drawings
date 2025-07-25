module impo() {
  translate([0, -80, 0])
    import("originals/Tree_large_rocks_scanned.stl", 3);
}

intersection() {
  for (z = [0, 0.2])
    translate([0, 0, -z])
      impo();
  translate([0, 0, 500])
    cube(1000, center=true);
}
