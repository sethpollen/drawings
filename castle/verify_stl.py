#!/usr/bin/env python3
"""Verify watertightness, dimensions, flat base footprint, overhang angles, and print metrics for the castle STL."""
import os
import sys
import numpy as np
import trimesh

stl_path = sys.argv[1] if len(sys.argv) > 1 else "/home/pollen/drawings/castle/medieval_castle_290x250.stl"
print(f"Loading {stl_path} ({os.path.getsize(stl_path) / (1024*1024):.2f} MB)...")
mesh = trimesh.load(stl_path, force="mesh")

verts = mesh.vertices
faces = mesh.faces
bounds = mesh.bounds
extents = mesh.extents

print("\n=== DIMENSIONS ===")
print(f"X: [{bounds[0,0]:.3f}, {bounds[1,0]:.3f}] mm  (span = {extents[0]:.3f} mm)")
print(f"Y: [{bounds[0,1]:.3f}, {bounds[1,1]:.3f}] mm  (span = {extents[1]:.3f} mm)")
print(f"Z: [{bounds[0,2]:.3f}, {bounds[1,2]:.3f}] mm  (span = {extents[2]:.3f} mm)")

print("\n=== TOPOLOGY & MANIFOLDNESS ===")
print(f"Vertices:          {len(verts):,}")
print(f"Triangles:         {len(faces):,}")
print(f"Watertight:        {mesh.is_watertight}")
print(f"Winding consistent:{mesh.is_winding_consistent}")
print(f"Volume:            {mesh.volume / 1000.0:.1f} cm^3")
print(f"Surface area:      {mesh.area / 100.0:.1f} cm^2")
print(f"Euler number:      {mesh.euler_number}")
bodies = mesh.split(only_watertight=False)
print(f"Connected bodies:  {len(bodies)}")

# Check flat z=0 base footprint
normals = mesh.face_normals
areas = mesh.area_faces
z_tris = verts[faces, 2]
base_mask = (np.max(np.abs(z_tris), axis=1) < 0.05) & (normals[:, 2] < -0.99)
base_area_cm2 = areas[base_mask].sum() / 100.0
base_verts = verts[np.abs(verts[:, 2]) < 0.05]
print("\n=== FLAT FIRST LAYER (z = 0.000 mm) ===")
print(f"Base triangles:    {int(base_mask.sum()):,}")
print(f"Base contact area: {base_area_cm2:.1f} cm^2 ({100.0 * base_area_cm2 / (29.0 * 29.0):.1f}% of 290x290 mm square)")
if len(base_verts) > 0:
    print(f"Base X span:       [{base_verts[:,0].min():.3f}, {base_verts[:,0].max():.3f}] -> {base_verts[:,0].max() - base_verts[:,0].min():.3f} mm")
    print(f"Base Y span:       [{base_verts[:,1].min():.3f}, {base_verts[:,1].max():.3f}] -> {base_verts[:,1].max() - base_verts[:,1].min():.3f} mm")

# Overhang analysis (excluding flat z=0 bed contact)
non_base = ~base_mask
non_base_area = areas[non_base].sum()
nz = normals[non_base, 2]
na = areas[non_base]
# Overhang angle from vertical: angle = arcsin(-nz) for nz < 0
# >45 deg overhang means nz < -sin(45 deg) = -0.7071
# >55 deg overhang means nz < -sin(55 deg) = -0.8192
# >65 deg overhang means nz < -sin(65 deg) = -0.9063
oh45 = na[nz < -np.sin(np.deg2rad(45.0))].sum() / non_base_area * 100.0
oh55 = na[nz < -np.sin(np.deg2rad(55.0))].sum() / non_base_area * 100.0
oh65 = na[nz < -np.sin(np.deg2rad(65.0))].sum() / non_base_area * 100.0
print("\n=== FDM OVERHANG ANALYSIS (non-base surface) ===")
print(f"Overhang > 45 deg: {oh45:.3f}% of surface area")
print(f"Overhang > 55 deg: {oh55:.3f}% of surface area")
print(f"Overhang > 65 deg: {oh65:.3f}% of surface area")

# Rough PLA estimate (3 walls @ 0.42mm = 1.26mm shell + 10% gyroid infill, PLA 1.24 g/cm^3)
shell_vol_cm3 = (mesh.area / 100.0) * 0.126
interior_vol_cm3 = max(0.0, mesh.volume / 1000.0 - shell_vol_cm3)
est_pla_g = (shell_vol_cm3 + 0.10 * interior_vol_cm3) * 1.24
print(f"\n=== EST. FDM PRINT METRICS (0.4mm nozzle, 3 walls, 10% infill) ===")
print(f"Est. PLA filament: ~{est_pla_g:.0f} g (~{est_pla_g/1000.0:.2f} kg)")
