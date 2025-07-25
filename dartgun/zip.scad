zip_channel_height = 3.2;
zip_channel_width = 6.5;

// Tuck the exposed ends in by this much to get a nice rounded corner.
zip_channel_tuck = 2;

module zip_channel(inner_dims) {
  translate([0, 0, -zip_channel_width/2]) {
    linear_extrude(zip_channel_width) {
      difference() {
        offset(6 + zip_channel_height)
          square(inner_dims - [7, 7], center=true);
        offset(6)
          square(inner_dims - [7, 7], center=true);
      }
    }
  }
}