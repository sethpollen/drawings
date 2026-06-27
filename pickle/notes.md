# Mk. 6

Going back to some of the settings from Mk. 3 (which was my most successful
design so far). But I am still trying to avoid any modification of the infill.

Top and bottom are printed in PETG with these settings:

* 0.15mm layers
* Floor: 6 layers for `top`; 7 for `bottom`
* Ceiling: 8 layers for `top`; 9 for `bottom`
* 10% honeycomb infill. I was tempted to go back to my tried-and-true grid
  infill, but hexagonal avoids the intersection lines that cause material
  to accumulate on the print head. The hexagons are about the same size as the
  squares, so it should be about as strong.
* Bottom layer inset: 0.2mm
* Head temp: 240 C
* Print speed: 40 mm/s
* Randomized z seam alignment
* Infill skin support: DISABLED

Grip plate printed in TPU:

* 0.2mm layers
* 20% gyroid fill
* Bottom layer inset: 0.2mm
* Floor: 3 layers

## Notes

I think 0.15mm layers is key for strength. The honeycomb infill seems fine,
though grid infill is probably also fine.

# Mk. 5

Some changes relative to Mk. 4. In general I am walking back some of the
customization I tried earlier. For instance, I don't have evidence that the 50%
skin layers are needed with PETG. So set everything to the default and then
do just these overrides:

* 0.2mm layers.
* 10% gyroid infill.
* Floor: only 3 layers.
* Bottom layer inset: 0.2mm.
* Head temperature: 240 C.
* Print speed: 40 mm/s.
* Randomized Z seam alignment.
* First layer overdrive: 110%, but only for the wall layers.
* Skin support density: 80%.
* Infill line direction: 5 degrees.

"Infill skin support" does weird things with grid infill. But with gyroid it
seems well behaved, so I'll use it.

Note that the `bottom` piece was printed with slightly different settings.
The most important differences where these:

* Floor: 4 layers
* 10% grid infill
* First layer overdrive: 110% for everything

## Notes while printing

Even the 110% initial layer overdrive seems to cause problems. I suspect that
it causes extra material to cling to the extruder nozzle, which then falls
off in large clumps and disrupts the print. Let's go just use the default
flow of 100%; adhesion will probably still be just fine.

One worry I have is that the first knurl groove is a weak spot for the floor
layer. The paddle could separate there. Maybe I should add extra floor layers
over the knurl lines.

## Notes from use

The paddle failed very quickly while in use. Unlike Mk. 4, it seemed to have
a reasonably strong connection between grip and fan. But the gyroid infill
was clearly a bad idea, at least at the 10% density. After only a few hits,
the floor and ceiling had separated from the infill. The paddle still looked
intact, but its surface was yielding. You could hear the broken infill crinkling
when you pressed the surface. After a few minutes of hard (but reasonable) play,
the surface cracked, revealing loose strands of infill within.

Now that I think about it, grid infill is probably more solid at a low fill
percentage. The obliquely stacked gyroid layer lines probably dont' bond well
enough.

I should also probably not push the weight reduction so aggressively. Instead
of 3 floor layers and 4 ceiling layers, I should do 4 floor layers and 5
ceiling layers. An extra ceiling layer is justified because the first layer
is always pretty nasty, and I sand off some of the top layer.

Mk. 3 remains my only successful PETG paddle; the others have failed
spectacularly. It could be explained by Mk. 4's flawed grip design and Mk. 5's
use of gyroid infill. But remember that Mk. 3 also used 0.15mm layers. Maybe
that really does provide better bonding. I'll keep that in mind, but for now
I'm going to stick with 0.2mm.

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

# Mk. 1

Mk. 1 used an insert sandwiched between two pieces on both sides. The interfaces
were all large, flat surfaces held together by epoxy. This was a bad design. The
epoxy failed under repeated stress, the surfaces separated, and eventually the
insert broke.
