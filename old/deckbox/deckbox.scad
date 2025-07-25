nozzle_width= 0.4;
layer_height= 0.16;

// Want interior volume: 64 x 55 x 90

deckbox_width= 71.5;
deckbox_total_height= 91.92;
deckbox_lid_height= 20;
deckbox_depth= 62.5;

sleeve_height= 12;
sleeve_xy_gap= 0.25; // decrease if the fit is too loose, increase if it's too tight
sleeve_z_gap= (4 * layer_height);
sleeve_wall_thickness= (4 * nozzle_width);

hex_pattern_cell_radius= (deckbox_width / 12);
hex_pattern_line_width= 1.5;
hex_pattern_depth= (0.75 * nozzle_width);

inner_sleeve_wall_thickness= sleeve_wall_thickness;
outer_sleeve_wall_thickness= (sleeve_wall_thickness + hex_pattern_depth);
total_sidewall_thickness= (
	inner_sleeve_wall_thickness +
	sleeve_xy_gap + 
	outer_sleeve_wall_thickness);

// NOTE: The floor intionally doesn't factor in hex_pattern_depth to
// avoid generating any mostly-hollow layers.
floor_thickness= (6 * layer_height);

deck_cavity_size= [
	(deckbox_width - (2 * total_sidewall_thickness)),
	(deckbox_depth - (2 * total_sidewall_thickness)),
	(deckbox_total_height - (2 * floor_thickness))];

echo("This deckbox has a cavity-size of ", deck_cavity_size);

emblem_frame_width= (0.85 * deckbox_width);
emblem_depth= (0.75 * nozzle_width);

plating_xy_separation= 10;

bevel_size= 1; // length of the beveled edge itself is (sqrt(2) * bevel_size)

csg_overlap= 0.02;

unit_hexagon_inner_radius= (sqrt(3) / 2);

unit_hexagon_points= [
	[1, 0], 
	[0.5, unit_hexagon_inner_radius], 
	[-0.5, unit_hexagon_inner_radius],
	[-1, 0],
	[-0.5, -unit_hexagon_inner_radius], 
	[0.5, -unit_hexagon_inner_radius]];

module hexagon_lattice_unbounded(
	lattice_size,
	hex_cell_radius,
	separation_gap)
{	
	// convert the hexagonal grid into a rectangular grid of hex-cell-pairs
	rect_cell_width= (3 * hex_cell_radius);
	rect_cell_height= (2 * (unit_hexagon_inner_radius * hex_cell_radius));
	
	column_count= ceil((lattice_size[0] + hex_cell_radius) / rect_cell_width);
	row_count= ceil((lattice_size[1] + hex_cell_radius) / rect_cell_height);
	
	union()
	{	
		for (row_index= [0 : (row_count - 1)])
		{
			translate([
				0,
				(row_index * rect_cell_height),
				0])
			for (column_index= [0 : (column_count - 1)])
			{
				translate([
					(column_index * rect_cell_width), 
					0, 
					0])
				union()
				{
					scale((hex_cell_radius - (separation_gap / 2)))
					polygon(points= unit_hexagon_points);
					
					translate([
						(hex_cell_radius + (hex_cell_radius / 2)),
						(rect_cell_height / 2),
						0])
					scale((hex_cell_radius - (separation_gap / 2)))
					polygon(points= unit_hexagon_points);
				}
			}
		}
	}
}

module hexagon_lattice_bounded(
	lattice_size,
	hex_cell_radius,
	separation_gap,
	is_positive= true)
{
	difference()
	{
		if (!is_positive)
		{
			translate([-csg_overlap, -csg_overlap])
			square([
				(lattice_size[0] + (2 * csg_overlap)),
				(lattice_size[1] + (2 * csg_overlap))]);
		}
		
		intersection()
		{
			square(lattice_size);
			
			hexagon_lattice_unbounded(
				lattice_size,
				hex_cell_radius,
				separation_gap);
		}
	}
}

