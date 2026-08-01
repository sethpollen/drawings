include <barrel.scad>
include <hairspring.scad>

// TODO: the fingers don't fit into their cavity in the bracket

module preview() {
  translate([0, 0, 15])
    bracket();
  barrel_preview();
}

projection(cut=true)
  translate([0, 0, -107])
    preview();