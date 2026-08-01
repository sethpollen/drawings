eps = 0.0001;
$fn = 16;

hex_side = 32;
thickness = 2.4;

clasp_width = 5;
clasp_length = 2.7;
slack = 0.15;

ears = true;
ear_thickness = 0.4 - eps;

stripe_thickness = 0.4;
stripe_width = 4.4;
stripe_inset = 2.2;

prototype = false;

function contains_mod_6(haystack, needle, pos=0) =
  (pos < len(haystack))
  && (
    ((needle % 6) == (haystack[pos] % 6))
    || contains_mod_6(haystack, needle, pos+1)
  );

module hex_2d() {
  polygon([for (r = [0:60:300]) hex_side * [cos(r), sin(r)]]);
}

module long_stripe_2d() {
  $fn = 30;

  intersection() {
    translate([0, spacing/2])
      square([1000, stripe_width], center=true);
    
    offset(-stripe_inset)
      hull()
        for (a = [60, 300])
          rotate([0, 0, a])
            translate([0, spacing])
              hex_2d();
  }
}

module short_stripe_2d() {
  $fn = 30;
  
  intersection() {
    square([1000, stripe_width], center=true);
    
    offset(-stripe_inset - slack - eps) {
      offset(slack + eps) {
        hex_2d();
        for (b = [60, 120, 240, 300])
          rotate([0, 0, b])
            translate([0, spacing])
              hex_2d();
      }
    }
  }
}

module clasp_lug_2d() {
  translate([0, hex_side*sqrt(3)/2])
    square([clasp_width, clasp_length]);
}

module clasp_socket_2d() {
  offset(slack)
    translate([-clasp_width, hex_side*sqrt(3)/2 - clasp_length])
      square([clasp_width, 2*clasp_length]);
}

module piece_2d(lugs=[]) {
  difference() {
    union() {
      hex_2d();
      
      for (r = 60 * lugs)
        rotate([0, 0, r])
          clasp_lug_2d();
    }
    
    for (r = 60 * lugs)
      rotate([0, 0, r])
        clasp_socket_2d();
    
    if (prototype)
      circle(hex_side*0.55, $fn=40);
  }
}

groove_depth = 1;
groove_flat = 0.15;

module groove() {
  magnitude = groove_depth * sqrt(2);
  
  hull()
    for (dy = groove_flat * [-1, 1])
      translate([0, hex_side*sqrt(3)/2 + dy, thickness])
        scale([1, 0.75, 1])
          rotate([45, 0, 0])
            cube([hex_side+1, magnitude, magnitude], center=true);
}

spacing = hex_side * sqrt(3) + slack;

module joint() {
  // Withdraw the ends slightly from exposed inner corners.
  width = hex_side - 0.3;
  
  color("red")
    linear_extrude(thickness - groove_depth)
      translate([-width/2, hex_side * sqrt(3) / 2 - 0.1])
        square([width, 0.2 + slack]);
}

module plug() {
  color("blue")
    linear_extrude(thickness - groove_depth)
      translate([hex_side, 0])
        square(2, center=true);
}

module piece(lugs=[], joints=[]) {
  difference() {
    linear_extrude(thickness)
      piece_2d(lugs=lugs);
    
    for (a = [0:60:300])
      rotate([0, 0, a])
        groove();
  }

  // Rabbit ears for lugs.
  if (ears)
    linear_extrude(ear_thickness)
      for (r = 60 * lugs)
        rotate([0, 0, r])
          translate([0.3, hex_side * sqrt(3)/2 + clasp_length - 1])
            square([clasp_width-0.5, 10]);
  
  // Joints.
  for (r = 60 * joints)
    rotate([0, 0, r])
      joint();
  
  // Plugs wherever two joints meet.
  for (a = [0:5])
    if (contains_mod_6(joints, a) && contains_mod_6(joints, a+1))
      rotate([0, 0, 120 + a*60])
        plug();
    