module beveled_cube(
	size,
	center= false)
{
	promoted_size= (
		(str(size)[0] != "[") ?
			[size, size, size] :
			size);
	
	beveled_size= (promoted_size - (2 * [bevel_size, bevel_size, bevel_size]));
	
	subcube_offset= (center == true) ? 0 : bevel_size;
	
	hull()
	{
		translate([0, subcube_offset, subcube_offset])
		cube(
			size= [promoted_size[0], beveled_size[1], beveled_size[2]], 
			center= center);
			
		translate([subcube_offset, 0, subcube_offset])
		cube(
			size= [beveled_size[0], promoted_size[1], beveled_size[2]], 
			center= center);
			
		translate([subcube_offset, subcube_offset, 0])
		cube(
			size= [beveled_size[0], beveled_size[1], promoted_size[2]], 
			center= center);
	}
}

module deckbox_face_pattern(
	side_size,
	is_positive)
{
	translate([0, 0, -csg_overlap])
	linear_extrude(
		height= (hex_pattern_depth + csg_overlap),
		convexity= 4)
	hexagon_lattice_bounded(
		lattice_size= side_size,
		hex_cell_radius= hex_pattern_cell_radius,
		separation_gap= (hex_pattern_line_width / 2),
		is_positive= is_positive);
}

module deckbox_front_hex_pattern(
	have_emblem)
{
	emblem_frame_outer_radius=
		(emblem_frame_width / (2 * unit_hexagon_inner_radius));
	
	union()
	{
		difference()
		{
			scale([1, -1, 1])
			rotate([90, 0, 0])
			deckbox_face_pattern(
				[deckbox_width, deckbox_total_height],
				is_positive= true);
			
			if (have_emblem)
			{
				translate([
					(deckbox_width / 2),
					(hex_pattern_depth + csg_overlap),
					(deckbox_total_height / 2)])
				rotate([90, 0, 0])
				linear_extrude(height= (hex_pattern_depth + (2 * csg_overlap)))
				scale(emblem_frame_outer_radius)
				rotate([0, 0, 90])
				polygon(unit_hexagon_points);
			}
		}			
		
		if (have_emblem)
		{
			translate([
				(deckbox_width / 2),
				hex_pattern_depth,
				(deckbox_total_height / 2)])
			rotate([90, 0, 0])
			linear_extrude(height= (hex_pattern_depth + csg_overlap))
			scale(emblem_frame_outer_radius - hex_pattern_line_width)
			rotate([0, 0, 90])
			polygon(unit_hexagon_points);
		}
	}
}

