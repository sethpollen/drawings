include <common.scad>

// When printing, use 80% fill with the "lines" pattern.

// A standard size die is 15mm.
//
// Models in this file are centered on the origin.

module square_die_blank() {
  translate([0, 0, -7.5])
    chamfered_box([15, 15, 15]);
}

// Accepts six 2-D children for the six die faces.
module die_imprint() {
  // An engrave depth of 1 yielded a very clean print, but
  // the symbols were hard to see.
  engrave_depth = 2;

  for (case = [
    [0, [0, 0, 1]],  
    [1, [1, 0, 0]],  
    [2, [-1, 0, 0]],  
    [3, [0, 1, 0]],  
    [4, [0, -1, 0]],  
    [5, [0, 2, 1]],  
  ])
    rotate(case[1]*90)
      translate([0, 0, -7.5-eps])
        linear_extrude(engrave_depth)
          children(case[0]);
}

// I tried printing actual sword and star icons, but worried
// that their detail would get messed up with deeper
// envgravings. So instead I have chosen idealized symbols
// which should be bridgable. These new shapes align better
// with the die shapes anyway (circles and squares).

module one_sword() {
  scale([1.6, 4, 2]) {
    polygon([
      [-1, -1],
      [-1, 1],
      [1, 1],
      [1, -1],
    ]);
  }
}

module two_swords() {
  for (a = [-1, 1])
    translate(a * [-2.5, 0, 0])
      scale([a, 1, 1])
        one_sword();
}

module one_star() {
  scale(2.5 * [1, 1, 1]) {
    circle(1);
  }
}

module two_stars() {
  for (a = [-1, 1])
    translate(a * [-2.5, -2.5, 0])
      one_star();
}

module empty() {}

// Used for prototyping 2D shapes.
module backdrop() {
  color("purple")
    translate([0, 0, -2])
      linear_extrude(1)
        circle(7);
}

module square_die() {
  difference() {
    square_die_blank();

    die_imprint() {
      empty();
      two_swords();
      two_swords();
      one_star();
      two_stars();
      one_sword();
    }
  }
}

module rounded_die() {
  difference() {
    intersection() {
      square_die_blank();
      sphere(10.4);
    }
    
    die_imprint() {
      one_star();
      two_swords();
      // Reflect this one to make the die look nice.
      scale([-1, 1, 1]) two_stars();
      two_stars();
      two_stars();
      one_sword();
    }
  }
}


// Demo.
repeatx(5, 30)
  square_die();
