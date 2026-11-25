// castle_sculptor.cpp
// High-resolution procedural 3D Signed Distance Field (SDF) medieval castle sculptor
// "Ironcrest Keep" — 290.0 x 284.4 x 215.0 mm flat-base FDM LEGO-compatible playset:
//   - 15.0 mm smooth courtyard, 20.0 mm thinned straight walls with 45-deg inner corbelled walks
//   - 25.9 mm wide wall walks (fits full 3-stud LEGO bricks), 20.0 mm tall parapets
//   - Outward-bulging flush-interior gatehouse with smooth pass-through Gothic tunnel
//   - Four corner bastion turrets (front deck 94 mm / merlons 114 mm, rear deck 102 mm / merlons 122 mm)
//   - Open-back 2-level Keep (roof 195 mm / merlons 215 mm) with pass-through Gothic lancet windows
//   - ~1,040 FDM-tolerant LEGO-compatible studs (8.00 mm pitch, 4.70 mm dia, 1.70 mm height)
//
// Compile: g++ -O3 -march=native -fopenmp -std=c++17 castle_sculptor.cpp -o castle_sculptor
// Render:  ./castle_sculptor render previews
// Mesh:    ./castle_sculptor mesh . 0.421 2000000

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <omp.h>
#include <queue>
#include <string>
#include <unordered_map>
#include <vector>

static constexpr float PI = 3.14159265358979323846f;
static constexpr float TAU = 2.0f * PI;

// ============================================================================
// Single Source of Truth: Master Castle Dimensions & LEGO Stud Specifications
// Shared by legoStudsSDF(), castleSDF(), and extractWatertightMesh() so floor
// heights, wall bounds, turret centers, and stud grids can never drift apart.
// ============================================================================
namespace CastleSpec {
    // Overall envelope (mm) — expanded slightly to accommodate +10 mm wider turrets at fixed centers (±110)
    static constexpr float HALF_X = 149.0f;
    static constexpr float HALF_Y = 149.0f;

    // Walkable floor & parapet elevations (mm above z = 0 flat build-plate base)
    static constexpr float Z_COURT      = 15.0f;  // Open courtyard & gate tunnel floor
    static constexpr float Z_L1_FLOOR   = 23.0f;  // Keep Level 1 floor (ceiling z = 102.0 -> 79 mm clear)
    static constexpr float Z_WALL_DECK  = 75.0f;  // Curtain wall walks & gatehouse top deck
    static constexpr float PARA_H       = 22.0f;  // +2 mm taller parapet (22 mm above walkable floor)
    static constexpr float Z_WALL_PARA  = Z_WALL_DECK + PARA_H;  // 97.0 mm
    static constexpr float Z_TWR_F_DECK = 94.0f;  // Front corner turret decks (merlons 116.0 mm)
    static constexpr float Z_TWR_R_DECK = 102.0f; // Rear corner turret decks  (merlons 124.0 mm)
    static constexpr float Z_L2_FLOOR   = 109.0f; // Keep Level 2 floor (ceiling z = 187.0 -> 78 mm clear)
    static constexpr float Z_KEEP_DECK  = 195.0f; // Keep flat roof deck
    static constexpr float Z_KEEP_PARA  = Z_KEEP_DECK + PARA_H;  // 217.0 mm (total castle height)

    // Outer curtain walls (20.0 mm main thickness below z = 63; 45-deg inner corbel z = 63..73.5; 25.9 mm walk)
    // Shortened 8.0 mm front-to-back by moving front curtain wall, front turrets & gatehouse +8.0 mm in +Y.
    static constexpr float WALL_OUT_X        = 123.5f;
    static constexpr float WALL_OUT_Y_MIN    = -100.5f;
    static constexpr float WALL_OUT_Y_MAX    =  123.5f;
    static constexpr float WALL_Y_C          = 0.5f * (WALL_OUT_Y_MIN + WALL_OUT_Y_MAX); // +11.5f
    static constexpr float WALL_Y_H          = 0.5f * (WALL_OUT_Y_MAX - WALL_OUT_Y_MIN); // 112.0f
    static constexpr float WALL_CORB_OUT     = 3.0f;
    static constexpr float WALL_BASE_BAT_H   = 25.0f; // bottom 25 mm wall base batter height
    static constexpr float WALL_BASE_BAT_OUT = 12.0f; // pronounced +12.0 mm horizontal flare (~64.4-deg slope)
    static constexpr float WALL_PARA_OUT_X   = WALL_OUT_X + WALL_CORB_OUT;     // 126.5f
    static constexpr float WALL_PARA_OUT_Y0  = WALL_OUT_Y_MIN - WALL_CORB_OUT; // -103.5f
    static constexpr float WALL_PARA_OUT_Y1  = WALL_OUT_Y_MAX + WALL_CORB_OUT; // +126.5f
    static constexpr float WALL_WALK_OUT_X   = 118.9f;  // inner parapet face (7.6 mm thick parapet)
    static constexpr float WALL_WALK_OUT_Y0  = -95.9f;
    static constexpr float WALL_WALK_OUT_Y1  =  118.9f;
    static constexpr float WALL_WALK_IN_X    =  93.0f;  // upper walkway inner edge (25.9 mm wide walk)
    static constexpr float WALL_WALK_IN_Y0   = -70.0f;
    static constexpr float WALL_WALK_IN_Y1   =  93.0f;
    static constexpr float WALL_COURT_IN_X   = 103.5f;  // lower courtyard wall inner face (20.0 mm thick wall)
    static constexpr float WALL_COURT_IN_Y0  = -80.5f;
    static constexpr float WALL_COURT_IN_Y1  =  103.5f;
    static constexpr float WALL_COURT_HY_LOW = 0.5f * (WALL_COURT_IN_Y1 - WALL_COURT_IN_Y0); // 92.0f
    static constexpr float WALL_COURT_HY_TOP = 0.5f * (WALL_WALK_IN_Y1  - WALL_WALK_IN_Y0);  // 81.5f

    // Corner bastion turrets (identical size/details; front turrets shifted +8.0 mm in +Y to (±110, -87))
    static constexpr float TWR_X      = 110.0f;
    static constexpr float TWR_F_Y    = -87.0f;
    static constexpr float TWR_R_Y    =  110.0f;
    static constexpr float TWR_F_R    = 32.5f; // Ø65 mm shaft, Ø71 mm crown, Ø56.2 mm inner deck
    static constexpr float TWR_R_R    = 33.0f; // Ø66 mm shaft, Ø72 mm crown, Ø57.2 mm inner deck
    static constexpr float TWR_F_R_IN = 28.1f;
    static constexpr float TWR_R_R_IN = 28.6f;

    // Rear turret stair step elevations (steps 0..2 stay below 97 mm side parapet; step 3 enters turret crown)
    static constexpr float TWR_R_STAIR_Z[4] = {81.60f, 88.20f, 94.80f, Z_TWR_R_DECK};

    // Outward-bulging gatehouse (identical size/details; shifted +8.0 mm in +Y flush with front curtain wall)
    static constexpr float GH_HALF_X      = 38.0f;
    static constexpr float GH_PARA_HALF_X = 40.5f;
    static constexpr float GH_WALK_HALF_X = 32.9f;
    static constexpr float GH_Y_MIN       = -114.5f; // outer main wall (+14.0 mm ahead of front wall)
    static constexpr float GH_Y_MAX       = WALL_WALK_IN_Y0; // -70.0f (flush with front walk inner edge)
    static constexpr float GH_Y_C         = 0.5f * (GH_Y_MIN + GH_Y_MAX); // -92.25f
    static constexpr float GH_Y_H         = 0.5f * (GH_Y_MAX - GH_Y_MIN); // 22.25f
    static constexpr float GH_PARA_Y_MIN  = -117.5f; // outer parapet face
    static constexpr float GH_WALK_Y_MIN  = -109.9f; // inner parapet face (7.6 mm thick parapet)
    static constexpr float GH_COURT_LOW_Y = WALL_COURT_IN_Y0; // -80.5f (flush with thinned front wall)
    static constexpr float GATE_HALF_W    = 19.0f;   // 38.0 mm wide smooth Gothic gate tunnel

    // Central open-back Keep (shortened 13.0 mm front-to-back: y in [+49, +123.5] = 74.5 mm deep, flush with rear wall)
    static constexpr float KEEP_X0 = -52.0f;
    static constexpr float KEEP_X1 =  52.0f;
    static constexpr float KEEP_Y0 =  49.0f;
    static constexpr float KEEP_Y1 = WALL_OUT_Y_MAX; // 123.5f
    static constexpr float KEEP_CX = 0.0f;
    static constexpr float KEEP_CY = 0.5f * (KEEP_Y0 + KEEP_Y1); // 86.25f
    static constexpr float KEEP_HX = 0.5f * (KEEP_X1 - KEEP_X0); // 52.0f
    static constexpr float KEEP_HY = 0.5f * (KEEP_Y1 - KEEP_Y0); // 37.25f

    // Precision FDM-tolerant LEGO-compatible stud parameters (calibrated from test print: 4.70 -> 4.60 mm printed)
    static constexpr float LEGO_PITCH   = 8.00f; // exact standard LEGO stud pitch
    static constexpr float LEGO_STUD_R  = 2.45f; // 4.90 mm modeled -> ~4.80 mm printed for crisp minifig click!
    static constexpr float LEGO_STUD_H  = 1.70f; // standard LEGO stud height
    static constexpr float LEGO_CHAMFER = 0.20f; // 0.20 mm 45-deg lead-in top chamfer

    // Exact horizontal Z planes snapped to 0.000 mm during mesh projection
    static constexpr float FLAT_FLOORS[7] = {
        Z_COURT, Z_L1_FLOOR, Z_WALL_DECK, Z_TWR_F_DECK, Z_TWR_R_DECK, Z_L2_FLOOR, Z_KEEP_DECK
    };
    static constexpr float STUD_TOPS[7] = {
        Z_COURT      + LEGO_STUD_H,
        Z_L1_FLOOR   + LEGO_STUD_H,
        Z_WALL_DECK  + LEGO_STUD_H,
        Z_TWR_F_DECK + LEGO_STUD_H,
        Z_TWR_R_DECK + LEGO_STUD_H,
        Z_L2_FLOOR   + LEGO_STUD_H,
        Z_KEEP_DECK  + LEGO_STUD_H
    };
} // namespace CastleSpec

struct Vec3 {
    float x, y, z;
    inline Vec3() : x(0), y(0), z(0) {}
    inline Vec3(float a, float b, float c) : x(a), y(b), z(c) {}
    inline Vec3 operator+(const Vec3& o) const { return {x + o.x, y + o.y, z + o.z}; }
    inline Vec3 operator-(const Vec3& o) const { return {x - o.x, y - o.y, z - o.z}; }
    inline Vec3 operator-() const { return {-x, -y, -z}; }
    inline Vec3 operator*(float s) const { return {x * s, y * s, z * s}; }
    inline Vec3 operator/(float s) const { float inv = 1.0f / s; return {x * inv, y * inv, z * inv}; }
};

inline Vec3 operator*(float s, const Vec3& v) { return {v.x * s, v.y * s, v.z * s}; }
inline float dot(const Vec3& a, const Vec3& b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
inline Vec3 cross(const Vec3& a, const Vec3& b) {
    return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}
inline float length(const Vec3& v) { return std::sqrt(dot(v, v)); }
inline Vec3 normalize(const Vec3& v) {
    float l = length(v);
    return (l > 1e-12f) ? (v / l) : Vec3(0, 0, 1);
}
inline float clampf(float v, float lo, float hi) { return v < lo ? lo : (v > hi ? hi : v); }
inline float lerpf(float a, float b, float t) { return a + (b - a) * t; }
inline float smoothstep(float e0, float e1, float x) {
    float t = clampf((x - e0) / (e1 - e0), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

// ============================================================================
// Deterministic Fast Hashing & 3D Value/Worley Noise for Realistic Stone/Rock
// ============================================================================
inline uint32_t hash_u32(uint32_t x) {
    x ^= x >> 16;
    x *= 0x7feb352du;
    x ^= x >> 15;
    x *= 0x846ca68bu;
    x ^= x >> 16;
    return x;
}

inline float hash21(int ix, int iy) {
    uint32_t h = hash_u32(uint32_t(ix) * 374761393u + uint32_t(iy) * 668265263u + 1442695041u);
    return float(h & 0x00FFFFFFu) * (1.0f / 16777216.0f);
}

inline float hash31(int ix, int iy, int iz) {
    uint32_t h = hash_u32(uint32_t(ix) * 374761393u + uint32_t(iy) * 668265263u + uint32_t(iz) * 2147483647u);
    return float(h & 0x00FFFFFFu) * (1.0f / 16777216.0f);
}

inline float vnoise2(float x, float y) {
    int ix = (int)std::floor(x);
    int iy = (int)std::floor(y);
    float fx = x - ix, fy = y - iy;
    float ux = fx * fx * (3.0f - 2.0f * fx);
    float uy = fy * fy * (3.0f - 2.0f * fy);
    float a = hash21(ix, iy);
    float b = hash21(ix + 1, iy);
    float c = hash21(ix, iy + 1);
    float d = hash21(ix + 1, iy + 1);
    return lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uy);
}

inline float vnoise3(float x, float y, float z) {
    int ix = (int)std::floor(x);
    int iy = (int)std::floor(y);
    int iz = (int)std::floor(z);
    float fx = x - ix, fy = y - iy, fz = z - iz;
    float ux = fx * fx * (3.0f - 2.0f * fx);
    float uy = fy * fy * (3.0f - 2.0f * fy);
    float uz = fz * fz * (3.0f - 2.0f * fz);
    float n000 = hash31(ix, iy, iz);
    float n100 = hash31(ix + 1, iy, iz);
    float n010 = hash31(ix, iy + 1, iz);
    float n110 = hash31(ix + 1, iy + 1, iz);
    float n001 = hash31(ix, iy, iz + 1);
    float n101 = hash31(ix + 1, iy, iz + 1);
    float n011 = hash31(ix, iy + 1, iz + 1);
    float n111 = hash31(ix + 1, iy + 1, iz + 1);
    float nx00 = lerpf(n000, n100, ux);
    float nx10 = lerpf(n010, n110, ux);
    float nx01 = lerpf(n001, n101, ux);
    float nx11 = lerpf(n011, n111, ux);
    return lerpf(lerpf(nx00, nx10, uy), lerpf(nx01, nx11, uy), uz);
}

inline float fbm3(float x, float y, float z, int octaves = 3) {
    float val = 0.0f, amp = 0.5f, freq = 1.0f;
    for (int i = 0; i < octaves; ++i) {
        val += amp * (vnoise3(x * freq, y * freq, z * freq) * 2.0f - 1.0f);
        freq *= 2.07f;
        amp *= 0.5f;
    }
    return val;
}

inline void voronoi2D(float x, float y, float& edgeDist, float& cellRand) {
    int ix = (int)std::floor(x);
    int iy = (int)std::floor(y);
    float f1 = 1e9f, f2 = 1e9f;
    int bestX = 0, bestY = 0;
    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            int cx = ix + dx, cy = iy + dy;
            float rx = hash21(cx * 17 + 3, cy * 31 + 7);
            float ry = hash21(cx * 29 + 11, cy * 13 + 19);
            float px = (cx + 0.15f + 0.70f * rx) - x;
            float py = (cy + 0.15f + 0.70f * ry) - y;
            float d = std::sqrt(px * px + py * py);
            if (d < f1) {
                f2 = f1; f1 = d;
                bestX = cx; bestY = cy;
            } else if (d < f2) {
                f2 = d;
            }
        }
    }
    edgeDist = f2 - f1;
    cellRand = hash21(bestX * 43 + 5, bestY * 59 + 13);
}

// ============================================================================
// SDF Primitives & Smooth Operations (Strictly Continuous Everywhere!)
// ============================================================================
inline float smin(float a, float b, float k) {
    if (k <= 1e-6f) return std::min(a, b);
    float h = clampf(0.5f + 0.5f * (b - a) / k, 0.0f, 1.0f);
    return lerpf(b, a, h) - k * h * (1.0f - h);
}

inline float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

inline float sdBox(const Vec3& p, const Vec3& c, const Vec3& h, float r = 0.0f) {
    float qx = std::fabs(p.x - c.x) - (h.x - r);
    float qy = std::fabs(p.y - c.y) - (h.y - r);
    float qz = std::fabs(p.z - c.z) - (h.z - r);
    float ox = std::max(qx, 0.0f);
    float oy = std::max(qy, 0.0f);
    float oz = std::max(qz, 0.0f);
    return std::sqrt(ox * ox + oy * oy + oz * oz) + std::min(std::max(qx, std::max(qy, qz)), 0.0f) - r;
}

inline float sdBoxMinMax(const Vec3& p, float x0, float x1, float y0, float y1, float z0, float z1, float r = 0.0f) {
    return sdBox(p, {0.5f * (x0 + x1), 0.5f * (y0 + y1), 0.5f * (z0 + z1)},
                    {0.5f * (x1 - x0), 0.5f * (y1 - y0), 0.5f * (z1 - z0)}, r);
}

inline float sdCylinderZ(const Vec3& p, float cx, float cy, float rad, float z0, float z1, float r = 0.0f) {
    float dr = std::hypot(p.x - cx, p.y - cy) - (rad - r);
    float dz = std::fabs(p.z - 0.5f * (z0 + z1)) - (0.5f * (z1 - z0) - r);
    return std::hypot(std::max(dr, 0.0f), std::max(dz, 0.0f)) + std::min(std::max(dr, dz), 0.0f) - r;
}

inline float sdConeFrustumZ(const Vec3& p, float cx, float cy, float z0, float z1, float r0, float r1) {
    float qx = std::hypot(p.x - cx, p.y - cy);
    float qy = p.z - z0;
    float h = z1 - z0;
    float bx = r1 - r0, by = h;
    float px = qx - r0, py = qy;
    float t = clampf((px * bx + py * by) / (bx * bx + by * by), 0.0f, 1.0f);
    float d_side = std::hypot(px - t * bx, py - t * by);
    float r_at_z = lerpf(r0, r1, clampf(qy / h, 0.0f, 1.0f));
    bool inside_r = (qx <= r_at_z);
    float d_caps = std::max(-qy, qy - h);
    if (d_caps <= 0.0f && inside_r) return -std::min(d_side, -d_caps);
    if (d_caps > 0.0f) {
        float rc = (qy < 0.0f) ? r0 : r1;
        return std::hypot(std::max(qx - rc, 0.0f), d_caps);
    }
    return d_side;
}

inline float sdGothicArch2D(float u, float z, float hw, float z_base, float z_spring, float z_peak) {
    float au = std::fabs(u);
    float archH = z_peak - z_spring;
    float c = (archH * archH - hw * hw) / (2.0f * hw);
    float R = hw + c;

    float d_bot = z_base - z;
    float d_side = au - hw;
    float d_arc = std::hypot(au + c, z - z_spring) - R;
    float d_arch = (z <= z_spring) ? d_side : d_arc;
    return std::max(d_bot, d_arch);
}

