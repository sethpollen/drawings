eps = 0.0001;

card_h = 101;

height = 42;
plate_t = 2;
tilt_offs = height/2;
gap = 17.8;
wall = 2.3;
sep_wall = 10;

chambers = 5;

module slash(w) {
  hull()
    for (yz = [[0, 0], [tilt_offs, height]])
      translate([-card_h/2, yz[0], yz[1]])
        cube([card_h, w, eps]);
}

module slashes() {
  slash(wall);

  for (i = [0:chambers-2])
    translate([0, gap+wall + i*(gap+sep_wall), 0])
      slash(sep_wall);
  
  translate([0, gap+wall + (chambers-1)*(gap+sep_wall), 0])
    slash(wall);
}

module barrel() {
  roundoff = 10;
  d = card_h*0.48;
  long = 400;
  
  translate([0, 0, height-roundoff+0.7]) {
    translate([0, long/2, 0])
      rotate([90, 0, 0])
        scale([1, 0.8, 1])
          cylinder($fn=90, h=long, d=d);
    
    difference() {
      translate([0, 0, d/2])
        cube([d+2*roundoff, long, d], center=true);
      
      for (a = [-1, 1])
        scale([a, 1, 1])
          translate([-d/2-roundoff, long/2, 0])
            rotate([90, 0, 0])
              cylinder($fn=90, h=long, r=roundoff);
    }
  }
}

module walls() {
  for (a = [-1, 1]) {
    scale([a, 1, 1]) {
      difference() {
        translate([wall, 0, 0])
          hull()
            slashes();
        translate([0, -1, -1])
          scale([1, 2, 2])
            hull()
              slashes();
      }
    }
  }
}

module plate() {
  intersection() {
    hull()
      slashes();
    cube([1000, 1000, plate_t*2], center=true);
  }
}

module tags() {
  for (x = (card_h/2 + wall) * [-1, 1], y = [0, chambers*gap + (chambers-1)*sep_wall + 2*wall])
    translate([x, y])
      cylinder(r=6, h=0.4);
}

module piece() {
  difference() {
    slashes();
    barrel();
  }
  difference() {
    walls();
    for (x = (card_h/2 + wall) * [-1, 1], y = [0, chambers*gap + (chambers-1)*sep_wall + 2*wall + tilt_offs])
      translate([x, y, -1])
        linear_extrude(150)
          rotate([0, 0, 45])
            square(2, center=true);
  }
  plate();
  tags();
}

piece();