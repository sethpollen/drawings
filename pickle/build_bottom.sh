#!/usr/bin/env fish

openscad --export-format binstl \
  -o bottom_perforations.stl bottom_perforations.scad

scad-stl bottom.scad