inline float sdGothicTunnelY(const Vec3& p, float cx, float hw, float y0, float y1, float z_base, float z_spring, float z_peak) {
    float d2 = sdGothicArch2D(p.x - cx, p.z, hw, z_base, z_spring, z_peak);
    float dy = std::fabs(p.y - 0.5f * (y0 + y1)) - 0.5f * (y1 - y0);
    return std::hypot(std::max(d2, 0.0f), std::max(dy, 0.0f)) + std::min(std::max(d2, dy), 0.0f);
}

inline float sdGothicTunnelX(const Vec3& p, float cy, float hw, float x0, float x1, float z_base, float z_spring, float z_peak) {
    float d2 = sdGothicArch2D(p.y - cy, p.z, hw, z_base, z_spring, z_peak);
    float dx = std::fabs(p.x - 0.5f * (x0 + x1)) - 0.5f * (x1 - x0);
    return std::hypot(std::max(d2, 0.0f), std::max(dx, 0.0f)) + std::min(std::max(d2, dx), 0.0f);
}

inline float sdBatteredBox(const Vec3& p, float cx, float cy, float z0, float z1,
                           float hx0, float hy0, float hx1, float hy1, float r = 0.7f) {
    float t = clampf((p.z - z0) / (z1 - z0), 0.0f, 1.0f);
    float hx = lerpf(hx0, hx1, t);
    float hy = lerpf(hy0, hy1, t);
    float sx = (hx1 - hx0) / (z1 - z0);
    float sy = (hy1 - hy0) / (z1 - z0);
    float invSlopeX = 1.0f / std::sqrt(1.0f + sx * sx);
    float invSlopeY = 1.0f / std::sqrt(1.0f + sy * sy);

    float qx = (std::fabs(p.x - cx) - (hx - r)) * invSlopeX;
    float qy = (std::fabs(p.y - cy) - (hy - r)) * invSlopeY;
    float qz = std::fabs(p.z - 0.5f * (z0 + z1)) - (0.5f * (z1 - z0) - r);
    float ox = std::max(qx, 0.0f), oy = std::max(qy, 0.0f), oz = std::max(qz, 0.0f);
    return std::sqrt(ox * ox + oy * oy + oz * oz) + std::min(std::max(qx, std::max(qy, qz)), 0.0f) - r;
}

// Seamless corbel + vertical parapet box (single continuous solid from z0 -> z_corb_top -> z1, ZERO horizontal gap!)
inline float sdCorbelParapetBox(const Vec3& p, float cx, float cy0, float cy1,
                                float z0, float z_corb_top, float z1,
                                float hx0, float hy0, float hx1, float hy1, float r = 0.65f) {
    float t  = clampf((p.z - z0) / (z_corb_top - z0), 0.0f, 1.0f);
    float cy = lerpf(cy0, cy1, t);
    float hx = lerpf(hx0, hx1, t);
    float hy = lerpf(hy0, hy1, t);
    float qx = std::fabs(p.x - cx) - (hx - r);
    float qy = std::fabs(p.y - cy) - (hy - r);
    float qz = std::fabs(p.z - 0.5f * (z0 + z1)) - (0.5f * (z1 - z0) - r);
    float d2 = std::hypot(std::max(qx, 0.0f), std::max(qy, 0.0f)) + std::min(std::max(qx, qy), 0.0f);
    if (p.z < z_corb_top) d2 *= 0.84f;
    return std::hypot(std::max(d2, 0.0f), std::max(qz, 0.0f)) + std::min(std::max(d2, qz), 0.0f) - r;
}

// Seamless corbel + vertical parapet cylinder (ZERO horizontal gap at z_corb_top!)
inline float sdCorbelParapetCyl(const Vec3& p, float cx, float cy,
                                float z0, float z_corb_top, float z1,
                                float R0, float R1, float r = 0.65f) {
    float t   = clampf((p.z - z0) / (z_corb_top - z0), 0.0f, 1.0f);
    float rad = lerpf(R0, R1, t);
    float dr  = std::hypot(p.x - cx, p.y - cy) - (rad - r);
    if (p.z < z_corb_top) dr *= 0.84f;
    float dz  = std::fabs(p.z - 0.5f * (z0 + z1)) - (0.5f * (z1 - z0) - r);
    return std::hypot(std::max(dr, 0.0f), std::max(dz, 0.0f)) + std::min(std::max(dr, dz), 0.0f) - r;
}

// ============================================================================
// Refined, Realistic Fine-Scale Medieval Stone Textures (Vertical Walls Only!)
// Walkable floors (courtyard, walltops, turrets, keep roof & interior floors)
// are kept completely smooth & flat so toy figures stand rock-steady.
// ============================================================================

inline float ashlarDisplacement(float u, float v, float courseH, float blockW, float mortarDepth, float blockRelief, int seed) {
    float rowF = v / courseH;
    int row = (int)std::floor(rowF);
    float vf = rowF - row;

    float rowShift = ((row & 1) ? 0.5f : 0.0f) + 0.16f * (hash21(row, seed) - 0.5f);
    float colF = u / blockW + rowShift;
    int col = (int)std::floor(colF);
    float uf = colF - col;

    float jL = 0.07f * (hash21(col + seed * 7, row * 13) - 0.5f);
    float jR = 0.07f * (hash21(col + 1 + seed * 7, row * 13) - 0.5f);
    if (uf < jL) { col -= 1; uf += 1.0f; }
    else if (uf > 1.0f + jR) { col += 1; uf -= 1.0f; }

    float dv = std::min(vf, 1.0f - vf) * courseH;
    float du = std::min(uf, 1.0f - uf) * blockW;

    float wobble = 0.14f * (vnoise2(u * 0.35f + seed * 3.1f, v * 0.35f) - 0.5f);
    dv = std::max(0.0f, dv + wobble);
    du = std::max(0.0f, du - wobble);

    float bevW = 0.68f;
    float stoneMask = smoothstep(0.0f, bevW, dv - 0.08f) * smoothstep(0.0f, bevW, du - 0.08f);
    float jointCut = (1.0f - stoneMask) * mortarDepth;

    float h0 = hash21(col * 37 + seed * 19, row * 53 + 7);
    float h1 = hash21(col * 71 + seed * 11, row * 29 + 13);
    float perBlock = (h0 - 0.48f) * blockRelief + (uf - 0.5f) * (h1 - 0.5f) * 0.16f;

    float chiseled = 0.12f * (vnoise2(u * 0.45f + 13.7f, v * 0.45f + 5.3f) - 0.5f)
                   + 0.07f * (vnoise2(u * 1.05f + 2.1f, v * 1.05f + 9.4f) - 0.5f);

    return (perBlock + chiseled) * stoneMask - jointCut;
}

inline float bedrockDisplacement(const Vec3& p) {
    float ang = std::atan2(p.y, p.x);
    float rad = std::hypot(p.x, p.y);
    float edgeD = 0.0f, cellR = 0.0f;
    voronoi2D(ang * 24.0f + 0.08f * p.z, p.z * 0.16f + rad * 0.015f, edgeD, cellR);
    float rockJoint = -0.95f * (1.0f - smoothstep(0.025f, 0.13f, edgeD));
    float slabStep = (cellR - 0.45f) * 0.95f;
    float n1 = fbm3(p.x * 0.06f + 3.1f, p.y * 0.06f - 1.7f, p.z * 0.08f, 3);
    float strata = 0.48f * std::sin(p.z * 0.58f + 1.8f * n1);
    float chiseled = 0.55f * n1;
    return clampf(slabStep + rockJoint + strata + chiseled, -1.7f, 1.4f);
}

inline float timberDoorDisplacement(float u, float z, float zBase) {
    float pf = u / 4.2f;
    float ff = pf - std::floor(pf);
    float dp = std::min(ff, 1.0f - ff) * 4.2f;
    float plankGroove = -0.45f * (1.0f - smoothstep(0.10f, 0.48f, dp));
    float grain = 0.14f * (vnoise2(u * 1.6f, z * 0.18f) - 0.5f);
    float s1 = zBase + 9.0f;
    float s2 = zBase + 25.0f;
    float strap = std::max(1.0f - smoothstep(1.3f, 1.9f, std::fabs(z - s1)),
                           1.0f - smoothstep(1.3f, 1.9f, std::fabs(z - s2)));
    float rf = (u + 2.1f) / 4.8f;
    float rx = (rf - std::floor(rf) - 0.5f) * 4.8f;
    float rz = std::min(std::fabs(z - s1), std::fabs(z - s2));
    float rivet = 1.0f - smoothstep(0.55f, 1.05f, std::hypot(rx, rz));
    return plankGroove * (1.0f - strap) + grain + 0.78f * strap + 0.42f * rivet;
}

// ============================================================================
// Reusable Crenellated Cylindrical Corner Tower
// - Smooth, untextured flat circular deck
// - Explicit angular stair-access opening [gapAng0, gapAng1] in local mirrored coords
//   with exact integer merlon spacing across the remaining parapet arc -> ZERO sliver merlons!
// ============================================================================
inline float sdCylTower(const Vec3& p, float cx, float cy, float R, float z_plinth_top,
                        float z_deck, float parapet_h, bool mirrorX,
                        float gapAng0Deg, float gapAng1Deg, int num_merlons,
                        bool has_slits, int seed, float curBest) {
    float dx = p.x - cx;
    float dy = p.y - cy;
    float r = std::hypot(dx, dy);

    float maxR = R + 6.5f;
    float drB = r - maxR;
    float dzB = std::max(-4.0f - p.z, p.z - (z_deck + parapet_h + 2.0f));
    float dBound = std::hypot(std::max(drB, 0.0f), std::max(dzB, 0.0f)) + std::min(std::max(drB, dzB), 0.0f);
    if (dBound > curBest + 3.5f) return dBound;

    // Local X-mirrored coordinates so left & right towers have exact symmetric gaps & merlons
    float ldx = mirrorX ? -dx : dx;
    float ang = std::atan2(dy, ldx); // in [-PI, +PI]

    // Shaft extends +0.5mm into crown base for solid overlap; sleek plinth flare (R + 3.0) matches crown footprint
    float d_shaft  = sdCylinderZ(p, cx, cy, R, -4.0f, z_deck + 0.5f, 0.7f);
    float d_plinth = sdConeFrustumZ(p, cx, cy, -4.0f, z_plinth_top, R + 3.0f, R);
    float d_body   = smin(d_shaft, d_plinth, 1.4f);

    float R_crown  = R + 3.0f;
    float d_crown  = sdCorbelParapetCyl(p, cx, cy, z_deck - 7.5f, z_deck - 1.5f, z_deck + parapet_h, R - 0.5f, R_crown, 0.65f);

    float corbEnv = smoothstep(z_deck - 8.0f, z_deck - 5.2f, p.z) * smoothstep(z_deck + 0.4f, z_deck - 2.2f, p.z)
                  * smoothstep(R - 2.0f, R, r) * smoothstep(R_crown + 2.0f, R_crown - 0.5f, r);
    if (corbEnv > 0.001f) {
        float cAng = std::fmod(ang + TAU * 2.0f, TAU / 20.0f);
        float cDist = std::fabs(cAng - 0.5f * TAU / 20.0f) * R;
        d_crown -= 0.85f * smoothstep(2.3f, 1.3f, cDist) * corbEnv;
    }

    d_body = smin(d_body, d_crown, 0.65f);

    // Subtle dressed stone belt course halfway up
    float z_belt = 0.5f * (z_plinth_top + z_deck - 8.0f);
    if (std::fabs(p.z - z_belt) < 4.0f) {
        float d_b1 = sdConeFrustumZ(p, cx, cy, z_belt - 1.8f, z_belt, R - 0.2f, R + 1.1f);
        float d_b2 = sdConeFrustumZ(p, cx, cy, z_belt, z_belt + 1.4f, R + 1.1f, R - 0.2f);
        d_body = smin(d_body, std::min(d_b1, d_b2), 0.4f);
    }

    // Hollow EXACT SHARP SMOOTH FLAT walkable circular deck (r=0, sharp max -> zero edge depression!)
    float R_inner = R_crown - 7.4f;
    float d_deck_cut = sdCylinderZ(p, cx, cy, R_inner, z_deck, z_deck + parapet_h + 10.0f, 0.0f);
    d_body = std::max(d_body, -d_deck_cut);

    // Explicit radial stair-access opening + exact sliver-free merlon subdivision of the remaining parapet arc!
    // Parapet arc starts at gapAng1Deg and wraps CCW to (gapAng0Deg + 360), ending cleanly on full chunky merlons!
    if (p.z > z_deck - 2.0f) {
        float angDeg = ang * (180.0f / PI);
        float gapSpan = gapAng1Deg - gapAng0Deg; // e.g. 110 deg (front) or 46 deg (rear)
        float parapetSpan = 360.0f - gapSpan;

        // Relative angle from start of stair gap, in [0, 360)
        float relFromGap = std::fmod(angDeg - gapAng0Deg + 720.0f, 360.0f);
        float radScale = std::max(r, R_inner) * (PI / 180.0f); // mm per degree

        // 1. Cut clean full-height radial stairway opening down to exact z_deck (sharp z_deck floor!)
        float distIntoGapDeg = std::min(relFromGap, gapSpan - relFromGap);
        float d_gap_ang = (relFromGap <= gapSpan) ? -distIntoGapDeg * radScale
                                                  : std::min(relFromGap - gapSpan, 360.0f - relFromGap) * radScale;
        float d_gap_z = z_deck - p.z;
        float d_gap_r = std::max((R_inner - 2.5f) - r, r - (R_crown + 3.5f));
        float d_gap = std::max(std::max(d_gap_ang, d_gap_z), d_gap_r);
        d_body = std::max(d_body, -d_gap);

        // 2. Cut (num_merlons - 1) evenly spaced embrasures strictly INSIDE the parapet arc
        //    so EVERY merlon (including both end merlons bordering the stair gap!) has full chunky width (~10-12mm)!
        float z_emb = z_deck + parapet_h * 0.50f;
        if (p.z > z_emb - 3.5f && relFromGap > gapSpan - 4.0f) {
            float relPara = relFromGap - gapSpan; // in [0, parapetSpan]
            // Divide parapetSpan = num_merlons * merlonDeg + (num_merlons - 1) * embDeg
            // with merlonDeg : embDeg = 1.38 : 1.0 (chunky merlons ~21-22 deg, crisp embrasures ~15-16 deg)
            float embDeg = parapetSpan / (1.38f * float(num_merlons) + float(num_merlons - 1));
            float merlonDeg = 1.38f * embDeg;
            float pitchDeg = merlonDeg + embDeg;

            // Embrasure k (k = 0 .. num_merlons - 2) is centered at merlonDeg + 0.5*embDeg + k*pitchDeg
            float minEmbDistDeg = 1e6f;
            for (int k = 0; k < num_merlons - 1; ++k) {
                float cDeg = merlonDeg + 0.5f * embDeg + float(k) * pitchDeg;
                float dDeg = std::fabs(relPara - cDeg) - 0.5f * embDeg;
                minEmbDistDeg = std::min(minEmbDistDeg, dDeg);
            }
            float d_emb = std::max(minEmbDistDeg * radScale, z_emb - p.z);
            d_emb = std::max(d_emb, std::max((R_inner - 2.0f) - r, r - (R_crown + 3.0f)));
            d_body = smax(d_body, -(d_emb - 0.55f), 0.55f);
        }
    }

    // Crisp recessed cruciform arrow slits (only on exterior-facing faces)
    float slitProtect = 1.0f;
    if (has_slits) {
        float z_sm = 0.54f * (z_plinth_top + z_deck);
        if (std::fabs(p.z - z_sm) < 14.0f && r > R - 6.5f) {
            float rawAng = std::atan2(dy, dx);
            for (int k = 0; k < 4; ++k) {
                float sa = 0.22f + k * (PI * 0.5f);
                float da = rawAng - sa;
                while (da > PI) da -= TAU;
                while (da < -PI) da += TAU;
                float arcU = da * R;
                if (std::fabs(arcU) < 8.0f) {
                    float d_vert = sdGothicArch2D(arcU, p.z, 1.55f, z_sm - 8.5f, z_sm + 5.5f, z_sm + 8.8f);
                    float d_depth = (R - 3.4f) - r;
                    float d_sill = (z_sm - 8.5f + (R - r) * 0.9f) - p.z;
                    float d_slit = std::max(std::max(d_vert, d_depth), d_sill);
                    float d_cross = std::max(std::max(std::fabs(arcU) - 3.4f, std::fabs(p.z - (z_sm + 1.0f)) - 1.05f), d_depth + 0.7f);
                    float d_cut = std::min(d_slit, d_cross);
                    d_body = smax(d_body, -(d_cut - 0.22f), 0.30f);
                    slitProtect = std::min(slitProtect, smoothstep(-0.4f, 1.8f, d_cut));
                }
            }
        }
    }

    // Fine dressed ashlar stone masonry on vertical walls ONLY (flat circular deck stays completely smooth!)
    if (std::fabs(d_body) < 2.5f) {
        float deckFade = (r < R_crown - 2.0f) ? smoothstep(0.0f, 1.5f, std::fabs(p.z - z_deck)) : 1.0f;
        float wallMask = deckFade
                       * smoothstep(0.0f, 1.2f, (z_deck + parapet_h) - p.z)
                       * smoothstep(0.5f, 3.5f, p.z);
        if (r > R - 5.5f && wallMask > 0.001f) {
            float rawAng = std::atan2(dy, dx);
            float u = (rawAng + PI) * R;
            float disp = ashlarDisplacement(u, p.z, 4.6f, 8.8f, 0.50f, 0.32f, seed);
            d_body -= disp * wallMask * slitProtect;
        }
    }
    return d_body;
}

// ============================================================================
// Precision FDM-Tolerant LEGO-Compatible Studs (EXACT 8.00 mm Grid Pitch!)
//   Dimensions live in CastleSpec (LEGO_PITCH, LEGO_STUD_R, LEGO_STUD_H, LEGO_CHAMFER).
//   Covers: Open Courtyard, Wall Walks + Gatehouse Deck, Rear Stair Landings, All 4 Turret Tops,
//           Keep Roof + Both Keep Interior Floors, and Single-Row Studs on All Suitable Stair Steps!
// ============================================================================
inline float sdLegoStud(const Vec3& p, float cx, float cy, float z_floor) {
    using namespace CastleSpec;
    float r = std::hypot(p.x - cx, p.y - cy);
    float dz_top = p.z - (z_floor + LEGO_STUD_H);
    float dz_bot = (z_floor - 0.85f) - p.z;
    float dz = std::max(dz_top, dz_bot);
    float dr = r - LEGO_STUD_R;
    float d_cyl = std::hypot(std::max(dr, 0.0f), std::max(dz, 0.0f)) + std::min(std::max(dr, dz), 0.0f);
    float d_chamf = (dr + dz_top + LEGO_CHAMFER) * 0.70710678f;
    return std::max(d_cyl, d_chamf);
}