module deckbox_front_emblem(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{
	color("SlateGray")
	translate([
		(deckbox_width / 2),
		(hex_pattern_depth + csg_overlap),
		(deckbox_total_height / 2)])
	rotate([90, 0, 0])
	linear_extrude(height= (emblem_depth + csg_overlap))
	translate(emblem_xy_offset)
	scale(emblem_scale)
	import(emblem_filename);
}

module deckbox_left_hex_pattern()
{
	rotate([0, 0, 90])
	rotate([90, 0, 0])
	deckbox_face_pattern(
		[deckbox_depth, deckbox_total_height],
		is_positive= true);
}

module deckbox_bottom_hex_pattern()
{
	is_aligned_to_front_face= true;
	
	if (is_aligned_to_front_face)
	{
		deckbox_face_pattern(
			[deckbox_width, deckbox_depth],
			is_positive= false);
	}
	else
	{
		translate([deckbox_width, 0, 0])
		rotate([0, 0, 90])
		deckbox_face_pattern(
			[deckbox_depth, deckbox_width],
			is_positive= false);
	}
}

module deckbox_body_decoration_negative(
	have_emblem)
{
	union()
	{		
		// front
		deckbox_front_hex_pattern(have_emblem);
		
		// back
		translate([deckbox_width, deckbox_depth, 0])
		rotate([0, 0, 180])
		deckbox_front_hex_pattern(have_emblem);
		
		// left
		deckbox_left_hex_pattern();
		
		// right
		translate([deckbox_width, deckbox_depth, 0])
		rotate([0, 0, 180])
		deckbox_left_hex_pattern();

		// bottom
		deckbox_bottom_hex_pattern();

		// top
		translate([0, deckbox_depth, deckbox_total_height])
		rotate([180, 0, 0])
		deckbox_bottom_hex_pattern();
	}
}

module deckbox_body_decoration_positive(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{
	union()
	{
		// front
		deckbox_front_emblem(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);
	
		// back
		translate([deckbox_width, deckbox_depth, 0])
		rotate([0, 0, 180])
		deckbox_front_emblem(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);
	}
}

module decorated_deckbox_body(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{
	have_emblem= (len(emblem_filename) > 1);
	
	union()
	{
		difference()
		{
			beveled_cube(size= [
				deckbox_width, 
				deckbox_depth, 
				deckbox_total_height]);
			
			deckbox_body_decoration_negative(
				have_emblem);
		}
		
		deckbox_body_decoration_positive(
			emblem_filename,					
			emblem_scale,
			emblem_xy_offset);
	}
}

module convert_to_deckbox_bottom()
{	
	difference()
	{
		union()
		{
			difference()
			{
				child(0);
				
				translate([
					-csg_overlap, 
					-csg_overlap, 
					(deckbox_total_height - deckbox_lid_height)])
				cube(size= [
					(deckbox_width + (2 * csg_overlap)),
					(deckbox_depth + (2 * csg_overlap)),
					(deckbox_lid_height + csg_overlap)]);
			}
						
			translate([
				(total_sidewall_thickness - inner_sleeve_wall_thickness), 
				(total_sidewall_thickness - inner_sleeve_wall_thickness), 
				floor_thickness])
			beveled_cube(size= [
				(deck_cavity_size[0] + (2 * inner_sleeve_wall_thickness)),
				(deck_cavity_size[1] + (2 * inner_sleeve_wall_thickness)),
				(((deckbox_total_height - deckbox_lid_height) + sleeve_height) - floor_thickness)]);
		}

		translate([
			total_sidewall_thickness, 
			total_sidewall_thickness, 
			floor_thickness])
		cube(size= deck_cavity_size);
	}
}

module convert_to_deckbox_lid()
{
	difference()
	{
		child(0);
		
		translate([
			-csg_overlap, 
			-csg_overlap, 
			-csg_overlap])
		cube(size= [
			(deckbox_width + (2 * csg_overlap)),
			(deckbox_depth + (2 * csg_overlap)),
			((deckbox_total_height - deckbox_lid_height) + csg_overlap)]);
			
		translate([
			outer_sleeve_wall_thickness, 
			outer_sleeve_wall_thickness, 
			((deckbox_total_height - deckbox_lid_height) - csg_overlap)])
		cube(size= [
			(deckbox_width - (2 * outer_sleeve_wall_thickness)),
			(deckbox_depth - (2 * outer_sleeve_wall_thickness)),
			(sleeve_height + sleeve_z_gap + csg_overlap)]);

		translate([
			total_sidewall_thickness, 
			total_sidewall_thickness, 
			floor_thickness])
		cube(size= deck_cavity_size);
	}
}

module deckbox_whole(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{	
	union()
	{
		convert_to_deckbox_bottom()		
		decorated_deckbox_body(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);
		
		convert_to_deckbox_lid()		
		decorated_deckbox_body(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);
	}
}

module deckbox_plate(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{	
	union()
	{
		convert_to_deckbox_bottom()		
		decorated_deckbox_body(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);
		
		translate([0, ((2 * deckbox_depth) + plating_xy_separation), 0])
		rotate([180, 0, 0])
		translate([0, 0, -deckbox_total_height])
		convert_to_deckbox_lid()		
		decorated_deckbox_body(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);
	}
}

*deckbox_plate(
	emblem_filename= "haas_bioroid_emblem.dxf",
	emblem_scale= 0.7,
	emblem_xy_offset= [0, 0]);
	
*deckbox_plate(
	emblem_filename= "shaper_emblem.dxf",
	emblem_scale= 0.7,
	emblem_xy_offset= [0, 0]);
	
deckbox_plate(
	emblem_filename= "",
	emblem_scale= 1,
	emblem_xy_offset= [0, 0]);