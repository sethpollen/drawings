# Mk. 1

Mk. 1 used an insert sandwiched between two pieces on both sides. The interfaces
were all large, flat surfaces held together by epoxy. This was a bad design. The
epoxy failed under repeated stress, the surfaces separated, and eventually the
insert broke.

# Mk. 2

Mk. 2 was printed in transparent PLA with two TPU grip pieces. It replaced
Mk. 1's insert with a finger joint, which worked well. The main problems with
Mk. 2 were as follows:

* The edges are squared off, which seems to make the corners weak. While the
  paddle surface shows no damage from repeated use, the edges are visibly dented
  by ball impacts.
* Part of this may be due to the use of PLA, which doesn't have great shock
  resistance. The paddle also has a somewhat "dead" feel in use, maybe because
  the PLA is not springy and responsive.

Specific material settings:

* 11% grid infill.
* 0.2mm layers.
* Floor and ceiling: 4 layers of 100%, plus 2 layers of 50% lines.
* Walls: 2 lines

# Mk. 3

Mk. 3 was printed in black PETG, with rounded edges and an extra line around
the edge. This resolved the major issues with Mk. 2.

Specific material settings:

* 10% grid infill.
* 0.15mm layers.
* Floor and ceiling: 6 layers of 100% plus 2 layers of 50% lines.
* Walls: 3 lines.
* Bottom layer inset: 0.2mm.
* Head temperature: 240 C (middle of the nominal range).
* Print speed: 40 mm/s (middle of the nominal range).

I switched to 0.15mm layers to try to get a better fit for the finger joint,
but it didn't really help. I also thought it might help with layer adhesion,
but I think I was too worried. PETG should have fine adhesion with 0.2mm layers.

# Mk. 4

I plan to use PETG again, but with 0.2mm layers. I noticed that the infill grids
struggle to form correctly with 0.15mm layers.

TODO:

2. Flatten the top of the handle like the bottom.
3. Make handle less wide.
5. Make knurl grooves shallower.
