#!/usr/bin/env fish

for i in (seq 4 18)
  openscad \
    --export-format=png \
    --projection=ortho \
    --camera=0,0,47,0,0,0 \
    --imgsize=200,200 \
    -o "$HOME/sbp/sbp_linux_config/openscad/genfiles/print_$i.png" \
    -D '$flat=true' \
    -D "printout=$i" \
    --colorscheme=Solarized \
    head_chips.scad
end