// O(1) rectangular grid of LEGO studs: x = x0 + ix*8 (ix in [0..nx-1]), y = y0 + iy*8 (iy in [0..ny-1])
inline float sdStudGrid(const Vec3& p, float x0, int nx, float y0, int ny, float z_floor, float curD) {
    using namespace CastleSpec;
    float x1 = x0 + float(nx - 1) * LEGO_PITCH;
    float y1 = y0 + float(ny - 1) * LEGO_PITCH;
    float dxB = std::max(x0 - LEGO_STUD_R - p.x, p.x - (x1 + LEGO_STUD_R));
    float dyB = std::max(y0 - LEGO_STUD_R - p.y, p.y - (y1 + LEGO_STUD_R));
    float dzB = std::max((z_floor - 0.85f) - p.z, p.z - (z_floor + LEGO_STUD_H));
    if (std::max(dxB, std::max(dyB, dzB)) >= curD) return curD;

    int ix = (int)std::lround((p.x - x0) / LEGO_PITCH);
    int iy = (int)std::lround((p.y - y0) / LEGO_PITCH);
    if (ix < 0) ix = 0; else if (ix >= nx) ix = nx - 1;
    if (iy < 0) iy = 0; else if (iy >= ny) iy = ny - 1;
    return std::min(curD, sdLegoStud(p, x0 + float(ix) * LEGO_PITCH, y0 + float(iy) * LEGO_PITCH, z_floor));
}

// O(1) circular rosette of 29 LEGO studs centered on wider turret (tcx, tcy):
// full 5x5 core (dx, dy in {0, ±8, ±16}) + 4 outer compass-point studs (±24, 0) & (0, ±24), r_max = 24.0 mm
inline float sdTurretStuds(const Vec3& p, float tcx, float tcy, float z_floor, float curD) {
    using namespace CastleSpec;
    float dzB = std::max((z_floor - 0.85f) - p.z, p.z - (z_floor + LEGO_STUD_H));
    float rB  = std::hypot(p.x - tcx, p.y - tcy) - 27.5f;
    if (std::max(dzB, rB) >= curD) return curD;

    int ix = (int)std::lround((p.x - tcx) / LEGO_PITCH);
    int iy = (int)std::lround((p.y - tcy) / LEGO_PITCH);
    if (ix < -3) ix = -3; else if (ix > 3) ix = 3;
    if (iy < -3) iy = -3; else if (iy > 3) iy = 3;
    auto isValid = [](int gx, int gy) {
        return (gx * gx + gy * gy) <= 9; // allows 5x5 (max 4+4=8) and (±3,0)/(0,±3) (9), excludes (±3,±1..3)
    };
    if (isValid(ix, iy)) {
        return std::min(curD, sdLegoStud(p, tcx + float(ix) * LEGO_PITCH, tcy + float(iy) * LEGO_PITCH, z_floor));
    }
    // Check nearest valid inward rosette neighbors for smooth SDF continuity
    int ixIn = (ix > 0) ? (ix - 1) : ((ix < 0) ? (ix + 1) : 0);
    int iyIn = (iy > 0) ? (iy - 1) : ((iy < 0) ? (iy + 1) : 0);
    float dBest = curD;
    if (isValid(ixIn, iy))   dBest = std::min(dBest, sdLegoStud(p, tcx + float(ixIn) * LEGO_PITCH, tcy + float(iy) * LEGO_PITCH, z_floor));
    if (isValid(ix, iyIn))   dBest = std::min(dBest, sdLegoStud(p, tcx + float(ix) * LEGO_PITCH, tcy + float(iyIn) * LEGO_PITCH, z_floor));
    if (isValid(ixIn, iyIn)) dBest = std::min(dBest, sdLegoStud(p, tcx + float(ixIn) * LEGO_PITCH, tcy + float(iyIn) * LEGO_PITCH, z_floor));
    return dBest;
}

// Master O(1) LEGO Studs Field across all walkable floors & stair treads!
inline float legoStudsSDF(const Vec3& p, float curD = 1e6f) {
    using namespace CastleSpec;
    float ds = curD;
    Vec3 ap(std::fabs(p.x), p.y, p.z); // X-mirrored point for symmetric left/right castle zones!

    // 1. OPEN COURTYARD FLOOR (z = Z_COURT, skipping smooth gate tunnel y < -80.5 & front turret plinth discs)
    if (p.z > Z_COURT - 2.0f && p.z < Z_COURT + 3.5f) {
        // Main courtyard grid: x in [-96, +96] (25 cols, pitch 8), y in [-75, +21] (13 rows, pitch 8)
        float dxB = std::max(-98.5f - p.x, p.x - 98.5f);
        float dyB = std::max(-77.5f - p.y, p.y - 23.5f);
        float dzB = std::max((Z_COURT - 0.85f) - p.z, p.z - (Z_COURT + LEGO_STUD_H));
        if (std::max(dxB, std::max(dyB, dzB)) < ds) {
            int ix = (int)std::lround((p.x + 96.0f) / LEGO_PITCH);
            int iy = (int)std::lround((p.y + 75.0f) / LEGO_PITCH);
            if (ix < 0) ix = 0; else if (ix > 24) ix = 24;
            if (iy < 0) iy = 0; else if (iy > 12) iy = 12;
            auto evalCourt = [&](int gx, int gy) -> float {
                if (gx < 0 || gx > 24 || gy < 0 || gy > 12) return 1e6f;
                float cx = -96.0f + float(gx) * LEGO_PITCH;
                float cy = -75.0f + float(gy) * LEGO_PITCH;
                if (std::hypot(std::fabs(cx) - TWR_X, cy - TWR_F_Y) < 38.5f) return 1e6f;
                return sdLegoStud(p, cx, cy, Z_COURT);
            };
            float dc = evalCourt(ix, iy);
            if (dc > 1e5f) {
                // Inside excluded front-turret corner disc: check inward neighbors for continuous SDF
                int sxIn = (ix > 12) ? (ix - 1) : (ix + 1);
                dc = std::min(evalCourt(sxIn, iy), evalCourt(ix, iy + 1));
            }
            ds = std::min(ds, dc);
        }
        // Central courtyard row ahead of Keep front steps (y = +29, x = -40..+40, 11 studs on exact courtyard grid)
        ds = sdStudGrid(p, -40.0f, 11, 29.0f, 1, Z_COURT, ds);
        // Flanking Keep front steps on exact same 8 mm courtyard grid: y = +37 (|x| = 32, 40)
        ds = sdStudGrid(ap, 32.0f, 2, 37.0f, 1, Z_COURT, ds);
    }

    // 2. KEEP CEREMONIAL FRONT STEPS (z = 19 & Z_L1_FLOOR) + KEEP LEVEL 1 INTERIOR FLOOR (z = Z_L1_FLOOR)
    if (p.z > Z_COURT + 2.5f && p.z < Z_L1_FLOOR + 3.5f) {
        ds = sdStudGrid(p, -12.0f,  4, 40.0f, 1, Z_COURT + 4.0f, ds); // Step 0 (4 studs: x = ±4, ±12)
        ds = sdStudGrid(p,  -4.0f,  2, 46.0f, 1, Z_L1_FLOOR,     ds); // Step 1 inside portal (2 studs: x = ±4)
        ds = sdStudGrid(p, -36.0f, 10, 63.0f, 8, Z_L1_FLOOR,     ds); // Keep Level 1 interior (10 x 8 = 80 studs)
    }

    // 3. COURTYARD STAIRCASES (L & R, 8 steps of 8.0 mm tread x 7.5 mm rise, y = 29..93, single row of studs on EVERY step!)
    if (p.z > Z_COURT + 4.5f && p.z < Z_WALL_DECK + 3.5f && ap.x > 55.0f && ap.x < 97.0f && p.y > 27.0f && p.y < 95.0f) {
        int sIdx = (int)std::floor((p.y - 29.0f) / 8.0f);
        for (int k = std::max(0, sIdx - 1); k <= std::min(7, sIdx + 1); ++k) {
            float sy = 29.0f + (float(k) + 0.5f) * 8.0f;
            float sz = Z_COURT + float(k + 1) * 7.5f;
            int nCols = (k >= 6) ? 4 : 5; // |x| = 60, 68, 76, 84 (, 92 on steps 0..5 clear of inner corbel)
            ds = sdStudGrid(ap, 60.0f, nCols, sy, 1, sz, ds);
        }
    }

    // 4. WALL WALKS + GATEHOUSE TOP DECK + REAR STAIR LANDINGS (all on exact z = Z_WALL_DECK)
    if (p.z > Z_WALL_DECK - 1.5f && p.z < Z_WALL_DECK + 3.5f) {
        // Front wall walk (3 rows x 16 cols: x = ±4..±60, y = -73.9, -81.9, -89.9; shifted +8 mm with front wall)
        ds = sdStudGrid(p, -60.0f, 16, -89.9f, 3, Z_WALL_DECK, ds);
        // Gatehouse outward bulge extra 2 front rows (2 rows x 8 cols: x = ±4..±28, y = -97.9, -105.9)
        ds = sdStudGrid(p, -28.0f,  8, -105.9f, 2, Z_WALL_DECK, ds);
        // Left & Right side wall walks (3 cols x 12 rows per side: |x| = 98, 106, 114; y = -37.6..+50.4, 8 mm shorter!)
        ds = sdStudGrid(ap, 98.0f,  3, -37.6f, 12, Z_WALL_DECK, ds);
        // Rear stair landings (2 cols x 3 rows per side: |x| = 60, 68; y = 98, 106, 114; clear of wider rear turrets)
        ds = sdStudGrid(ap, 60.0f,  2,  98.0f,  3, Z_WALL_DECK, ds);
    }

    // 5. TURRET ACCESS STAIRS (Front turret side/front steps + Rear turret steps)
    if (p.z > Z_WALL_DECK + 4.0f && p.z < Z_TWR_R_DECK - 3.0f) {
        // Front turret side stairs (4a): s=0 (y=-47, z=81.33) & s=1 (y=-53, z=87.67), |x|=98,106,114
        if (ap.x > 93.0f && p.y < -42.0f && p.y > -58.0f) {
            ds = sdStudGrid(ap, 98.0f, 3, -47.0f, 1, 81.33f, ds);
            ds = sdStudGrid(ap, 98.0f, 3, -53.0f, 1, 87.67f, ds);
        }
        // Front turret front stairs (4b): s=0 (|x|=70, z=81.33) & s=1 (|x|=76, z=87.67), y=-89.9,-81.9,-73.9
        if (ap.x > 65.0f && ap.x < 81.0f && p.y < -69.0f && p.y > -95.0f) {
            ds = sdStudGrid(ap, 70.0f, 1, -89.9f, 3, 81.33f, ds);
            ds = sdStudGrid(ap, 76.0f, 1, -89.9f, 3, 87.67f, ds);
        }
        // Rear turret side stairs (4c): s=0,1,2 (y=60.05, 66.55, 73.05; z=TWR_R_STAIR_Z[0..2]), |x|=98,106,114
        if (ap.x > 93.0f && p.y > 55.0f && p.y < 78.0f) {
            ds = sdStudGrid(ap, 98.0f, 3, 60.05f, 1, TWR_R_STAIR_Z[0], ds);
            ds = sdStudGrid(ap, 98.0f, 3, 66.55f, 1, TWR_R_STAIR_Z[1], ds);
            ds = sdStudGrid(ap, 98.0f, 3, 73.05f, 1, TWR_R_STAIR_Z[2], ds);
        }
    }

    // 6. FRONT CORNER TURRET TOPS (z = Z_TWR_F_DECK, 29-stud circular rosette centered at (±TWR_X, TWR_F_Y))
    if (p.z > Z_TWR_F_DECK - 1.5f && p.z < Z_TWR_F_DECK + 3.5f) {
        ds = sdTurretStuds(ap, TWR_X, TWR_F_Y, Z_TWR_F_DECK, ds);
    }

    // 7. REAR CORNER TURRET TOPS (z = Z_TWR_R_DECK, 29-stud circular rosette centered at (±TWR_X, TWR_R_Y))
    if (p.z > Z_TWR_R_DECK - 1.5f && p.z < Z_TWR_R_DECK + 3.5f) {
        ds = sdTurretStuds(ap, TWR_X, TWR_R_Y, Z_TWR_R_DECK, ds);
    }

    // 8. KEEP LEVEL 2 INTERIOR FLOOR (z = Z_L2_FLOOR, 10 x 8 = 80 studs)
    if (p.z > Z_L2_FLOOR - 1.5f && p.z < Z_L2_FLOOR + 3.5f) {
        ds = sdStudGrid(p, -36.0f, 10, 63.0f, 8, Z_L2_FLOOR, ds);
    }

    // 9. KEEP ROOF DECK (z = Z_KEEP_DECK, 11 x 8 = 88 studs)
    if (p.z > Z_KEEP_DECK - 1.5f && p.z < Z_KEEP_DECK + 3.5f) {
        ds = sdStudGrid(p, -40.0f, 11, 58.25f, 8, Z_KEEP_DECK, ds);
    }

    return ds;
}

