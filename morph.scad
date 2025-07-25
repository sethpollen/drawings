// Utilities for composing smooth solids from a list of cross-sections.

// Searches over a list of key/value pairs (sorted by key), returning
// the index of the pair with the largest key less than or equal to 'target'.
function _binsearch(target, pairs) = (
  _binsearch_impl(target, pairs, 0, len(pairs))
);
function _binsearch_impl(target, pairs, lo, hi) = (
  // Base case.
  hi == lo + 1 ? lo :
  // Recursive case.
  let (mid = floor((hi + lo) / 2))
  pairs[mid][0] <= target
  ? _binsearch_impl(target, pairs, mid, hi)
  : _binsearch_impl(target, pairs, lo, mid)
);

// Filters out slices which do not affect the resulting solid.
function _filter(slices) = (
  assert(len(slices) > 0, "No slices")
  let (last = len(slices)-1)
  [
    for (i = [0 : last]) if (
      // Always keep the start and end.
      i == 0 ||
      i == last ||
      // Keep interior slices only if they are not bordered on both sides by
      // identical slices.
      slices[i-1][1] != slices[i][1] ||
      slices[i+1][1] != slices[i][1]
    ) slices[i]
  ]
);
  
// Each element of 'slices' is a pair giving a Z-coordinate and a payload
// list of values. The result is a similar list with Z-coordinates spaced
// apart by $zstep and the payload values interpolated.
function _reslice(slices) = (
  assert(len(slices) > 0, "No slices")
  let (
    last = len(slices)-1,
    minz = slices[0][0],
    maxz = slices[last][0]
  )
  [
    for (z = [minz : $zstep : maxz]) (
      // Edge cases: No interpolation.
      z == minz ? [z, slices[0][1]] :
      z == maxz ? [z, slices[last][1]] :
    
      // Load the two bounding points between which to interpolate.
      let (
        lo = _binsearch(z, slices),
    
        lower_z = slices[lo][0],
        lower_payload = slices[lo][1],
        upper_z = slices[lo+1][0],
        upper_payload = slices[lo+1][1],
    
        // Interpolation ratio.
        r = (z - lower_z) / (upper_z - lower_z)
      )
      [z, upper_payload*r + lower_payload*(1-r)]
    )
  ]
);

// Interpolates between several slices in the z dimension. Each element of
// 'slices' is a pair giving a Z-coordinate and a payload list of values.
// $zstep determines the resolution. The children are expected to be 2-D.
// They are evaluated repeatedly to produces the slices of the morphed
// solid. Each time the children are evaluated, $m will contain an interpolated
// slice.
module morph(slices) {
  layers = _filter(_reslice(slices));
    
  // We intentionally throw out the last slice. Otherwise we would extrude
  // one zstep beyond the desired dimensions.
  last = len(layers)-2;
  
  for (i = [0 : last]) {
    z = layers[i][0];
    height = layers[i+1][0] - z;
    translate([0, 0, z]) {
      // Add 1% to make sure all of the layers actually overlap.
      linear_extrude(height * 1.01) {
        $m = layers[i][1];
        children();
      }
    }
  }
}

// A utility for generating slices to be passed to morph. This allows the
// z-coordinate to be used as one of the interpolated elements.
function dupfirst(slices) = [
  for (s = slices) [s[0], s]
];