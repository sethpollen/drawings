use <paddle.scad>

positioning_square();

print_position()
intersection() {
  unibody();
  sample_cut();
}