// ============================================================================
// Master Castle Signed Distance Field
// Envelope: X in [-145, +145] (290.0 mm), Y in [-139.4, +145.0] (284.4 mm), Z in [0, 215] (215.0 mm)
// All shared dimensions are sourced from CastleSpec above.
// ============================================================================
inline float castleSDF(const Vec3& p) {
    using namespace CastleSpec;

    // ------------------------------------------------------------------------
    // 1. SOLID INTERIOR FOUNDATION SLAB (z = 0..15 mm, zero scree/glacis skirt!)
    //    Bounded cleanly inside the outer curtain walls so the steep 25 mm ashlar wall
    //    batter forms the entire outer base perimeter with continuous dressed stonework.
    // ------------------------------------------------------------------------
    float d = 1e9f;
    {
        float d_slab_main = sdBoxMinMax(p, -WALL_OUT_X, WALL_OUT_X, WALL_OUT_Y_MIN, WALL_OUT_Y_MAX, -4.0f, Z_COURT, 0.0f);
        float d_slab_gh   = sdBoxMinMax(p, -GH_HALF_X,  GH_HALF_X,  GH_Y_MIN,       WALL_OUT_Y_MIN + 2.0f, -4.0f, Z_COURT, 0.0f);
        d = std::min(d_slab_main, d_slab_gh);
    }

    // ------------------------------------------------------------------------
    // 2. FRONT STEPPED STONE CAUSEWAY (world y = -131.3 to -113.5 mm, shifted +8 mm with gatehouse)
    // ------------------------------------------------------------------------
    {
        float d_b = sdBoxMinMax(p, -26.0f, 26.0f, GH_Y_MIN - 19.0f, GH_Y_MIN + 9.0f, -2.0f, Z_COURT + 8.0f);
        if (d_b < d + 3.0f) {
            float yStart = GH_Y_MIN - 16.8f; // -131.3 mm
            float yEnd   = GH_Y_MIN + 1.0f;  // -113.5 mm
            int nSteps   = 4;
            float stepRun  = (yEnd - yStart) / float(nSteps);   // 4.45 mm deep treads
            float stepRise = Z_COURT / float(nSteps);           // 3.75 mm gentle rise (~40 deg shallow pitch)

            float d_steps = 1e9f;
            for (int s = 0; s < nSteps; ++s) {
                float sy0 = yStart + s * stepRun;
                float sz1 = (s + 1) * stepRise;
                float sb = sdBoxMinMax(p, -20.5f, 20.5f, sy0, GH_Y_MIN + 7.5f, -2.0f, sz1, 0.35f);
                d_steps = std::min(d_steps, sb);
            }
            // Flanking stone curbs (matching shallower pitch)
            float ty = clampf((p.y - yStart) / (yEnd - yStart), 0.0f, 1.0f);
            float z_curb = lerpf(4.5f, Z_COURT + 4.0f, ty);
            float dz_c = (p.z - z_curb) * 0.72f;
            float dx_c = std::fabs(std::fabs(p.x) - 21.8f) - 2.6f;
            float dy_c = std::max((GH_Y_MIN - 16.3f) - p.y, p.y - (GH_Y_MIN + 3.5f));
            float cx = std::max(dx_c, 0.0f), cy = std::max(dy_c, 0.0f), cz = std::max(dz_c, 0.0f);
            float d_curb = std::sqrt(cx*cx + cy*cy + cz*cz) + std::min(std::max(dx_c, std::max(dy_c, dz_c)), 0.0f) - 0.45f;

            float d_ramp = smin(d_steps, d_curb, 0.5f);
            if (std::fabs(d_ramp) < 2.0f && std::fabs(p.x) > 22.8f && p.z > 2.0f) {
                d_ramp -= ashlarDisplacement(p.y + 145.0f, p.z, 4.4f, 8.2f, 0.40f, 0.24f, 88)
                        * smoothstep(22.5f, 24.0f, std::fabs(p.x));
            }
            d = smin(d, d_ramp, 0.65f);
        }
    }

    // ------------------------------------------------------------------------
    // 3. OUTER CURTAIN WALLS (from CastleSpec::WALL_* constants)
    //    Outer wall:  X in [-123.5, +123.5], Y in [-100.5, +123.5] (8.0 mm shorter front-to-back!)
    //    Base flare:  bottom 25.0 mm flares +12.0 mm outward (~64.4-deg slope) with continuous ashlar
    //    Parapet:     X in [-126.5, +126.5], Y in [-103.5, +126.5] (7.6 mm thick -> inner ±118.9 / -95.9)
    //    Walkway top: X inner ±93.0, Y inner [-70.0, +93.0] -> 25.9 mm wide (fits 3-stud LEGO brick)
    //    Main straight walls (z = 25..63): exact 20.0 mm thick
    // ------------------------------------------------------------------------
    {
        static constexpr float WX_H = WALL_OUT_X;
        static constexpr float WY_C = WALL_Y_C;
        static constexpr float WY_H = WALL_Y_H;

        float d_wb = sdBoxMinMax(p, -139.0f, 139.0f, WALL_OUT_Y_MIN - 15.5f, WALL_OUT_Y_MAX + 15.5f, -4.0f, Z_WALL_PARA + 3.0f);
        if (d_wb < d + 3.5f) {
            float ax = std::fabs(p.x);
            float ay = std::fabs(p.y - WY_C);
            // Distance from outer wall plane (0 at x=±123.5 or y=-100.5 / y=+123.5)
            float dFromOutX = ax - WX_H;
            float dFromOutY = ay - WY_H;
            float maxOut = std::max(dFromOutX, dFromOutY);

            // Seamless pronounced 25 mm battered wall base (+12.0 mm horizontal flare at z=0 -> 0 mm at z=25, ~64.4-deg slope!)
            // Single continuous profile from z = -4 to Z_WALL_DECK + 0.5 -> ZERO horizontal seam at z = 25 mm!
            float t_bat = clampf(1.0f - p.z / WALL_BASE_BAT_H, 0.0f, 1.0f);
            float batOut = WALL_BASE_BAT_OUT * t_bat;
            float bx = ax - (WX_H + batOut - 0.8f);
            float by = ay - (WY_H + batOut - 0.8f);
            float bz = std::max(-4.0f + 0.8f - p.z, p.z - (Z_WALL_DECK + 0.5f - 0.8f));
            float b2 = std::hypot(std::max(bx, 0.0f), std::max(by, 0.0f)) + std::min(std::max(bx, by), 0.0f);
            if (p.z < WALL_BASE_BAT_H) b2 *= 0.9015f; // 1 / sqrt(1 + (12/25)^2) for exact Lipschitz SDF on slope
            float d_out_shaft = std::hypot(std::max(b2, 0.0f), std::max(bz, 0.0f)) + std::min(std::max(b2, bz), 0.0f) - 0.8f;

            // Single seamless corbel + parapet solid -> ZERO horizontal groove/void at z = Z_WALL_DECK - 1.5
            float d_out_crown = sdCorbelParapetBox(p, 0.0f, WY_C, WY_C,
                                                   Z_WALL_DECK - 7.8f, Z_WALL_DECK - 1.5f, Z_WALL_PARA,
                                                   WX_H - 0.5f, WY_H - 0.5f, WX_H + WALL_CORB_OUT, WY_H + WALL_CORB_OUT, 0.65f);

            float d_outer = smin(d_out_shaft, d_out_crown, 0.65f);

            // Continuous seam-free inner courtyard cutout (zero horizontal seam membrane):
            //   z <= 63.0:      wide courtyard [-103.5, +103.5] x [-88.5, +103.5] -> exact 20.0 mm wall thickness
            //   z = 63.0..73.5: exact 45-deg receding corbel slope (10.5 mm run over 10.5 mm rise)
            //   z >= 73.5:      [-93.0, +93.0] x [-78.0, +93.0] -> exact 25.9 mm wide walkway (fits 3-stud LEGO brick)
            float t_corb = clampf((p.z - (Z_WALL_DECK - 12.0f)) / 10.5f, 0.0f, 1.0f);
            float c_hx   = lerpf(WALL_COURT_IN_X,   WALL_WALK_IN_X,   t_corb);
            float c_hy   = lerpf(WALL_COURT_HY_LOW, WALL_COURT_HY_TOP, t_corb);
            float c_qx   = std::fabs(p.x) - (c_hx - 0.5f);
            float c_qy   = std::fabs(p.y - WY_C) - (c_hy - 0.5f);
            float c_d2   = std::hypot(std::max(c_qx, 0.0f), std::max(c_qy, 0.0f)) + std::min(std::max(c_qx, c_qy), 0.0f) - 0.5f;
            float d_court_cut = c_d2 * 0.707f;

            float d_walk_cut  = sdBoxMinMax(p, -WALL_WALK_OUT_X, WALL_WALK_OUT_X, WALL_WALK_OUT_Y0, WALL_WALK_OUT_Y1, Z_WALL_DECK, 120.0f, 0.0f);

            float d_walls = std::max(smax(d_outer, -d_court_cut, 0.45f), -d_walk_cut);

            // Corbel brackets under exterior parapet overhang (blends smoothly into parapet ashlars above!)
            float corbM = smoothstep(Z_WALL_DECK - 8.0f, Z_WALL_DECK - 5.2f, p.z)
                        * smoothstep(Z_WALL_DECK + 0.4f, Z_WALL_DECK - 2.2f, p.z)
                        * smoothstep(-2.5f, 0.0f, maxOut) * smoothstep(5.0f, 2.5f, maxOut);
            if (corbM > 0.001f) {
                float u = (dFromOutX > dFromOutY) ? p.y : p.x;
                float uf = std::fabs(std::fmod(u + 300.0f, 10.5f) - 5.25f);
                d_walls -= 0.72f * smoothstep(2.4f, 1.3f, uf) * corbM;
            }

            // Matching subtle corbel ribs under the 45-deg interior courtyard walkway overhang (z = 64.5..73.0)
            float inCorbM = smoothstep(Z_WALL_DECK - 11.2f, Z_WALL_DECK - 8.5f, p.z)
                          * smoothstep(Z_WALL_DECK - 1.2f, Z_WALL_DECK - 3.0f, p.z)
                          * smoothstep(-18.0f, -21.0f, maxOut) * smoothstep(-32.0f, -29.0f, maxOut);
            if (inCorbM > 0.001f) {
                bool isGateOpening = (dFromOutY >= dFromOutX && p.y < WY_C && ax < 22.0f);
                if (!isGateOpening) {
                    float u = (dFromOutX > dFromOutY) ? p.y : p.x;
                    float uf = std::fabs(std::fmod(u + 300.0f, 10.5f) - 5.25f);
                    d_walls -= 0.65f * smoothstep(2.3f, 1.2f, uf) * inCorbM;
                }
            }

            // Explicit sliver-free crenellation embrasures (~50% wider merlons & crenels, +2 mm taller parapet!)
            // Crenels ~15.5 mm wide, merlons ~21-22.5 mm wide (sill at Z_WALL_DECK + 11.0, merlons at +22.0)
            if (p.z > Z_WALL_DECK + 8.0f && maxOut > -8.0f) {
                float d_emb_u = 1e6f;
                if (dFromOutX > dFromOutY) {
                    // Left & Right side walls (clear span y in [-51.5, +74.0] = 125.5 mm, centered at y = +11.25):
                    // 3 evenly spaced 15.5 mm crenels at pitch 35.25 mm -> ALL 4 merlons exact 19.75 mm wide!
                    float dyS = std::fabs(p.y - 11.25f);
                    float d1 = dyS - 7.20f;
                    float d2 = std::fabs(dyS - 35.25f) - 7.20f;
                    d_emb_u = std::min(d1, d2);
                } else if (p.y < WY_C) {
                    // Front wall flanking gatehouse & wider front turret (clear span |x| in [40.5, 74.5] = 34.0 mm):
                    // 1 wide 15.5 mm crenel [40.5, 56.0] leaving a chunky 18.5+ mm merlon into the front turret!
                    d_emb_u = std::fabs(ax - 48.25f) - 7.20f;
                } else {
                    // Rear wall flanking Keep & wider rear turret (clear span |x| in [55.5, 74.0] = 18.5 mm):
                    // 1 crisp 14.0 mm crenel centered at |x| = 64.75
                    d_emb_u = std::fabs(ax - 64.75f) - 6.45f;
                }
                float d_emb = std::max(d_emb_u, (Z_WALL_DECK + PARA_H * 0.5f) - p.z);
                d_walls = smax(d_walls, -(d_emb - 0.55f), 0.55f);
            }

            // Exterior arrow slits along curtain walls (z = 35..53, relative to Z_COURT)
            float slitProtect = 1.0f;
            if (p.z > Z_COURT + 15.0f && p.z < Z_COURT + 44.0f && maxOut > -7.0f) {
                float u = (dFromOutX > dFromOutY) ? p.y : p.x;
                bool skipFrontGate = (p.y < WALL_WALK_IN_Y0 - 2.0f && std::fabs(p.x) < 42.0f);
                bool skipRearKeep  = (p.y >  95.0f && std::fabs(p.x) < 56.0f);
                bool validSpan = (dFromOutX > dFromOutY) ? (p.y > -51.0f && p.y < 74.0f) : (std::fabs(u) < 76.0f);
                if (!skipFrontGate && !skipRearKeep && validSpan) {
                    float uShift = (dFromOutX > dFromOutY) ? (p.y - 11.25f) : u;
                    float uf = std::fmod(uShift + 306.0f, 36.0f) - 18.0f;
                    float d_s2 = sdGothicArch2D(uf, p.z, 1.55f, Z_COURT + 20.0f, Z_COURT + 34.0f, Z_COURT + 38.0f);
                    float d_depth = -3.6f - maxOut;
                    float d_sill = (Z_COURT + 20.0f + (-maxOut) * 0.9f) - p.z;
                    float d_slit = std::max(std::max(d_s2, d_depth), d_sill);
                    float d_cross = std::max(std::max(std::fabs(uf) - 3.4f, std::fabs(p.z - (Z_COURT + 29.5f)) - 1.05f), d_depth + 0.7f);
                    float d_cut = std::min(d_slit, d_cross);
                    d_walls = smax(d_walls, -(d_cut - 0.22f), 0.30f);
                    slitProtect = smoothstep(-0.4f, 1.8f, d_cut);
                }
            }

            // Fine ashlar stone masonry on vertical wall faces ONLY (walltop & courtyard floors stay glass-smooth!)
            if (std::fabs(d_walls) < 2.5f && maxOut > -33.0f) {
                float u = (dFromOutX > dFromOutY) ? p.y : p.x;
                int faceSeed = (dFromOutX > dFromOutY) ? (p.x > 0 ? 11 : 17) : (p.y > WY_C ? 23 : 29);
                // Keep exterior parapet & steep 25 mm battered wall base ashlar continuous all the way down to z = 0.5 mm!
                // On the courtyard side (maxOut < -3.0), keep courtyard floor (z = Z_COURT) & wall walk (z = Z_WALL_DECK) smooth.
                float deckFade = (maxOut < -2.5f) ? smoothstep(0.0f, 1.5f, std::fabs(p.z - Z_WALL_DECK)) : 1.0f;
                float botFade  = (maxOut < -3.0f) ? smoothstep(Z_COURT - 2.0f, Z_COURT + 2.5f, p.z)
                                                  : smoothstep(0.5f, 3.0f, p.z);
                float walkMask = deckFade
                               * smoothstep(0.0f, 1.2f, Z_WALL_PARA - p.z)
                               * botFade;
                // Keep 45-deg inner corbel slope crisp and FDM-friendly (fade ashlar smoothly across slope)
                float innerSlopeFade = (maxOut < -18.5f && p.z > Z_WALL_DECK - 12.5f && p.z < Z_WALL_DECK - 1.0f) ? 0.25f : 1.0f;
                float floorMask = (maxOut < -4.4f && maxOut > -31.5f) ? smoothstep(1.8f, 0.2f, std::fabs(p.z - Z_WALL_DECK)) : 0.0f;

                if (walkMask > 0.001f && floorMask < 0.85f) {
                    float disp = ashlarDisplacement(u + 150.0f, p.z, 4.6f, 9.0f, 0.50f, 0.32f, faceSeed);
                    d_walls -= disp * walkMask * slitProtect * innerSlopeFade;
                }
            }
            d = smin(d, d_walls, 0.8f);
        }
    }

    // ------------------------------------------------------------------------
    // 4. FOUR CORNER BASTION TOWERS + FULL-WIDTH STAIR PATHS (ZERO CREVICE AGAINST PARAPET)
    //    Front Towers at (±TWR_X, TWR_F_Y) = (±110, -95): deck z = 94, merlons z = 114 (+20 mm)
    //    Rear Towers  at (±TWR_X, TWR_R_Y) = (±110, +110): deck z = 102, merlons z = 122 (+20 mm)
    // ------------------------------------------------------------------------
    {
        // Wider turrets (+10 mm dia) with ~50% wider merlons & crenels (5 merlons front, 7 merlons rear)
        float tFL = sdCylTower(p, -TWR_X, TWR_F_Y, TWR_F_R, Z_COURT + 14.0f, Z_TWR_F_DECK, PARA_H, false, -19.0f, 109.0f, 5, true, 101, d);
        d = smin(d, tFL, 0.85f);
        float tFR = sdCylTower(p, +TWR_X, TWR_F_Y, TWR_F_R, Z_COURT + 14.0f, Z_TWR_F_DECK, PARA_H, true,  -19.0f, 109.0f, 5, true, 102, d);
        d = smin(d, tFR, 0.85f);
        float tRL = sdCylTower(p, -TWR_X, TWR_R_Y, TWR_R_R, Z_COURT + 16.0f, Z_TWR_R_DECK, PARA_H, false, -109.0f, -52.0f, 7, true, 103, d);
        d = smin(d, tRL, 0.85f);
        float tRR = sdCylTower(p, +TWR_X, TWR_R_Y, TWR_R_R, Z_COURT + 16.0f, Z_TWR_R_DECK, PARA_H, true,  -109.0f, -52.0f, 7, true, 104, d);
        d = smin(d, tRR, 0.85f);

        float ax = std::fabs(p.x);

        // 4a. Side-wall stairs climbing from wall walk (z=75) -> Wider Front Corner Towers (z=94):
        //     Spans FULL widened walkway width |x| in [93.0, 121.5] straight into the parapet wall -> ZERO crevice!
        float d_sbF = sdBoxMinMax(Vec3(ax, p.y, p.z), 91.0f, 123.5f, -68.0f, -40.0f, Z_WALL_DECK - 4.0f, Z_TWR_F_DECK + 4.0f);
        if (d_sbF < d + 2.5f) {
            float d_st = 1e9f;
            for (int s = 0; s < 3; ++s) {
                float y_hi = -44.0f - s * 6.0f;
                float z_hi = Z_WALL_DECK + (s + 1) * ((Z_TWR_F_DECK - Z_WALL_DECK) / 3.0f);
                d_st = std::min(d_st, sdBoxMinMax(Vec3(ax, p.y, p.z), 93.0f, 121.5f, -66.0f, y_hi, Z_WALL_DECK - 3.0f, z_hi, 0.35f));
            }
            d = smin(d, d_st, 0.35f);
        }

        // 4b. Front-wall stairs climbing from front wall walk (z=75) -> Wider Front Corner Towers (z=94):
        //     Spans FULL widened walkway width y in [-98.5, -70.0] straight into front parapet -> ZERO crevice!
        float d_sbFront = sdBoxMinMax(Vec3(ax, p.y, p.z), 63.0f, 91.0f, -100.5f, -68.0f, Z_WALL_DECK - 4.0f, Z_TWR_F_DECK + 4.0f);
        if (d_sbFront < d + 2.5f) {
            float d_st = 1e9f;
            for (int s = 0; s < 3; ++s) {
                float x_lo = 67.0f + s * 6.0f;
                float z_hi = Z_WALL_DECK + (s + 1) * ((Z_TWR_F_DECK - Z_WALL_DECK) / 3.0f);
                d_st = std::min(d_st, sdBoxMinMax(Vec3(ax, p.y, p.z), x_lo, 89.0f, -98.5f, -70.0f, Z_WALL_DECK - 3.0f, z_hi, 0.35f));
            }
            d = smin(d, d_st, 0.35f);
        }

        // 4c. Side-wall stairs climbing from wall walk (z=75) -> Wider Rear Corner Towers (z=102):
        //     Steps 0..2 stay <= 94.8 mm (< side parapet 97.0 mm); step 3 starts at y=76.3 inside turret crown!
        float d_sbR = sdBoxMinMax(Vec3(ax, p.y, p.z), 91.0f, 123.5f, 54.0f, 91.0f, Z_WALL_DECK - 4.0f, Z_TWR_R_DECK + 4.0f);
        if (d_sbR < d + 2.5f) {
            float d_st = 1e9f;
            for (int s = 0; s < 4; ++s) {
                float y_lo = 56.8f + s * 6.5f;
                float z_hi = TWR_R_STAIR_Z[s];
                d_st = std::min(d_st, sdBoxMinMax(Vec3(ax, p.y, p.z), 93.0f, 121.5f, y_lo, 89.0f, Z_WALL_DECK - 3.0f, z_hi, 0.35f));
            }
            d = smin(d, d_st, 0.35f);
        }

        // 4d. Re-clear all four circular turret interior decks with EXACT SHARP std::max (r=0, k=0) AFTER unioning walls & stairs
        {
            float d_clrFL = sdCylinderZ(p, -TWR_X, TWR_F_Y, TWR_F_R_IN, Z_TWR_F_DECK, Z_TWR_F_DECK + 35.0f, 0.0f);
            float d_clrFR = sdCylinderZ(p, +TWR_X, TWR_F_Y, TWR_F_R_IN, Z_TWR_F_DECK, Z_TWR_F_DECK + 35.0f, 0.0f);
            float d_clrRL = sdCylinderZ(p, -TWR_X, TWR_R_Y, TWR_R_R_IN, Z_TWR_R_DECK, Z_TWR_R_DECK + 35.0f, 0.0f);
            float d_clrRR = sdCylinderZ(p, +TWR_X, TWR_R_Y, TWR_R_R_IN, Z_TWR_R_DECK, Z_TWR_R_DECK + 35.0f, 0.0f);
            float d_clrAll = std::min(std::min(d_clrFL, d_clrFR), std::min(d_clrRL, d_clrRR));
            d = std::max(d, -d_clrAll);
        }
    }

    // ------------------------------------------------------------------------
    // 5. OUTWARD-BULGING FLUSH-HEIGHT GATEHOUSE (world coordinates, from CastleSpec::GH_*)
    //    Outer wall y = -114.5 (parapet -117.5), inner face flush with front wall (y = -80.5 / -70.0)
    //    Smooth pass-through Gothic gate tunnel (38 mm wide x 52 mm tall, z = 15..67 mm)
    // ------------------------------------------------------------------------
    {
        float d_ghb = sdBoxMinMax(p, -54.0f, 54.0f, GH_Y_MIN - 16.0f, GH_Y_MAX + 4.0f, -4.0f, Z_WALL_PARA + 4.0f);
        if (d_ghb < d + 3.5f) {
            // Matching seamless pronounced 25 mm ashlar base batter (+12.0 mm at z=0 -> 0 at z=25, front & sides only!)
            float t_gbat = clampf(1.0f - p.z / WALL_BASE_BAT_H, 0.0f, 1.0f);
            float gBat   = WALL_BASE_BAT_OUT * t_gbat;
            float gbx = std::fabs(p.x) - (GH_HALF_X + gBat - 0.8f);
            float gby = std::max((GH_Y_MIN - gBat + 0.8f) - p.y, p.y - (GH_Y_MAX - 0.8f));
            float gbz = std::max(-4.0f + 0.8f - p.z, p.z - (Z_WALL_DECK + 0.5f - 0.8f));
            float gb2 = std::hypot(std::max(gbx, 0.0f), std::max(gby, 0.0f)) + std::min(std::max(gbx, gby), 0.0f);
            if (p.z < WALL_BASE_BAT_H) gb2 *= 0.9015f;
            float d_gh_shaft = std::hypot(std::max(gb2, 0.0f), std::max(gbz, 0.0f)) + std::min(std::max(gb2, gbz), 0.0f) - 0.8f;

            // Keep the stair well (|x| <= 19.2, z <= Z_COURT) open through the +12 mm front flare so all 4 causeway steps stay crisp!
            float d_stair_well = sdBoxMinMax(p, -19.2f, 19.2f, GH_Y_MIN - 15.0f, GH_Y_MIN + 0.5f, -5.0f, Z_COURT + 2.0f, 0.0f);
            d_gh_shaft = std::max(d_gh_shaft, -d_stair_well);

            // Seamless corbel + parapet flaring outward ONLY on front (GH_PARA_Y_MIN) & sides (±GH_PARA_HALF_X)
            float d_gh_crown = sdCorbelParapetBox(p, 0.0f, GH_Y_C, GH_Y_C - 1.5f,
                                                  Z_WALL_DECK - 7.8f, Z_WALL_DECK - 1.5f, Z_WALL_PARA,
                                                  GH_HALF_X, GH_Y_H, GH_PARA_HALF_X, GH_Y_H + 1.5f, 0.65f);
            d_gh_crown = std::max(d_gh_crown, p.y - GH_Y_MAX);
            float d_pil = sdBoxMinMax(Vec3(std::fabs(p.x), p.y, p.z), 31.0f, 39.5f, GH_Y_MIN - 1.5f, GH_Y_MIN + 17.5f,
                                      Z_COURT, Z_WALL_DECK - 6.0f, 0.7f);

            float d_gh = smin(d_gh_shaft, std::min(d_gh_crown, d_pil), 0.65f);

            // Clean corbel brackets under outward-bulging front & side gatehouse overhangs (blends smoothly into parapet)
            float corbM = smoothstep(Z_WALL_DECK - 8.0f, Z_WALL_DECK - 5.2f, p.z)
                        * smoothstep(Z_WALL_DECK + 0.4f, Z_WALL_DECK - 2.2f, p.z);
            if (corbM > 0.001f) {
                float fMask = smoothstep(GH_Y_MIN + 1.5f, GH_Y_MIN - 0.5f, p.y)
                            * smoothstep(GH_Y_MIN - 4.5f, GH_Y_MIN - 2.3f, p.y)
                            * smoothstep(40.0f, 38.0f, std::fabs(p.x));
                float sMask = smoothstep(37.0f, 39.0f, std::fabs(p.x)) * smoothstep(42.0f, 40.0f, std::fabs(p.x))
                            * smoothstep(GH_Y_MIN + 17.5f, GH_Y_MIN + 15.0f, p.y)
                            * smoothstep(GH_Y_MIN - 2.5f,  GH_Y_MIN,         p.y);
                if (fMask > 0.001f) {
                    float uf = std::fabs(std::fmod(p.x + 200.0f, 9.5f) - 4.75f);
                    d_gh -= 0.72f * smoothstep(2.4f, 1.2f, uf) * corbM * fMask;
                }
                if (sMask > 0.001f) {
                    float uf = std::fabs(std::fmod(p.y + 195.0f, 9.5f) - 4.75f);
                    d_gh -= 0.72f * smoothstep(2.4f, 1.2f, uf) * corbM * sMask;
                }
            }

            // Continuous EXACT SHARP flat walkable battlement deck at z = Z_WALL_DECK (7.6 mm thick parapet)
            float d_gh_deck1 = sdBoxMinMax(p, -GH_WALK_HALF_X, GH_WALK_HALF_X, GH_WALK_Y_MIN, GH_Y_MAX + 4.0f, Z_WALL_DECK, 125.0f, 0.0f);
            float d_gh_deck2 = sdBoxMinMax(p, -44.0f, 44.0f, WALL_WALK_OUT_Y0, GH_Y_MAX + 4.0f, Z_WALL_DECK, 125.0f, 0.0f);
            d_gh = std::max(d_gh, -std::min(d_gh_deck1, d_gh_deck2));

            // Match the exact same continuous courtyard wall profile (y = -80.5 below z = 63, 45-deg corbel up to y = -70.0 at z = 73.5)
            {
                float t_corb = clampf((p.z - (Z_WALL_DECK - 12.0f)) / 10.5f, 0.0f, 1.0f);
                float gc_yMax = lerpf(GH_COURT_LOW_Y, GH_Y_MAX, t_corb);
                float d_gc_cut = (gc_yMax - p.y) * 0.707f;
                d_gh = smax(d_gh, -d_gc_cut, 0.45f);
            }

            // Consistent wider crenellation merlons & crenels along the outward-bulging gatehouse parapet
            // Front: center 20.0 mm merlon [-10.0, +10.0], pair of 14.5 mm crenels [10.0, 24.5], solid 16x14 mm corner L-merlons
            if (p.z > Z_WALL_DECK + 8.0f) {
                float ax = std::fabs(p.x);
                if (p.y < GH_Y_MIN + 6.5f && ax < 33.0f) {
                    float d_emb_all = std::fabs(ax - 17.25f) - 6.70f;
                    float d_e = std::max(d_emb_all, (Z_WALL_DECK + PARA_H * 0.5f) - p.z);
                    d_gh = smax(d_gh, -(d_e - 0.55f), 0.55f);
                }
            }

            // Flanking cruciform arrow slits on gate piers (z = 36..53, relative to Z_COURT)
            float ghProtect = 1.0f;
            if (p.z > Z_COURT + 18.0f && p.z < Z_COURT + 44.0f && p.y < GH_Y_MIN + 6.5f && std::fabs(std::fabs(p.x) - 29.0f) < 6.0f) {
                float ux = std::fabs(p.x) - 29.0f;
                float d_s2 = sdGothicArch2D(ux, p.z, 1.45f, Z_COURT + 21.0f, Z_COURT + 34.0f, Z_COURT + 38.0f);
                float d_depth = p.y - (GH_Y_MIN + 4.5f);
                float d_sill = (Z_COURT + 21.0f + (p.y - GH_Y_MIN) * 0.9f) - p.z;
                float d_slit = std::max(std::max(d_s2, d_depth), d_sill);
                float d_cross = std::max(std::max(std::fabs(ux) - 3.0f, std::fabs(p.z - (Z_COURT + 30.0f)) - 1.0f), d_depth + 0.6f);
                float d_cut = std::min(d_slit, d_cross);
                d_gh = smax(d_gh, -(d_cut - 0.22f), 0.30f);
                ghProtect = std::min(ghProtect, smoothstep(-0.4f, 1.8f, d_cut));
            }

            // Carved stone Voussoir Arch Ring framing outer front portal (y = GH_Y_MIN);
            // inner courtyard portal exits cleanly through the y = -80.5 wall and 45-deg corbel
            if (p.z > Z_COURT - 1.0f && p.z < Z_COURT + 59.0f && std::fabs(p.x) < 27.0f && p.y < GH_Y_MIN + 5.5f) {
                float d_ao = sdGothicArch2D(p.x, p.z, 23.2f, Z_COURT - 1.0f, Z_COURT + 28.0f, Z_COURT + 56.5f);
                float d_ai = sdGothicArch2D(p.x, p.z, GATE_HALF_W, Z_COURT - 1.0f, Z_COURT + 28.0f, Z_COURT + 52.0f);
                float d_ring = std::max(d_ao, -d_ai);
                float dyFR = std::fabs(p.y - (GH_Y_MIN - 0.3f)) - 1.6f;
                float d_vous = std::max(d_ring, dyFR);
                if (std::fabs(d_vous) < 2.2f && p.z > Z_COURT + 27.0f) {
                    float va = std::atan2(p.z - (Z_COURT + 28.0f), p.x);
                    float vf = std::fmod(va + PI, PI / 15.0f);
                    float vg = std::min(vf, PI / 15.0f - vf) * 21.0f;
                    d_vous += 0.42f * (1.0f - smoothstep(0.12f, 0.55f, vg));
                }
                d_gh = smin(d_gh, d_vous, 0.32f);
                ghProtect = std::min(ghProtect, smoothstep(-0.4f, 1.5f, d_vous));
            }

            // Carved medieval heater shield centered on the 20 mm-wide central gate merlon
            {
                float sx = std::fabs(p.x);
                float sz = p.z - (Z_WALL_DECK + 11.0f);
                float wAtZ = (sz >= -0.5f) ? 4.6f : lerpf(4.6f, 0.5f, clampf((-0.5f - sz) / 5.5f, 0.0f, 1.0f));
                float d_sh2d = std::max(sx - wAtZ, std::max(sz - 5.4f, -6.0f - sz));
                float d_shield = std::max(d_sh2d, std::fabs(p.y - (GH_PARA_Y_MIN - 0.1f)) - 1.35f) - 0.35f;
                float d_cr = std::min(std::fabs(p.x) - 0.85f, std::fabs(p.z - (Z_WALL_DECK + 11.7f)) - 0.85f);
                float d_sh_cr = std::max(std::max(d_cr, d_sh2d + 1.2f), std::fabs(p.y - (GH_PARA_Y_MIN - 1.0f)) - 0.75f) - 0.2f;
                d_gh = smin(d_gh, smin(d_shield, d_sh_cr, 0.25f), 0.35f);
                ghProtect = std::min(ghProtect, smoothstep(-0.4f, 1.5f, d_shield));
                // Matching interior corbel ribs on gatehouse courtyard slope (skipping gate tunnel |x| < 22)
                float inGhCorb = smoothstep(Z_WALL_DECK - 11.2f, Z_WALL_DECK - 8.5f, p.z)
                               * smoothstep(Z_WALL_DECK - 1.2f, Z_WALL_DECK - 3.0f, p.z)
                               * smoothstep(GH_COURT_LOW_Y - 1.5f, GH_COURT_LOW_Y + 2.0f, p.y)
                               * smoothstep(20.5f, 23.0f, std::fabs(p.x));
                if (inGhCorb > 0.001f) {
                    float uf = std::fabs(std::fmod(p.x + 300.0f, 10.5f) - 5.25f);
                    d_gh -= 0.65f * smoothstep(2.3f, 1.2f, uf) * inGhCorb;
                }
            }

            // Protect the stair well side cheeks (|x| <= 21, z <= Z_COURT) from ashlar bleed
            if (p.z < Z_COURT + 1.0f && p.y < GH_Y_MIN + 1.0f) {
                ghProtect = std::min(ghProtect, smoothstep(19.0f, 22.0f, std::fabs(p.x)));
            }

            // Fine ashlar stone on EXTERIOR (all the way down the 25 mm battered base to z = 0.5!) & COURTYARD gatehouse walls
            if (std::fabs(d_gh) < 2.5f) {
                float floorMask = (p.y > GH_WALK_Y_MIN - 0.6f && p.y < GH_Y_MAX + 2.0f)
                                ? smoothstep(1.8f, 0.2f, std::fabs(p.z - Z_WALL_DECK)) : 0.0f;
                if (floorMask < 0.85f && p.z > 0.2f) {
                    bool isSideFace = ((std::fabs(p.x) - (GH_HALF_X + gBat)) > ((GH_Y_MIN - gBat) - p.y)) && (p.y < WALL_OUT_Y_MIN + 8.5f);
                    float u = isSideFace ? (p.y + 145.0f) : (p.x + 100.0f);
                    int seed = isSideFace ? (p.x > 0 ? 206 : 207) : 205;
                    float disp = ashlarDisplacement(u, p.z, 4.6f, 8.8f, 0.50f, 0.32f, seed);
                    float ghSlopeFade = (p.y > GH_COURT_LOW_Y - 1.5f && p.z > Z_WALL_DECK - 12.5f && p.z < Z_WALL_DECK - 1.0f) ? 0.25f : 1.0f;
                    bool isExtGh = (p.y < GH_Y_MIN + 2.5f) || (std::fabs(p.x) > 35.5f && p.y < WALL_OUT_Y_MIN + 5.5f);
                    float ghDeckFade = isExtGh ? 1.0f : smoothstep(0.0f, 1.5f, std::fabs(p.z - Z_WALL_DECK));
                    float ghBotFade  = isExtGh ? smoothstep(0.5f, 3.0f, p.z) : smoothstep(Z_COURT - 2.0f, Z_COURT + 2.5f, p.z);
                    float topMask = smoothstep(0.0f, 1.2f, Z_WALL_PARA - p.z)
                                  * ghDeckFade
                                  * ghBotFade;
                    d_gh -= disp * topMask * ghProtect * ghSlopeFade;
                }
            }
            d = smin(d, d_gh, 0.75f);
            // Re-flatten gatehouse & front wall top deck AFTER smin(d_walls, d_gh) -> exact 0.000 mm flat z = Z_WALL_DECK
            float d_gh_flat = std::min(sdBoxMinMax(p, -GH_WALK_HALF_X, GH_WALK_HALF_X, GH_WALK_Y_MIN, GH_Y_MAX + 4.0f, Z_WALL_DECK, 125.0f, 0.0f),
                                       sdBoxMinMax(p, -44.0f, 44.0f, WALL_WALK_OUT_Y0, GH_Y_MAX + 4.0f, Z_WALL_DECK, 125.0f, 0.0f));
            d = std::max(d, -d_gh_flat);
        }

        // CARVE 100% SMOOTH PASS-THROUGH POINTED GOTHIC GATE TUNNEL (38 mm wide x 52 mm tall, z = 15..67 mm)
        // Extends out to GH_Y_MIN - 15.0 to clear the full +12 mm gatehouse base flare cleanly!
        {
            float d_tb = sdBoxMinMax(p, -24.0f, 24.0f, GH_Y_MIN - 16.0f, GH_Y_MAX + 6.0f, Z_COURT - 2.0f, Z_COURT + 56.0f);
            if (d_tb < 4.0f) {
                float d_tunnel = sdGothicTunnelY(p, 0.0f, GATE_HALF_W, GH_Y_MIN - 15.0f, GH_Y_MAX + 5.0f, Z_COURT, Z_COURT + 28.0f, Z_COURT + 52.0f);
                d = std::max(d, -d_tunnel);
            }
        }
    }

    // ------------------------------------------------------------------------
    // 6. FULL-WIDTH REAR-ANCHORED STAIRCASES (z = 15 -> 75 mm!)
    //    8 steps of 8.0 mm tread x 7.5 mm rise (y = 29..93) aligned cleanly with the shortened Keep!
    // ------------------------------------------------------------------------
    {
        float sx = std::fabs(p.x);
        float d_sb = sdBoxMinMax(Vec3(sx, p.y, p.z), 50.0f, 107.0f, 26.0f, 107.0f, Z_COURT - 3.0f, Z_WALL_DECK + 3.0f);
        if (d_sb < d + 3.0f) {
            float y0 = 29.0f;
            float y1 = 93.0f; // lands flush against the rear curtain wall walk (y >= 93, z = 75mm)!
            int numSteps = 8;
            float stepRun  = (y1 - y0) / float(numSteps);            // 8.0 mm deep treads (exact LEGO pitch)!
            float stepRise = (Z_WALL_DECK - Z_COURT) / float(numSteps); // 7.5 mm rise (<45 deg)!

            float d_stair = 1e9f;
            for (int i = 0; i < numSteps; ++i) {
                float sy0 = y0 + i * stepRun;
                float sz1 = Z_COURT + (i + 1) * stepRise;
                float sxMax = (i == numSteps - 1) ? 94.5f : 105.0f;
                float syMax = (i == numSteps - 1) ? 95.5f : 105.0f;
                float b = sdBoxMinMax(Vec3(sx, p.y, p.z), 51.0f, sxMax, sy0, syMax, Z_COURT - 2.0f, sz1, 0.35f);
                d_stair = std::min(d_stair, b);
            }
            d = smin(d, d_stair, 0.55f);
        }
    }

    // ------------------------------------------------------------------------
    // 7. SINGLE FLAT-TOPPED 2-LEVEL OPEN-BACK KEEP (DONJON) — 215.0 mm TOTAL HEIGHT
    //    Spans x in [-52, +52] (104 mm wide), y in [+36, +123.5] (87.5 mm deep, flush with rear wall)
    //    Flat roof deck at z = 195.0 mm, 20 mm crenellations to EXACT z = 215.0 mm
    //    Back wall cleanly OPEN across 2 spacious LEGO-friendly levels:
    //      Level 1 (Great Hall):    floor z = 23.0 .. ceiling z = 102.0 (79 mm clear)
    //      Level 2 (Upper Chamber): floor z = 109.0.. ceiling z = 187.0 (78 mm clear)
    // ------------------------------------------------------------------------
    {
        float d_kb = sdBoxMinMax(p, -61.0f, 61.0f, KEEP_Y0 - 20.0f, 134.5f, Z_COURT - 10.0f, Z_KEEP_PARA + 3.0f);
        if (d_kb < d + 4.0f) {
            float kx0 = KEEP_X0, kx1 = KEEP_X1;
            float ky0 = KEEP_Y0, ky1 = KEEP_Y1;
            float kcx = KEEP_CX, kcy = KEEP_CY;
            float khx = KEEP_HX, khy = KEEP_HY;

            // 7a. Main Keep Body + Battered Plinth (clamped flush at rear wall so the rear wall's 25 mm batter is seamless!)
            float d_kp_plinth = sdBatteredBox(p, kcx, kcy, Z_COURT - 4.0f, Z_COURT + 20.0f, khx + 4.5f, khy + 4.5f, khx, khy, 0.9f);
            d_kp_plinth = std::max(d_kp_plinth, p.y - KEEP_Y1);
            float d_kp_shaft  = sdBoxMinMax(p, kx0, kx1, ky0, ky1, Z_COURT + 16.0f, Z_KEEP_DECK + 1.0f, 0.9f);
            float d_kp_crown  = sdCorbelParapetBox(p, kcx, kcy, kcy,
                                                   Z_KEEP_DECK - 8.2f, Z_KEEP_DECK - 1.5f, Z_KEEP_PARA,
                                                   khx - 0.5f, khy - 0.5f, khx + 3.5f, khy + 3.5f, 0.7f);
            float d_keep = smin(std::min(d_kp_plinth, d_kp_shaft), d_kp_crown, 0.75f);

            // 7b. Classic Norman Stepped Corner Buttresses & Side Wall Pilasters (step aligned at Floor 2!)
            //     Extended down to z = Z_COURT - 8 so rear corner buttresses sink smoothly into the 25 mm rear batter!
            {
                float set1 = smoothstep(Z_L2_FLOOR - 5.0f, Z_L2_FLOOR - 0.5f, p.z);
                float buttOut = 3.5f - 1.3f * set1;

                float axk = std::fabs(p.x - kcx);
                float ayk = std::fabs(p.y - kcy);
                float d_cbut = sdBoxMinMax(Vec3(axk, ayk, p.z), khx - 10.0f, khx + buttOut, khy - 12.0f, khy + buttOut,
                                           Z_COURT - 8.0f, Z_KEEP_DECK - 6.5f, 0.75f);
                float d_sbutLR = sdBoxMinMax(Vec3(axk, ayk, p.z), khx - 2.0f, khx + buttOut * 0.75f, 0.0f, 6.8f,
                                             Z_COURT - 2.0f, Z_KEEP_DECK - 6.5f, 0.65f);
                d_keep = smin(d_keep, std::min(d_cbut, d_sbutLR), 0.55f);
            }

            // 7c. Projecting 45-deg Stone Stringcourse (Belt Course) aligned cleanly with Floor 2 slab
            {
                float zb = Z_L2_FLOOR - 3.0f;
                if (std::fabs(p.z - zb) < 4.5f) {
                    float d_b1 = sdBatteredBox(p, kcx, kcy, zb - 2.2f, zb, khx - 0.2f, khy - 0.2f, khx + 1.6f, khy + 1.6f, 0.35f);
                    float d_b2 = sdBatteredBox(p, kcx, kcy, zb, zb + 1.6f, khx + 1.6f, khy + 1.6f, khx - 0.2f, khy - 0.2f, 0.35f);
                    d_keep = smin(d_keep, std::min(d_b1, d_b2), 0.4f);
                }
            }

            // 7d. Corbel brackets under Keep battlement overhang
            {
                float axk = std::fabs(p.x - kcx) - khx;
                float ayk = std::fabs(p.y - kcy) - khy;
                float mXY = std::max(axk, ayk);
                float corbM = smoothstep(Z_KEEP_DECK - 8.2f, Z_KEEP_DECK - 5.4f, p.z)
                            * smoothstep(Z_KEEP_DECK + 0.4f, Z_KEEP_DECK - 2.2f, p.z)
                            * smoothstep(-1.5f, 0.5f, mXY) * smoothstep(5.5f, 3.0f, mXY);
                if (corbM > 0.001f) {
                    float u = (axk > ayk) ? (p.y - kcy) : (p.x - kcx);
                    float uf = std::fabs(std::fmod(u + 200.0f, 10.5f) - 5.25f);
                    d_keep -= 0.78f * smoothstep(2.4f, 1.3f, uf) * corbM;
                }
            }

            // 7e. Hollow out Keep's single exact-flat walkable roof deck (z = Z_KEEP_DECK = 195.0 mm)
            float d_kp_deck = sdBoxMinMax(p, kx0 + 4.8f, kx1 - 4.8f, ky0 + 4.8f, ky1 - 4.8f, Z_KEEP_DECK, 245.0f, 0.0f);
            d_keep = std::max(d_keep, -d_kp_deck);

            // 7f. Explicit sliver-free 22 mm crenellations (~50% wider merlons & 15.5 mm crenels along Keep crown!)
            if (p.z > Z_KEEP_DECK + 8.0f && p.z < Z_KEEP_PARA + 3.0f) {
                float axk = std::fabs(p.x - kcx) - khx;
                float ayk = std::fabs(p.y - kcy) - khy;
                if (std::max(axk, ayk) > -6.0f) {
                    float d_emb_u = 1e6f;
                    if (axk > ayk) {
                        // Left & Right faces (81.5 mm after 13 mm Keep shortening):
                        // 2 wide 14.5 mm crenels at |y - kcy| = 15.5 -> 16.5 mm center merlon, 18.0 mm corner merlons!
                        float dyAbs = std::fabs(p.y - kcy);
                        d_emb_u = std::fabs(dyAbs - 15.50f) - 6.70f;
                    } else {
                        // Front & Rear faces (111.0 mm): 3 wide 15.5 mm crenels at |x| = 0, 32.0 -> 16.5 mm interior merlons
                        float dxAbs = std::fabs(p.x - kcx);
                        d_emb_u = std::min(dxAbs - 7.20f, std::fabs(dxAbs - 32.0f) - 7.20f);
                    }
                    float d_emb = std::max(d_emb_u, (Z_KEEP_DECK + PARA_H * 0.5f) - p.z);
                    d_keep = smax(d_keep, -(d_emb - 0.55f), 0.60f);
                }
            }

            // 7g. Grand Ceremonial Front Steps & Gothic Portal Frame (Front of Keep, y = KEEP_Y0 = +49, z = 23..75)
            float portalProtect = 1.0f;
            {
                float d_fb = sdBoxMinMax(p, -29.0f, 29.0f, KEEP_Y0 - 16.0f, KEEP_Y0 + 8.0f, Z_COURT - 2.0f, Z_L1_FLOOR + 60.0f);
                if (d_fb < d_keep + 3.5f) {
                    // 2 broad ceremonial stone steps rising from courtyard z=15 -> z=23mm
                    for (int s = 0; s < 2; ++s) {
                        float sy0 = (KEEP_Y0 - 12.0f) + s * 6.0f;
                        float sz1 = Z_COURT + 4.0f * (s + 1);
                        d_keep = smin(d_keep, sdBoxMinMax(p, -22.0f, 22.0f, sy0, KEEP_Y0 + 2.0f, Z_COURT - 2.0f, sz1, 0.45f), 0.4f);
                    }
                    // Flanking low carved stone stair cheeks
                    float d_cheek = sdBoxMinMax(Vec3(std::fabs(p.x), p.y, p.z), 20.0f, 24.2f, KEEP_Y0 - 11.5f, KEEP_Y0 + 1.0f, Z_COURT - 2.0f, Z_COURT + 11.5f, 0.55f);
                    d_keep = smin(d_keep, d_cheek, 0.45f);

                    // Carved Gothic Portal Voussoir Frame on Keep Front Face (30mm wide x 52mm tall opening!)
                    float d_po = sdGothicArch2D(p.x, p.z, 19.2f, Z_L1_FLOOR - 1.0f, Z_L1_FLOOR + 28.0f, Z_L1_FLOOR + 57.0f);
                    float d_pi = sdGothicArch2D(p.x, p.z, 15.0f, Z_L1_FLOOR - 1.0f, Z_L1_FLOOR + 28.0f, Z_L1_FLOOR + 52.0f);
                    float d_pframe = std::max(std::max(d_po, -d_pi), std::fabs(p.y - (KEEP_Y0 - 0.4f)) - 1.8f);
                    if (std::fabs(d_pframe) < 2.0f && p.z > Z_L1_FLOOR + 27.0f) {
                        float va = std::atan2(p.z - (Z_L1_FLOOR + 28.0f), p.x);
                        float vf = std::fmod(va + PI, PI / 13.0f);
                        float vg = std::min(vf, PI / 13.0f - vf) * 17.0f;
                        d_pframe += 0.38f * (1.0f - smoothstep(0.10f, 0.50f, vg));
                    }
                    d_keep = smin(d_keep, d_pframe, 0.35f);
                    portalProtect = smoothstep(-0.4f, 1.5f, d_pframe);
                }
            }

            // 7h. Fine Ashlar Masonry on Exterior Keep Walls ONLY (roof & interior floors stay completely SMOOTH!)
            if (std::fabs(d_keep) < 2.5f && p.z < Z_KEEP_PARA + 1.0f) {
                float axk = std::fabs(p.x - kcx) - khx;
                float ayk = std::fabs(p.y - kcy) - khy;
                float terraceMask = (p.x > kx0 + 4.5f && p.x < kx1 - 4.5f && p.y > ky0 + 4.5f && p.y < ky1 - 4.5f)
                                  ? smoothstep(1.8f, 0.2f, std::fabs(p.z - Z_KEEP_DECK)) : 0.0f;

                if (terraceMask < 0.85f && p.z > Z_COURT - 2.0f) {
                    float u = (axk > ayk) ? (p.y - kcy) : (p.x - kcx);
                    int fseed = (axk > ayk) ? (p.x > 0 ? 501 : 502) : (p.y > kcy ? 503 : 504);
                    float disp = ashlarDisplacement(u + 120.0f, p.z, 4.6f, 9.0f, 0.50f, 0.32f, fseed);
                    float keepDeckFade = (std::max(axk, ayk) < -1.0f) ? smoothstep(0.0f, 1.5f, std::fabs(p.z - Z_KEEP_DECK)) : 1.0f;
                    float topMask = smoothstep(0.0f, 1.2f, Z_KEEP_PARA - p.z)
                                  * keepDeckFade
                                  * smoothstep(Z_COURT - 3.0f, Z_COURT + 2.0f, p.z);
                    d_keep -= disp * topMask * portalProtect;
                }
            }

            d = smin(d, d_keep, 0.80f);
        }
    }

    // ------------------------------------------------------------------------
    // 8. CARVE 2-LEVEL OPEN-BACK KEEP INTERIOR (WITH MATCHING ASHLAR STONEWORK ON INTERIOR WALLS!)
    //    Applied AFTER unioning curtain wall & Keep so the rear wall opens cleanly!
    //      Level 1 (Great Hall):    floor z = 23.0 .. ceiling z = 102.0 (79 mm clear) + 30x52 mm front portal
    //      Level 2 (Upper Chamber): floor z = 109.0.. ceiling z = 187.0 (78 mm clear) + 7 wide pass-through windows
    // ------------------------------------------------------------------------
    {
        static constexpr float KEEP_IN_Y0 = KEEP_Y0 + 9.0f; // +58.0 mm (preserves exact 9.0 mm Keep front wall thickness)
        float d_open_bound = sdBoxMinMax(p, -58.0f, 58.0f, KEEP_Y0 - 6.0f, 134.0f, Z_L1_FLOOR - 2.0f, Z_KEEP_DECK);
        if (d_open_bound < 4.0f) {
            float d_room1 = sdBoxMinMax(p, -43.0f, 43.0f, KEEP_IN_Y0, 132.0f, Z_L1_FLOOR, Z_L1_FLOOR + 79.0f, 0.8f);
            float d_room2 = sdBoxMinMax(p, -43.0f, 43.0f, KEEP_IN_Y0, 132.0f, Z_L2_FLOOR, Z_L2_FLOOR + 78.0f, 0.8f);
            float d_rooms = std::min(d_room1, d_room2);

            // Apply the exact same fine ashlar masonry (4.6 x 9.0 mm blocks) to the 3 vertical interior Keep walls
            // (left x=-43, right x=+43, front y=KEEP_IN_Y0), keeping floors, ceilings, and window/portal arches completely crisp!
            if (std::fabs(d_rooms) < 2.2f && p.y < KEEP_Y1 - 0.2f) {
                float dxIn = 43.0f - std::fabs(p.x);
                float dyIn = p.y - KEEP_IN_Y0;
                if (std::min(dxIn, dyIn) < 2.2f) {
                    float zMask1 = smoothstep(Z_L1_FLOOR + 0.6f, Z_L1_FLOOR + 2.4f, p.z)
                                 * smoothstep(Z_L1_FLOOR + 78.4f, Z_L1_FLOOR + 76.4f, p.z);
                    float zMask2 = smoothstep(Z_L2_FLOOR + 0.6f, Z_L2_FLOOR + 2.4f, p.z)
                                 * smoothstep(Z_L2_FLOOR + 77.4f, Z_L2_FLOOR + 75.4f, p.z);
                    float zMask  = std::max(zMask1, zMask2);
                    float backFade = smoothstep(KEEP_Y1 - 0.3f, KEEP_Y1 - 2.2f, p.y);
                    if (zMask * backFade > 0.001f) {
                        bool onSide = (dxIn < dyIn);
                        float u = onSide ? (p.y + 120.0f) : (p.x + 120.0f);
                        int iseed = onSide ? (p.x > 0 ? 601 : 602) : 603;
                        float disp = ashlarDisplacement(u, p.z, 4.6f, 9.0f, 0.50f, 0.32f, iseed);
                        // Positive disp pushes solid wall inward into the room; negative disp carves mortar joints into wall!
                        d_rooms += disp * zMask * backFade;
                    }
                }
            }

            float d_cut = d_rooms;

            // Level 1 Front Gothic Portal opening ALL THE WAY THROUGH into Level 1 Great Hall (30 mm wide x 52 mm tall)
            float d_portal = sdGothicTunnelY(p, 0.0f, 15.0f, KEEP_Y0 - 6.0f, KEEP_Y0 + 14.0f, Z_L1_FLOOR, Z_L1_FLOOR + 28.0f, Z_L1_FLOOR + 52.0f);
            d_cut = std::min(d_cut, d_portal);

            // Level 2 Pass-Through Gothic Lancet Windows (floor z=109 -> sill z=121 (+12 mm), peak z=161 (+52 mm))
            // Generous width so LEGO minifigure heads, helmets & shields are clearly visible
            if (p.z > Z_L2_FLOOR + 9.0f && p.z < Z_L2_FLOOR + 57.0f) {
                // Front face (y = KEEP_Y0..KEEP_IN_Y0): Triple grand lancet windows at x = -25, 0, +25
                float d_w2fC = sdGothicTunnelY(p, 0.0f, 6.5f, KEEP_Y0 - 5.0f, KEEP_Y0 + 13.0f, Z_L2_FLOOR + 12.0f, Z_L2_FLOOR + 39.0f, Z_L2_FLOOR + 52.0f);
                float d_w2fS = sdGothicTunnelY(Vec3(std::fabs(p.x), p.y, p.z), 25.0f, 6.5f, KEEP_Y0 - 5.0f, KEEP_Y0 + 13.0f, Z_L2_FLOOR + 12.0f, Z_L2_FLOOR + 39.0f, Z_L2_FLOOR + 52.0f);
                // Left & Right faces (x = ±43..±52): Twin grand lancet windows centered in the two 18.45 mm bays at y = 70.25 and 102.25
                float d_w2s1 = sdGothicTunnelX(Vec3(std::fabs(p.x), p.y, p.z), KEEP_CY - 16.0f, 6.2f, 40.0f, 58.0f, Z_L2_FLOOR + 12.0f, Z_L2_FLOOR + 39.0f, Z_L2_FLOOR + 52.5f);
                float d_w2s2 = sdGothicTunnelX(Vec3(std::fabs(p.x), p.y, p.z), KEEP_CY + 16.0f, 6.2f, 40.0f, 58.0f, Z_L2_FLOOR + 12.0f, Z_L2_FLOOR + 39.0f, Z_L2_FLOOR + 52.5f);
                d_cut = std::min(d_cut, std::min(std::min(d_w2fC, d_w2fS), std::min(d_w2s1, d_w2s2)));
            }

            d = smax(d, -d_cut, 0.45f);
        }
    }

    // ------------------------------------------------------------------------
    // 9. PRECISION LEGO-COMPATIBLE STUDS ON ALL WALKABLE SURFACES & STAIRS
    //    Sharp union (std::min, zero base fillet!) so minifigure feet seat flush on flat floors!
    // ------------------------------------------------------------------------
    d = std::min(d, legoStudsSDF(p, d));

    // ------------------------------------------------------------------------
    // 10. EXACT DEAD-FLAT BASE AT z = 0.000 mm AND BOUNDING ENVELOPE CLAMP
    // ------------------------------------------------------------------------
    d = std::max(d, -p.z);
    d = std::max(d, p.z - Z_KEEP_PARA);
    d = std::max(d, std::fabs(p.x) - HALF_X);
    d = std::max(d, std::fabs(p.y) - HALF_Y);

    return d;
}

