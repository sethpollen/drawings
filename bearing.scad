test = false;

$fn = 120;

bot_h         = test ? 10   : 43.6 ;
collar_h      = test ?  8   : 29   ;
top_h         = test ?  1.2 :  3.8 ;
top_intrusion = test ?  4   : 10   ;

bot_od = 39.3;
collar_od = 39.45;
collar_id = bot_od - 8;

top_d = 51.95;

slip = 0.5;
z_play = 0.6;

module bot() {
  cylinder(d=bot_od, h=bot_h-collar_h-z_play);
  cylinder(d=collar_id-slip, h=bot_h-top_intrusion);
}

module collar(up=true) {
  translate([0, 0, up ? bot_h-collar_h-z_play/2 : 0]) {
    difference() {
      cylinder(d=collar_od, h=collar_h);
      translate([0, 0, -1])
        cylinder(d=collar_id, h=1000);
    }
  }
}

module top(up) {
  translate([0, 0, up ? bot_h : 0]) {
    cylinder(d=top_d, h=top_h);
    translate([0, 0, -top_intrusion])
      cylinder(d=collar_id-slip, h=top_h+top_intrusion);
  }
}

module preview() {
  bot();
  color("orange") collar();
  color("cyan") top();
}

module print() {
  bot();
  translate([bot_od+1, 0, 0])
    collar(up=false);
  translate([top_d*0.4, top_d-9, top_h])
    rotate([180, 0, 0])
      top(false);
}

print();