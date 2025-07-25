use <base.scad>

translate([-67.5, -67.5, 0])
  repeatx(4, 45)
    repeaty(4, 45)
      base_chip();