inline Vec3 calcNormal(const Vec3& p, float eps = 0.18f) {
    float dx = castleSDF({p.x + eps, p.y, p.z}) - castleSDF({p.x - eps, p.y, p.z});
    float dy = castleSDF({p.x, p.y + eps, p.z}) - castleSDF({p.x, p.y - eps, p.z});
    float dz = castleSDF({p.x, p.y, p.z + eps}) - castleSDF({p.x, p.y, p.z - eps});
    return normalize({dx, dy, dz});
}

// ============================================================================
// Built-In Studio Raymarcher (Soft Shadows & AO)
// ============================================================================
float traceRay(const Vec3& ro, const Vec3& rd, float tMax) {
    Vec3 bmin(-151.0f, -151.0f, -0.5f);
    Vec3 bmax( 151.0f,  151.0f, 224.0f);
    float t0 = 0.0f, t1 = tMax;
    for (int a = 0; a < 3; ++a) {
        float o = (&ro.x)[a], d = (&rd.x)[a];
        float mn = (&bmin.x)[a], mx = (&bmax.x)[a];
        if (std::fabs(d) < 1e-8f) {
            if (o < mn || o > mx) return -1.0f;
        } else {
            float inv = 1.0f / d;
            float ta = (mn - o) * inv, tb = (mx - o) * inv;
            if (ta > tb) std::swap(ta, tb);
            t0 = std::max(t0, ta);
            t1 = std::min(t1, tb);
            if (t0 > t1) return -1.0f;
        }
    }
    float t = t0;
    for (int i = 0; i < 340; ++i) {
        Vec3 pos = ro + rd * t;
        float dist = castleSDF(pos);
        if (dist < 0.05f) return t;
        t += std::max(dist * 0.62f, 0.05f);
        if (t > t1) return -1.0f;
    }
    return -1.0f;
}

