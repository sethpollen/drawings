use <creeper.scad>
use <enderman.scad>
use <evoker.scad>
use <ghast.scad>
use <hero.scad>
use <skeleton.scad>
use <zombie.scad>

translate([-50, 0, 0]) enderman_preview();
translate([0, 0, 0]) skeleton_preview();
translate([50, 0, 0]) zombie_preview();
translate([0, 0, 80]) hero_preview();
translate([50, 0, 80]) creeper_preview();
translate([-50, 0, 80]) evoker_preview();
translate([-50, 0, -80]) ghast_preview();