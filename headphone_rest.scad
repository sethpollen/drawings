$fn = 50;

pc_width = 6.5 * 25.4;
slack = 0.25;
thickness = 5;
height = 75;
hook_length = 70;
curl_radius = 20;

width = 23;
roundoff = 2.4;

hook_x = pc_width + 2*slack + 2*thickness;

module piece_2d() {
  difference() {
    union() {
      // Main body.
      square([hook_x, height]);
      
      // Horizontal extension of the hook.
      square([hook_x + hook_length, thickness]);
      
      // Curled end.
      translate([hook_x + hook_length, curl_radius]) {
        intersection() {
          circle(r=curl_radius);
          rotate([0, 0, 240])
            square(100);
        }
      }
    }    
    
    // Cutout for PC.
    translate([thickness, -thickness])
      square([pc_width + 2*slack, height]);
    
    // Shorten the back leg.
    square(height, center=true);
    
    // Cutout for curled end.
    translate([hook_x + hook_length, curl_radius])
      circle(r=curl_radius-thickness);
    
    // Remove the part of the curl circle we don't want.
    translate([hook_x + hook_length - curl_radius, thickness])
      square([curl_radius, 100]);
  }
  
  // Reinforcement.
  translate([hook_x, thickness])
    polygon(6 * [
      [0, 0],
      [0, 1],
      [1, 0],
    ]);
}

module piece_rounded_2d() {
  offset(roundoff)
    offset(-roundoff*2)
      offset(roundoff)
        piece_2d();
}

module piece() {
  chamfers = 5;

  for (a = [-1, 1])
    scale([1, 1, a])
      translate([0, 0, -width/2])
        for (i = [1:chamfers])
          translate([0, 0, (i-1)*0.2])
            linear_extrude(0.2)
              offset(-0.13*(chamfers-i) - (a == 1 && i == 1 ? 0.32 : 0))
                piece_rounded_2d();
  
  translate([0, 0, -width/2+chamfers*0.2])
    linear_extrude(width-chamfers*0.4)
      piece_rounded_2d();
        
  // Brims.
  translate([0, 0, -width/2])
    linear_extrude(0.4)
      for (xy = [
        [thickness/2, height/2-1],
        [hook_x-6, -1],
        [hook_x+1, height+1],
        [hook_x+hook_length+17, 12],
      ])
        translate(xy)
          circle(d=14);
}

piece();