float calcSoftShadow(const Vec3& ro, const Vec3& rd, float tMax) {
    float res = 1.0f;
    float t = 1.2f;
    for (int i = 0; i < 72; ++i) {
        float h = castleSDF(ro + rd * t);
        if (h < 0.05f) return 0.0f;
        res = std::min(res, 6.0f * h / t);
        t += clampf(h * 0.65f, 0.5f, 10.0f);
        if (t > tMax) break;
    }
    return clampf(res, 0.0f, 1.0f);
}

float calcAO(const Vec3& p, const Vec3& n) {
    float occ = 0.0f, sca = 1.0f;
    for (int i = 1; i <= 5; ++i) {
        float h = 0.7f + 2.2f * float(i);
        float d = castleSDF(p + n * h);
        occ += (h - d) * sca;
        sca *= 0.68f;
    }
    return clampf(1.0f - 0.14f * occ, 0.12f, 1.0f);
}

void renderView(const std::string& filename, int W, int H,
                const Vec3& camPos, const Vec3& target, float fovDeg,
                const Vec3& customSun = Vec3(0.58f, -0.52f, 0.63f)) {
    Vec3 fwd = normalize(target - camPos);
    Vec3 worldUp = (std::fabs(fwd.z) > 0.98f) ? Vec3(0, 1, 0) : Vec3(0, 0, 1);
    Vec3 right = normalize(cross(fwd, worldUp));
    Vec3 up = cross(right, fwd);
    float tanHalf = std::tan(fovDeg * 0.5f * PI / 180.0f);
    float aspect = float(W) / float(H);

    Vec3 sunDir = normalize(customSun);
    Vec3 fillDir = normalize(Vec3(-customSun.x, -customSun.y * 0.6f, 0.45f));

    std::vector<uint8_t> img(W * H * 3, 0);

    #pragma omp parallel for schedule(dynamic, 8)
    for (int y = 0; y < H; ++y) {
        float py = (1.0f - 2.0f * (y + 0.5f) / float(H)) * tanHalf;
        for (int x = 0; x < W; ++x) {
            float px = (2.0f * (x + 0.5f) / float(W) - 1.0f) * tanHalf * aspect;
            Vec3 rd = normalize(fwd + right * px + up * py);

            float bgT = clampf(0.5f + 0.5f * rd.z, 0.0f, 1.0f);
            float r = lerpf(0.18f, 0.28f, bgT);
            float g = lerpf(0.20f, 0.31f, bgT);
            float b = lerpf(0.24f, 0.36f, bgT);

            float tGround = (rd.z < -1e-4f) ? (-camPos.z / rd.z) : -1.0f;
            float tHit = traceRay(camPos, rd, 1800.0f);

            if (tHit > 0.0f) {
                Vec3 pos = camPos + rd * tHit;
                Vec3 n = calcNormal(pos, 0.16f);
                float ao = calcAO(pos, n);
                float sh = calcSoftShadow(pos + n * 0.45f, sunDir, 420.0f);

                float diff = std::max(dot(n, sunDir), 0.0f) * sh;
                float fill = std::max(dot(n, fillDir), 0.0f) * 0.30f;
                float hemi = (0.5f + 0.5f * n.z) * 0.32f;

                float stoneVar = 0.94f + 0.08f * fbm3(pos.x * 0.05f, pos.y * 0.05f, pos.z * 0.05f, 2);
                float baseTint = smoothstep(0.0f, 10.0f, pos.z);
                float br = lerpf(0.71f, 0.78f, baseTint) * stoneVar;
                float bg = lerpf(0.69f, 0.76f, baseTint) * stoneVar;
                float bb = lerpf(0.65f, 0.72f, baseTint) * stoneVar;

                Vec3 halfV = normalize(sunDir - rd);
                float spec = std::pow(std::max(dot(n, halfV), 0.0f), 28.0f) * 0.16f * sh;

                r = br * (diff * 0.98f + fill * 0.85f + hemi * 0.92f) * ao + spec;
                g = bg * (diff * 0.94f + fill * 0.90f + hemi * 0.96f) * ao + spec;
                b = bb * (diff * 0.87f + fill * 1.00f + hemi * 1.05f) * ao + spec;
            } else if (tGround > 0.0f && tGround < 1600.0f) {
                Vec3 gp = camPos + rd * tGround;
                float distC = std::hypot(gp.x, gp.y);
                if (distC < 420.0f) {
                    float sh = calcSoftShadow(gp + Vec3(0, 0, 0.5f), sunDir, 420.0f);
                    float fade = smoothstep(420.0f, 170.0f, distC);
                    float gx = std::fabs(std::fmod(gp.x + 500.0f, 50.0f) - 25.0f);
                    float gy = std::fabs(std::fmod(gp.y + 500.0f, 50.0f) - 25.0f);
                    float grid = (std::min(25.0f - gx, 25.0f - gy) < 0.7f && std::fabs(gp.x) <= 150.0f && std::fabs(gp.y) <= 150.0f) ? 0.06f : 0.0f;
                    float plate = (std::fabs(gp.x) <= 150.0f && std::fabs(gp.y) <= 150.0f) ? 0.05f : 0.0f;
                    float fl = (0.34f + plate + grid) * (0.45f + 0.55f * sh);
                    r = lerpf(r, fl, fade);
                    g = lerpf(g, fl * 1.01f, fade);
                    b = lerpf(b, fl * 1.04f, fade);
                }
            }

            auto tonemap = [](float c) -> uint8_t {
                c = c / (1.0f + c * 0.35f);
                c = std::pow(clampf(c, 0.0f, 1.0f), 1.0f / 2.2f);
                return (uint8_t)clampf(c * 255.0f + 0.5f, 0.0f, 255.0f);
            };
            size_t idx = (size_t(y) * W + x) * 3;
            img[idx + 0] = tonemap(r);
            img[idx + 1] = tonemap(g);
            img[idx + 2] = tonemap(b);
        }
    }

    std::ofstream out(filename, std::ios::binary);
    out << "P6\n" << W << " " << H << "\n255\n";
    out.write(reinterpret_cast<const char*>(img.data()), img.size());
}

