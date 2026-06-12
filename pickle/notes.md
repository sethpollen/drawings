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

I think the extra wall line of Mk. 3 was overkill. Simply switching from PLA
to PETG should be enough to avoid denting the edges.

* 0.2mm layers.
* 10% grid infill.
* Floor: 3 layers of 100% plus 3 layers of 50% lines.
* Ceiling: 4 layers of 100% plus 3 layers of 50% lines.
* Walls: 2 lines (the default).
* Bottom layer inset: 0.2mm.
* Head temperature: 240 C.
* Print speed: 40 mm/s.
* Randomized Z seam alignment (to avoid weak spots).
* First layer overdrive:
  * 120% flow in general
  * 110% flow for outer walls

Also need to disable "extra infill lines to support skins," as my 50% layers
already do that.

## Notes

The 120% flow overdrive might be backfiring, causing weird artifacts on the
first layer. I can probably scale back to 110% initial layer flow. The adhesion
of PETG seems quite good.

The paddle broke after a few minutes of use. I believe the problem is that
the continuous sheet of the upper surface stopped abruptly at the shelf. So
under stress, the paddle cracked right there at the shelf. In the future, I need
to maintain that continuous sheet over the whole paddle.

# Mk. 5

Some changes relative to Mk. 4. In general I am walking back some of the
customization I tried earlier. For instance, I don't have evidence that the 50%
skin layers are needed with PETG. So set everything to the default and then
do just these overrides:

* 0.2mm layers.
* 10% grid infill.
* Floor: 3 layers of 100% plus one layer of 50%.
* Bottom layer inset: 0.2mm.
* Head temperature: 240 C.
* Print speed: 40 mm/s.
* Randomized Z seam alignment.
* First layer overdrive: 110%
