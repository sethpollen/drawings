A custom pickleball paddle with a curved grip. I've experimented with several
fully 3D printed paddles. This one is durable and versatile. When printed in
PETG, it has a good feel and responsiveness. The finished paddle weighs about
250 grams.

Personally I like the curved grip. It feels more ergonomic when reaching for a
far-away ball. The thumb lug and hook on the end of the handle facilitate quick,
one-handed grip changes, allowing diverse styles of play. See the photos for
the different grip holds that I use when playing with this paddle.

This paddle is about 15.5 inches long and 8 inches wide, which is compliant with
the USA Pickleball regulations for paddle size
(https://usapickleball.org/docs/rules/USAP-Equipment-Standards-Manual.pdf). I
do not know whether it complies with the regulations for surface roughness and
friction.

# Print settings

I recommend PETG. I've printed and used several PETG paddles, and they stand up
pretty well with normal use. The weak spot is the edge; they are prone to crack
if dropped onto a hard surface. I have printed workable paddles in PLA, and they
hold up well. But they are less responsive (less "springy") and have a "duller"
sound.

Both models are already oriented for printing. They fit within a 225mm x 225mm
build volume.

* Layer height: 0.15mm
* Floor: 6 layers
* Ceiling: 7 layers
* Infill: 10% honecomb
* Support: touching build plate only (for the finger joint protrusions). There
  is no need for support inside the cavities; they bridge just fine.

Note that `bottom.stl` contains several intentionally placed internal voids.
These are meant to cause your slicer to add extra material at key places,
avoiding weak spots in the final result. It is especially important that there
be a continuous ceiling for the whole print, without any interruption underneath
the thumb lug.

# Assembly instructions

1. Print the two pieces (`bottom.stl` and `top.stl`).

2. Lightly file or sand the undersides of the finger joint protrusions, to
   remove rough spots from the supports. This helps the pieces fit together
   smoothly.

3. Generously spread both finger joints with expoxy adhesive (I used JB Weld
   ClearWeld). Press the two pieces together. Insert a length of 1.75mm filament
   through the hole in the side of the paddle and push it through to the other
   side. This locks the two pieces together while the adhesive sets. Wipe off
   excess epoxy that squirts out of the joint.

4. Clamp the paddle to a flat surface to make sure the two pieces set in good
   alignment. This is optional; I think you'll get pretty good alignment just
   from the mating of the finger joint. You will probably want to put oil or
   Vaseline on the flat surface to keep any epoxy from sticking to it.

5. Once the epoxy has cured, snip off any excess from the piece of filament
   sticking out of the sides.

6. Sand the top surface of the paddle to remove the layer lines. This is
   optional, but it makes the texture more consistent between the two sides of
   the paddle.

# Tweaks

This paddle was created in OpenSCAD. You can find the source code at
https://github.com/sethpollen/drawings/tree/693eac99b73ce2ef4bbddbd91d39560510053811/pickle.
The two STL files are generated from `top.scad` and `bottom.scad`. Feel free to
tweak it; it should be straightforward to adjust the thickness, length, width,
and grip angle.