// ============================================================================
// Mathematically Guaranteed 100% Strict 2-Manifold Kuhn Marching Tetrahedra (MT6)
// ============================================================================
static constexpr int KUHN_TETS[6][4] = {
    {0, 1, 3, 7},
    {0, 3, 2, 7},
    {0, 2, 6, 7},
    {0, 6, 4, 7},
    {0, 4, 5, 7},
    {0, 5, 1, 7}
};

struct Mesh {
    std::vector<Vec3> verts;
    std::vector<std::array<uint32_t, 3>> tris;
};

struct EdgeKey {
    uint64_t a, b;
    bool operator==(const EdgeKey& o) const { return a == o.a && b == o.b; }
};
struct EdgeKeyHash {
    size_t operator()(const EdgeKey& k) const {
        uint64_t h = k.a * 0x9e3779b97f4a7c15ULL ^ (k.b + 0x9e3779b97f4a7c15ULL + (k.a << 6) + (k.a >> 2));
        return size_t(h ^ (h >> 33));
    }
};

void keepLargestComponent(Mesh& mesh) {
    size_t nV = mesh.verts.size();
    size_t nT = mesh.tris.size();
    std::vector<uint32_t> parent(nV);
    for (uint32_t i = 0; i < nV; ++i) parent[i] = i;

    auto find = [&](uint32_t x) {
        while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
        return x;
    };
    auto unite = [&](uint32_t a, uint32_t b) {
        a = find(a); b = find(b);
        if (a != b) parent[b] = a;
    };

    for (const auto& t : mesh.tris) {
        unite(t[0], t[1]);
        unite(t[1], t[2]);
    }

    std::unordered_map<uint32_t, size_t> compCount;
    for (const auto& t : mesh.tris) compCount[find(t[0])]++;

    uint32_t bestRoot = 0;
    size_t bestSize = 0;
    for (const auto& kv : compCount) {
        if (kv.second > bestSize) { bestSize = kv.second; bestRoot = kv.first; }
    }
    if (compCount.size() <= 1) return;

    std::cout << "Connected components: " << compCount.size()
              << " -> keeping main castle body (" << bestSize << " / " << nT << " tris)\n" << std::flush;

    std::vector<uint32_t> remap(nV, UINT32_MAX);
    std::vector<Vec3> newVerts; newVerts.reserve(nV);
    std::vector<std::array<uint32_t, 3>> newTris; newTris.reserve(bestSize);
    for (const auto& t : mesh.tris) {
        if (find(t[0]) != bestRoot) continue;
        std::array<uint32_t, 3> nt;
        for (int k = 0; k < 3; ++k) {
            if (remap[t[k]] == UINT32_MAX) {
                remap[t[k]] = (uint32_t)newVerts.size();
                newVerts.push_back(mesh.verts[t[k]]);
            }
            nt[k] = remap[t[k]];
        }
        newTris.push_back(nt);
    }
    mesh.verts.swap(newVerts);
    mesh.tris.swap(newTris);
}

void verifyManifold(const Mesh& mesh, const char* tag) {
    std::unordered_map<uint64_t, int> halfEdgeCount;
    halfEdgeCount.reserve(mesh.tris.size() * 3);
    auto heKey = [](uint32_t a, uint32_t b) -> uint64_t { return (uint64_t(a) << 32) | uint64_t(b); };
    for (const auto& t : mesh.tris) {
        halfEdgeCount[heKey(t[0], t[1])]++;
        halfEdgeCount[heKey(t[1], t[2])]++;
        halfEdgeCount[heKey(t[2], t[0])]++;
    }
    size_t dupDirected = 0, unmatchedOpp = 0;
    for (const auto& kv : halfEdgeCount) {
        if (kv.second != 1) dupDirected++;
        uint32_t a = uint32_t(kv.first >> 32);
        uint32_t b = uint32_t(kv.first & 0xFFFFFFFFULL);
        auto it = halfEdgeCount.find(heKey(b, a));
        if (it == halfEdgeCount.end() || it->second != 1) unmatchedOpp++;
    }
    std::cout << "[" << tag << "] Manifold self-check: V=" << mesh.verts.size()
              << " F=" << mesh.tris.size()
              << " E=" << (halfEdgeCount.size() / 2)
              << " dupDirected=" << dupDirected
              << " unmatchedOpp=" << unmatchedOpp
              << " Euler=" << (int64_t(mesh.verts.size()) - int64_t(halfEdgeCount.size() / 2) + int64_t(mesh.tris.size()))
              << "\n" << std::flush;
}

Mesh extractWatertightMesh(float h, bool projectToSurface = true) {
    const float x0 = -150.0f, y0 = -150.0f;
    const float z0 = -0.5f * h;
    const int nx = (int)std::ceil(300.0f / h) + 3;
    const int ny = (int)std::ceil(300.0f / h) + 3;
    const int nz = (int)std::ceil(220.0f / h) + 3;

    std::cout << "Strict-Manifold MT6 Grid: " << nx << " x " << ny << " x " << nz
              << " (voxel h=" << h << " mm, total=" << (double(nx)*ny*nz/1e6) << "M)\n" << std::flush;

    const int B = 8;
    const int cnx = (nx + B - 1) / B;
    const int cny = (ny + B - 1) / B;
    const int cnz = (nz + B - 1) / B;
    const float blockDiag = 0.5f * B * h * std::sqrt(3.0f) + 6.0f * h;

    std::vector<uint8_t> blockState(size_t(cnx) * cny * cnz, 0);
    size_t activeCount = 0;

    #pragma omp parallel for reduction(+:activeCount) schedule(dynamic)
    for (int bz = 0; bz < cnz; ++bz) {
        for (int by = 0; by < cny; ++by) {
            for (int bx = 0; bx < cnx; ++bx) {
                float cx = x0 + (bx * B + 0.5f * B) * h;
                float cy = y0 + (by * B + 0.5f * B) * h;
                float cz = z0 + (bz * B + 0.5f * B) * h;
                float d = castleSDF({cx, cy, cz});
                uint8_t st = 1;
                if (d > blockDiag + 8.0f)         st = 0;
                else if (d < -(blockDiag + 8.0f)) st = 2;
                blockState[(size_t(bz) * cny + by) * cnx + bx] = st;
                if (st == 1) activeCount++;
            }
        }
    }
    std::cout << "Narrow-band active blocks: " << activeCount << " / " << blockState.size()
              << " (" << (100.0 * activeCount / blockState.size()) << "%)\n" << std::flush;

    const size_t sliceSize = size_t(nx) * ny;
    std::vector<float> sliceA(sliceSize, 100.0f);
    std::vector<float> sliceB(sliceSize, 100.0f);

    auto evalSliceExact = [&](int iz, std::vector<float>& slice) {
        if (iz == nz - 1) { std::fill(slice.begin(), slice.end(), 100.0f); return; }
        int bz0 = std::max(0, (iz - 1) / B);
        int bz1 = std::min(cnz - 1, (iz + 1) / B);
        float z = z0 + iz * h;
        #pragma omp parallel for schedule(dynamic, 4)
        for (int iy = 0; iy < ny; ++iy) {
            if (iy == 0 || iy == ny - 1) {
                for (int ix = 0; ix < nx; ++ix) slice[size_t(iy) * nx + ix] = 100.0f;
                continue;
            }
            int by0 = std::max(0, (iy - 1) / B);
            int by1 = std::min(cny - 1, (iy + 1) / B);
            float y = y0 + iy * h;
            for (int ix = 0; ix < nx; ++ix) {
                if (ix == 0 || ix == nx - 1) {
                    slice[size_t(iy) * nx + ix] = 100.0f;
                    continue;
                }
                int bx0 = std::max(0, (ix - 1) / B);
                int bx1 = std::min(cnx - 1, (ix + 1) / B);
                bool needEval = false;
                uint8_t ownState = blockState[(size_t(iz / B) * cny + (iy / B)) * cnx + (ix / B)];
                for (int bz = bz0; bz <= bz1 && !needEval; ++bz)
                    for (int by = by0; by <= by1 && !needEval; ++by)
                        for (int bx = bx0; bx <= bx1 && !needEval; ++bx) {
                            uint8_t s = blockState[(size_t(bz) * cny + by) * cnx + bx];
                            if (s == 1 || s != ownState) needEval = true;
                        }
                if (!needEval) {
                    slice[size_t(iy) * nx + ix] = (ownState == 2) ? -100.0f : 100.0f;
                } else {
                    float val = castleSDF({x0 + ix * h, y, z});
                    if (val == 0.0f) val = 1e-6f;
                    slice[size_t(iy) * nx + ix] = val;
                }
            }
        }
    };

    Mesh mesh;
    std::unordered_map<EdgeKey, uint32_t, EdgeKeyHash> edgeVertMap;
    edgeVertMap.reserve(1 << 21);

    auto gridNodeId = [&](int ix, int iy, int iz) -> uint64_t {
        return (uint64_t(iz) * uint64_t(ny) + uint64_t(iy)) * uint64_t(nx) + uint64_t(ix);
    };

    struct RawTri {
        EdgeKey e[3];
        Vec3 v[3];
    };

    evalSliceExact(0, sliceA);
    int nThreads = omp_get_max_threads();
    std::vector<std::vector<RawTri>> tlsTris(nThreads);

    for (int iz = 0; iz < nz - 1; ++iz) {
        evalSliceExact(iz + 1, sliceB);
        for (auto& buf : tlsTris) buf.clear();

        #pragma omp parallel for schedule(dynamic, 4)
        for (int iy = 0; iy < ny - 1; ++iy) {
            int tid = omp_get_thread_num();
            auto& outTris = tlsTris[tid];
            for (int ix = 0; ix < nx - 1; ++ix) {
                float val[8] = {
                    sliceA[size_t(iy) * nx + ix],
                    sliceA[size_t(iy) * nx + ix + 1],
                    sliceA[size_t(iy + 1) * nx + ix],
                    sliceA[size_t(iy + 1) * nx + ix + 1],
                    sliceB[size_t(iy) * nx + ix],
                    sliceB[size_t(iy) * nx + ix + 1],
                    sliceB[size_t(iy + 1) * nx + ix],
                    sliceB[size_t(iy + 1) * nx + ix + 1]
                };

                int negMask = 0;
                for (int c = 0; c < 8; ++c) if (val[c] < 0.0f) negMask |= (1 << c);
                if (negMask == 0 || negMask == 255) continue;

                Vec3 pos[8];
                uint64_t nid[8];
                for (int c = 0; c < 8; ++c) {
                    int cx = ix + (c & 1);
                    int cy = iy + ((c >> 1) & 1);
                    int cz = iz + ((c >> 2) & 1);
                    pos[c] = {x0 + cx * h, y0 + cy * h, z0 + cz * h};
                    nid[c] = gridNodeId(cx, cy, cz);
                }

                for (int t = 0; t < 6; ++t) {
                    const int* tet = KUHN_TETS[t];
                    int inIdx[4], outIdx[4];
                    int nIn = 0, nOut = 0;
                    for (int k = 0; k < 4; ++k) {
                        if (val[tet[k]] < 0.0f) inIdx[nIn++] = k;
                        else outIdx[nOut++] = k;
                    }
                    if (nIn == 0 || nIn == 4) continue;

                    auto makeEdge = [&](int cA, int cB, EdgeKey& ek, Vec3& vp) {
                        uint64_t idA = nid[cA], idB = nid[cB];
                        if (idA < idB) ek = {idA, idB};
                        else           ek = {idB, idA};
                        float fA = val[cA], fB = val[cB];
                        float alpha = clampf(fA / (fA - fB), 0.04f, 0.96f);
                        vp = pos[cA] + (pos[cB] - pos[cA]) * alpha;
                        if (iz == 0 && std::fabs(vp.z) < 0.05f) vp.z = 0.0f;
                    };

                    auto emitTri = [&](int a1, int a2, int b1, int b2, int c1, int c2) {
                        RawTri rt;
                        makeEdge(a1, a2, rt.e[0], rt.v[0]);
                        makeEdge(b1, b2, rt.e[1], rt.v[1]);
                        makeEdge(c1, c2, rt.e[2], rt.v[2]);
                        outTris.push_back(rt);
                    };

                    if (nIn == 1) {
                        int i0 = tet[inIdx[0]];
                        int o0 = tet[outIdx[0]], o1 = tet[outIdx[1]], o2 = tet[outIdx[2]];
                        if (dot(cross(pos[o1] - pos[o0], pos[o2] - pos[o0]), pos[o0] - pos[i0]) < 0.0f) {
                            std::swap(o1, o2);
                        }
                        emitTri(i0, o0, i0, o1, i0, o2);
                    } else if (nIn == 3) {
                        int o0 = tet[outIdx[0]];
                        int i0 = tet[inIdx[0]], i1 = tet[inIdx[1]], i2 = tet[inIdx[2]];
                        if (dot(cross(pos[i1] - pos[i0], pos[i2] - pos[i0]), pos[o0] - pos[i0]) < 0.0f) {
                            std::swap(i1, i2);
                        }
                        emitTri(i0, o0, i1, o0, i2, o0);
                    } else {
                        int i0 = tet[inIdx[0]], i1 = tet[inIdx[1]];
                        int o0 = tet[outIdx[0]], o1 = tet[outIdx[1]];
                        Vec3 nRef = cross(pos[o1] - pos[o0], pos[i1] - pos[i0]);
                        Vec3 outRef = (pos[o0] + pos[o1]) - (pos[i0] + pos[i1]);
                        if (dot(nRef, outRef) < 0.0f) {
                            std::swap(o0, o1);
                        }
                        emitTri(i0, o0, i0, o1, i1, o1);
                        emitTri(i0, o0, i1, o1, i1, o0);
                    }
                }
            }
        }

        for (const auto& buf : tlsTris) {
            for (const auto& rt : buf) {
                std::array<uint32_t, 3> tri;
                for (int k = 0; k < 3; ++k) {
                    auto it = edgeVertMap.find(rt.e[k]);
                    if (it == edgeVertMap.end()) {
                        uint32_t idx = (uint32_t)mesh.verts.size();
                        edgeVertMap.emplace(rt.e[k], idx);
                        mesh.verts.push_back(rt.v[k]);
                        tri[k] = idx;
                    } else {
                        tri[k] = it->second;
                    }
                }
                if (tri[0] != tri[1] && tri[1] != tri[2] && tri[2] != tri[0]) {
                    mesh.tris.push_back(tri);
                }
            }
        }

        if ((iz & 15) == 15) {
            uint64_t minKeepNode = gridNodeId(0, 0, iz + 1);
            for (auto it = edgeVertMap.begin(); it != edgeVertMap.end(); ) {
                if (it->first.b < minKeepNode) it = edgeVertMap.erase(it);
                else ++it;
            }
        }
        std::swap(sliceA, sliceB);
    }

    std::cout << "Raw strict-manifold MT6 mesh: " << mesh.verts.size() << " verts, " << mesh.tris.size() << " tris\n" << std::flush;
    keepLargestComponent(mesh);
    verifyManifold(mesh, "Post-MT6");

    if (projectToSurface) {
        using CastleSpec::FLAT_FLOORS;
        using CastleSpec::STUD_TOPS;
        #pragma omp parallel for schedule(static)
        for (size_t i = 0; i < mesh.verts.size(); ++i) {
            Vec3& v = mesh.verts[i];
            if (v.z == 0.0f) continue;
            bool onStud = (legoStudsSDF(v, 2.0f) < h * 0.90f);
            int nIter = onStud ? 2 : 1;
            Vec3 n(0, 0, 1);
            for (int it = 0; it < nIter; ++it) {
                float f = castleSDF(v);
                n = calcNormal(v, h * (onStud ? 0.25f : 0.35f));
                if (std::fabs(f) > 1e-4f && std::fabs(f) < h * 0.45f) {
                    Vec3 vn = v - n * (f * (onStud ? 0.58f : 0.65f));
                    if (vn.z > 0.03f) v = vn;
                }
            }
            // Snap interior upward-facing walkable floor vertices onto their exact mathematical Z planes -> 0.000mm slicer flatness!
            // Using wider normal probe (h * 0.90f) avoids snapping wall/stud-base crease vertices into coincident coordinates!
            if (!onStud && n.z > 0.96f && calcNormal(v, h * 0.90f).z > 0.98f) {
                for (float zf : FLAT_FLOORS) {
                    if (std::fabs(v.z - zf) < h * 0.55f) {
                        v.z = zf;
                        break;
                    }
                }
            } else if (onStud && n.z > 0.96f && calcNormal(v, h * 0.55f).z > 0.98f) {
                for (float zt : STUD_TOPS) {
                    if (std::fabs(v.z - zt) < h * 0.45f) {
                        v.z = zt;
                        break;
                    }
                }
            }
        }
    }
    return mesh;
}