  // Rabbit ears at exposed corners.
  if (ears)
    linear_extrude(ear_thickness)
      for (a = [0:5])
        if (!contains_mod_6(joints, a) && !contains_mod_6(joints, a+1))
          rotate([0, 0, 120 + a*60])
            translate([hex_side, 0])
              rotate([0, 0, 30])
                translate([-1, 0.2])
                  square([10, 5]);
}

module small_piece(lugs=[true, true, true, true], stripe=true) {
  difference() {
    union() {
      piece(joints=[0, 1, 2, 3, 4, 5]);
      
      for (a = [0:5]) {
        rotate([0, 0, a*60]) {
          translate([0, spacing])
            piece(
              lugs =
                (a == 0 && lugs[0]) ? [1, 5]
              : (a == 1 && lugs[1]) ? [1]
              : (a == 2 && lugs[1]) ? [5]
              : (a == 3 && lugs[2]) ? [1, 5]
              : (a == 4 && lugs[3]) ? [1]
              : (a == 5 && lugs[3]) ? [5]
              : [],
              joints=[2, 3, 4]
            );
        }
      }

      if (stripe)
        linear_extrude(thickness)
          offset(-0.2)
            long_stripe_2d();
    }
    
    if (stripe)
      translate([0, 0, thickness - stripe_thickness])
        linear_extrude(10)
          long_stripe_2d();
  }
}

module large_piece(lugs=[true, true, true, true], stripe=true) {
  difference() {
    union() {
      // Short row.
      for (a = [0:1])
        translate([0, a * spacing])
          piece(
            joints =
              (a == 0) ? [0, 1, 2,    4, 5]
            : (a == 1) ? [   1, 2, 3, 4, 5]
            : []
          );
      
      // Long rows.
      for (a = [-1, 0, 1], b = [-1, 1])
        translate([0, a * spacing])
          rotate([0, 0, b * 60])
            translate([0, spacing])
              piece(
                lugs =
                  (b == -1 && a == -1 && lugs[0]) ? [3]
                : (b ==  1 && a == -1 && lugs[0]) ? [3]
                : (b == -1 && a ==  1 && lugs[1]) ? [2]
                : (b ==  1 && a ==  1 && lugs[1]) ? [4]
                : (b == -1 && a ==  0 && lugs[2]) ? [0, 5]
                : (b ==  1 && a ==  0 && lugs[3]) ? [0, 1]
                : [],
                joints =
                  (b == -1 && a == -1) ? [1, 2]
                : (b ==  1 && a == -1) ? [4, 5]
                : (b == -1 && a ==  1) ? [3, 4]
                : (b ==  1 && a ==  1) ? [2, 3]
                : (b == -1 && a ==  0) ? [1, 3, 4]
                : (b ==  1 && a ==  0) ? [2, 4, 5]
                : []
              );
              
      if (stripe)
        linear_extrude(thickness)
          offset(-0.2)
            short_stripe_2d();
    }
    
    if (stripe)
      translate([0, 0, thickness - stripe_thickness])
        linear_extrude(10)
          short_stripe_2d();
  }
}

module print() {
  linear_extrude(0.2)
    offset(-0.3)
      projection(cut=true)
        translate([0, 0, -0.1])
          children();
  intersection() {
    children();
    translate([0, 0, 500.2])
      cube(1000, center=true);
  }
}

module gash() {
  translate([0, 0, 0.2])
    linear_extrude(1)
        offset(0.17 - stripe_width/2)
          children();
}

module print_stripes() {
  print() {
    for (a = [-1, 1]) {
      scale([1, a]) {
        translate([0, -11.5]) {
          for (y = [0, -6]) {
            translate([0, y]) {
              difference() {
                linear_extrude(stripe_thickness)
                  offset(-0.2)
                    long_stripe_2d();
                gash()
                  long_stripe_2d();
              }
            }
          }
          
          translate([0, 15.5]) {
            difference() {
              linear_extrude(stripe_thickness)
                offset(-0.2)
                  short_stripe_2d();
              gash()
                short_stripe_2d();
            }
          }
        }
      }
    }
  }
}

print_stripes();