// ============================================================================
// Manifold-Preserving Garland-Heckbert QEM Mesh Simplification (O(1) valence cap)
// ============================================================================
struct Quadric {
    double a[10];
    Quadric() { std::memset(a, 0, sizeof(a)); }
    void addPlane(double nx, double ny, double nz, double d) {
        a[0] += nx * nx; a[1] += nx * ny; a[2] += nx * nz; a[3] += nx * d;
        a[4] += ny * ny; a[5] += ny * nz; a[6] += ny * d;
        a[7] += nz * nz; a[8] += nz * d;
        a[9] += d * d;
    }
    Quadric operator+(const Quadric& o) const {
        Quadric r;
        for (int i = 0; i < 10; ++i) r.a[i] = a[i] + o.a[i];
        return r;
    }
    double eval(double x, double y, double z) const {
        return a[0]*x*x + 2*a[1]*x*y + 2*a[2]*x*z + 2*a[3]*x
             + a[4]*y*y + 2*a[5]*y*z + 2*a[6]*y
             + a[7]*z*z + 2*a[8]*z + a[9];
    }
    bool solve(Vec3& out) const {
        double m00 = a[0], m01 = a[1], m02 = a[2];
        double m11 = a[4], m12 = a[5], m22 = a[7];
        double det = m00 * (m11 * m22 - m12 * m12)
                   - m01 * (m01 * m22 - m12 * m02)
                   + m02 * (m01 * m12 - m11 * m02);
        if (std::fabs(det) < 1e-12) return false;
        double inv = 1.0 / det;
        double b0 = -a[3], b1 = -a[6], b2 = -a[8];
        double c00 = m11 * m22 - m12 * m12;
        double c01 = m02 * m12 - m01 * m22;
        double c02 = m01 * m12 - m02 * m11;
        double c11 = m00 * m22 - m02 * m02;
        double c12 = m02 * m01 - m00 * m12;
        double c22 = m00 * m11 - m01 * m01;
        out.x = float((c00 * b0 + c01 * b1 + c02 * b2) * inv);
        out.y = float((c01 * b0 + c11 * b1 + c12 * b2) * inv);
        out.z = float((c02 * b0 + c12 * b1 + c22 * b2) * inv);
        return true;
    }
};

void simplifyManifoldQEM(Mesh& mesh, size_t targetTris, double maxError = 0.08) {
    size_t nV = mesh.verts.size();
    size_t nT = mesh.tris.size();
    if (nT <= targetTris) return;

    std::cout << "Running manifold-preserving QEM simplification (" << nT << " -> " << targetTris << " tris)...\n" << std::flush;

    std::vector<Quadric> Q(nV);
    std::vector<uint8_t> vDeleted(nV, 0);
    std::vector<uint8_t> tDeleted(nT, 0);
    std::vector<uint32_t> vVer(nV, 0);
    std::vector<std::vector<uint32_t>> vTris(nV);

    // Protect precision LEGO stud cylinders with 25x quadric weight so QEM keeps exact 4.70mm roundness!
    std::vector<uint8_t> vIsStud(nV, 0);
    #pragma omp parallel for schedule(static)
    for (size_t i = 0; i < nV; ++i) {
        if (legoStudsSDF(mesh.verts[i], 1.0f) < 0.45f) vIsStud[i] = 1;
    }

    for (uint32_t ti = 0; ti < nT; ++ti) {
        const auto& t = mesh.tris[ti];
        vTris[t[0]].push_back(ti);
        vTris[t[1]].push_back(ti);
        vTris[t[2]].push_back(ti);
        Vec3 p0 = mesh.verts[t[0]], p1 = mesh.verts[t[1]], p2 = mesh.verts[t[2]];
        Vec3 n = cross(p1 - p0, p2 - p0);
        double len = std::sqrt(double(n.x)*n.x + double(n.y)*n.y + double(n.z)*n.z);
        if (len > 1e-12) {
            double w = (vIsStud[t[0]] || vIsStud[t[1]] || vIsStud[t[2]]) ? 5.0 : 1.0;
            double nx = (n.x / len) * w, ny = (n.y / len) * w, nz = (n.z / len) * w;
            double d = -(nx * p0.x + ny * p0.y + nz * p0.z);
            Q[t[0]].addPlane(nx, ny, nz, d);
            Q[t[1]].addPlane(nx, ny, nz, d);
            Q[t[2]].addPlane(nx, ny, nz, d);
        }
    }

    for (size_t i = 0; i < nV; ++i) {
        if (mesh.verts[i].z == 0.0f) Q[i].addPlane(0.0, 0.0, 10.0, 0.0);
    }

    struct CollapseItem {
        double cost;
        uint32_t u, v;
        uint32_t verU, verV;
        Vec3 pos;
        bool operator>(const CollapseItem& o) const { return cost > o.cost; }
    };

    auto evalEdge = [&](uint32_t u, uint32_t v, Vec3& bestP) -> double {
        Quadric q = Q[u] + Q[v];
        Vec3 pu = mesh.verts[u], pv = mesh.verts[v], pm = (pu + pv) * 0.5f;
        Vec3 diff = pu - pv;
        double lenTie = 1e-6 * double(dot(diff, diff));
        Vec3 cand;
        bool bothBase = (pu.z == 0.0f && pv.z == 0.0f);
        bool oneBase = (pu.z == 0.0f) != (pv.z == 0.0f);
        if (oneBase) {
            bestP = (pu.z == 0.0f) ? pu : pv;
            return std::max(0.0, q.eval(bestP.x, bestP.y, bestP.z)) + 0.002 + lenTie;
        }
        if (q.solve(cand) && length(cand - pm) < length(diff) * 1.15f) {
            if (bothBase) cand.z = 0.0f;
            bestP = cand;
            return std::max(0.0, q.eval(cand.x, cand.y, cand.z)) + lenTie;
        }
        double eu = q.eval(pu.x, pu.y, pu.z);
        double ev = q.eval(pv.x, pv.y, pv.z);
        double em = q.eval(pm.x, pm.y, pm.z);
        if (em <= eu && em <= ev) { bestP = pm; if (bothBase) bestP.z = 0.0f; return std::max(0.0, em) + lenTie; }
        if (eu <= ev) { bestP = pu; return std::max(0.0, eu) + lenTie; }
        bestP = pv; return std::max(0.0, ev) + lenTie;
    };

    std::priority_queue<CollapseItem, std::vector<CollapseItem>, std::greater<CollapseItem>> pq;
    for (uint32_t ti = 0; ti < nT; ++ti) {
        const auto& t = mesh.tris[ti];
        for (int k = 0; k < 3; ++k) {
            uint32_t u = t[k], v = t[(k + 1) % 3];
            if (u < v) {
                Vec3 bp;
                double c = evalEdge(u, v, bp);
                if (c <= maxError) pq.push({c, u, v, 0, 0, bp});
            }
        }
    }

    size_t curTris = nT;
    std::vector<uint32_t> nU, nVlist;
    nU.reserve(32); nVlist.reserve(32);

    while (!pq.empty() && curTris > targetTris) {
        CollapseItem it = pq.top();
        pq.pop();
        if (it.cost > maxError) break;
        uint32_t u = it.u, v = it.v;
        if (vDeleted[u] || vDeleted[v] || vVer[u] != it.verU || vVer[v] != it.verV) continue;
        if (vTris[u].size() + vTris[v].size() > 22) continue;

        nU.clear(); nVlist.clear();
        int sharedTris = 0;
        for (uint32_t ti : vTris[u]) {
            if (tDeleted[ti]) continue;
            const auto& t = mesh.tris[ti];
            if (t[0] == v || t[1] == v || t[2] == v) sharedTris++;
            for (int k = 0; k < 3; ++k) if (t[k] != u && t[k] != v) nU.push_back(t[k]);
        }
        if (sharedTris != 2) continue;

        for (uint32_t ti : vTris[v]) {
            if (tDeleted[ti]) continue;
            const auto& t = mesh.tris[ti];
            for (int k = 0; k < 3; ++k) if (t[k] != u && t[k] != v) nVlist.push_back(t[k]);
        }
        std::sort(nU.begin(), nU.end());
        nU.erase(std::unique(nU.begin(), nU.end()), nU.end());
        std::sort(nVlist.begin(), nVlist.end());
        nVlist.erase(std::unique(nVlist.begin(), nVlist.end()), nVlist.end());

        int commonNeighbors = 0;
        size_t i = 0, j = 0;
        while (i < nU.size() && j < nVlist.size()) {
            if (nU[i] == nVlist[j]) { commonNeighbors++; i++; j++; }
            else if (nU[i] < nVlist[j]) i++;
            else j++;
        }
        if (commonNeighbors != 2) continue;

        bool flip = false;
        auto checkFlip = [&](uint32_t vert) {
            for (uint32_t ti : vTris[vert]) {
                if (tDeleted[ti]) continue;
                const auto& t = mesh.tris[ti];
                if ((t[0] == u || t[1] == u || t[2] == u) && (t[0] == v || t[1] == v || t[2] == v)) continue;
                Vec3 a = mesh.verts[t[0]], b = mesh.verts[t[1]], c = mesh.verts[t[2]];
                Vec3 oldN = cross(b - a, c - a);
                Vec3 na = (t[0] == u || t[0] == v) ? it.pos : a;
                Vec3 nb = (t[1] == u || t[1] == v) ? it.pos : b;
                Vec3 nc = (t[2] == u || t[2] == v) ? it.pos : c;
                Vec3 newN = cross(nb - na, nc - na);
                float oldL = length(oldN), newL = length(newN);
                if (newL < 1e-7f || (oldL > 1e-7f && dot(oldN, newN) < 0.25f * oldL * newL)) {
                    flip = true; return;
                }
            }
        };
        checkFlip(u);
        if (!flip) checkFlip(v);
        if (flip) continue;

        mesh.verts[u] = it.pos;
        Q[u] = Q[u] + Q[v];
        vDeleted[v] = 1;
        vVer[u]++;

        for (uint32_t ti : vTris[v]) {
            if (tDeleted[ti]) continue;
            auto& t = mesh.tris[ti];
            if (t[0] == u || t[1] == u || t[2] == u) {
                tDeleted[ti] = 1; curTris--;
            } else {
                for (int k = 0; k < 3; ++k) if (t[k] == v) t[k] = u;
                vTris[u].push_back(ti);
            }
        }
        vTris[v].clear();

        size_t w = 0;
        for (size_t k = 0; k < vTris[u].size(); ++k) {
            if (!tDeleted[vTris[u][k]]) vTris[u][w++] = vTris[u][k];
        }
        vTris[u].resize(w);

        nU.clear();
        for (uint32_t ti : vTris[u]) {
            const auto& t = mesh.tris[ti];
            for (int k = 0; k < 3; ++k) if (t[k] != u) nU.push_back(t[k]);
        }
        std::sort(nU.begin(), nU.end());
        nU.erase(std::unique(nU.begin(), nU.end()), nU.end());
        for (uint32_t nb : nU) {
            if (vDeleted[nb]) continue;
            Vec3 bp;
            double c = evalEdge(u, nb, bp);
            if (c <= maxError) pq.push({c, u, nb, vVer[u], vVer[nb], bp});
        }
    }

    std::vector<uint32_t> remap(nV, UINT32_MAX);
    std::vector<Vec3> newVerts; newVerts.reserve(nV);
    std::vector<std::array<uint32_t, 3>> newTris; newTris.reserve(curTris);

    for (size_t ti = 0; ti < nT; ++ti) {
        if (tDeleted[ti]) continue;
        auto t = mesh.tris[ti];
        for (int k = 0; k < 3; ++k) {
            if (remap[t[k]] == UINT32_MAX) {
                remap[t[k]] = (uint32_t)newVerts.size();
                newVerts.push_back(mesh.verts[t[k]]);
            }
            t[k] = remap[t[k]];
        }
        if (t[0] != t[1] && t[1] != t[2] && t[2] != t[0]) newTris.push_back(t);
    }
    mesh.verts.swap(newVerts);
    mesh.tris.swap(newTris);
    std::cout << "Simplified mesh: " << mesh.verts.size() << " verts, " << mesh.tris.size() << " tris\n" << std::flush;
}

void writeBinarySTL(const std::string& filename, const Mesh& mesh) {
    std::ofstream out(filename, std::ios::binary);
    char header[80];
    std::memset(header, 0, sizeof(header));
    std::snprintf(header, sizeof(header), "Ironcrest Keep v7 290x290x215mm Open-Back Sculpted FDM Playset");
    out.write(header, 80);
    uint32_t nT = (uint32_t)mesh.tris.size();
    out.write(reinterpret_cast<const char*>(&nT), 4);

    std::vector<uint8_t> buf(size_t(nT) * 50);
    #pragma omp parallel for schedule(static)
    for (size_t i = 0; i < nT; ++i) {
        const auto& t = mesh.tris[i];
        Vec3 a = mesh.verts[t[0]], b = mesh.verts[t[1]], c = mesh.verts[t[2]];
        Vec3 n = normalize(cross(b - a, c - a));
        uint8_t* ptr = buf.data() + i * 50;
        float data[12] = {n.x, n.y, n.z, a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z};
        std::memcpy(ptr, data, 48);
        ptr[48] = 0; ptr[49] = 0;
    }
    out.write(reinterpret_cast<const char*>(buf.data()), buf.size());
    std::cout << "Wrote " << filename << " (" << (buf.size() + 84) / (1024.0 * 1024.0) << " MB, " << nT << " triangles)\n" << std::flush;
}

int main(int argc, char** argv) {
    std::string mode = (argc > 1) ? argv[1] : "preview";
    std::string outDir = (argc > 2) ? argv[2] : ".";

    if (mode == "render" || mode == "preview") {
        int W = (mode == "preview") ? 1000 : 1280;
        int H = (mode == "preview") ?  820 : 1024;
        std::cout << "Rendering multi-angle studio previews (" << W << "x" << H << ")...\n" << std::flush;
        renderView(outDir + "/view_hero_front_iso.ppm", W, H, {-295, -335, 245}, {0, 10,  95}, 42.0f);
        // Rear isometric & direct open-back interior views lit from rear-top so both interior levels shine
        renderView(outDir + "/view_rear_iso.ppm",       W, H, { 280,  345, 225}, {0, 20,  95}, 42.0f, { 0.45f,  0.65f, 0.60f});
        renderView(outDir + "/view_rear_interior.ppm",  W, H, {  28,  345, 130}, {0, 65, 108}, 42.0f, { 0.35f,  0.72f, 0.58f});
        renderView(outDir + "/view_front_elev.ppm",     W, H, {   0, -445, 118}, {0,  0, 105}, 38.0f);
        renderView(outDir + "/view_top_courtyard.ppm",  W, H, {   0, -105, 470}, {0,  5,  35}, 42.0f);
        renderView(outDir + "/view_gate_closeup.ppm",   W, H, { -45, -225,  68}, {0, -110, 54}, 40.0f);
        std::cout << "Done rendering previews!\n";
    }

    if (mode == "mesh" || mode == "final") {
        float h = (argc > 3) ? std::stof(argv[3]) : 0.421f;
        size_t targetTris = (argc > 4) ? (size_t)std::stoull(argv[4]) : 2000000ULL;
        std::string stlPath = outDir + "/medieval_castle_290x215.stl";

        double t0 = omp_get_wtime();
        Mesh m = extractWatertightMesh(h, true);
        double t1 = omp_get_wtime();
        std::cout << "Extraction time: " << (t1 - t0) << " s\n" << std::flush;

        if (targetTris > 0 && m.tris.size() > targetTris) {
            simplifyManifoldQEM(m, targetTris, 0.08);
            double t2 = omp_get_wtime();
            std::cout << "QEM simplification time: " << (t2 - t1) << " s\n" << std::flush;
            verifyManifold(m, "Post-QEM");
        }

        Vec3 bmin(1e9f, 1e9f, 1e9f), bmax(-1e9f, -1e9f, -1e9f);
        size_t baseVerts = 0;
        for (const auto& v : m.verts) {
            bmin.x = std::min(bmin.x, v.x); bmax.x = std::max(bmax.x, v.x);
            bmin.y = std::min(bmin.y, v.y); bmax.y = std::max(bmax.y, v.y);
            bmin.z = std::min(bmin.z, v.z); bmax.z = std::max(bmax.z, v.z);
            if (v.z == 0.0f) baseVerts++;
        }
        std::cout << "BBox X: [" << bmin.x << ", " << bmax.x << "] span=" << (bmax.x - bmin.x) << " mm\n";
        std::cout << "BBox Y: [" << bmin.y << ", " << bmax.y << "] span=" << (bmax.y - bmin.y) << " mm\n";
        std::cout << "BBox Z: [" << bmin.z << ", " << bmax.z << "] span=" << (bmax.z - bmin.z) << " mm\n";
        std::cout << "Flat z=0.000 base vertices: " << baseVerts << "\n";

        writeBinarySTL(stlPath, m);
    }
    return 0;
}
