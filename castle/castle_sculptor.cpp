// castle_sculptor.cpp
// High-resolution procedural 3D Signed Distance Field (SDF) medieval castle sculptor — v3
// "Ironcrest Keep" — 290mm x 290mm flat base, 220mm flat-topped open-back keep anchored at rear wall,
// 20mm smooth courtyard, 80mm/94mm walls & flush gatehouse, full-width rear-anchored stairs,
// open turret parapet stair passages, smooth walkable floors, open-back 3-level keep with pass-through windows.
//
// Compile: g++ -O3 -march=native -fopenmp -std=c++17 castle_sculptor.cpp -o castle_sculptor

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

    // Shaft extends +0.5mm into crown base for solid overlap with zero exterior lip
    float d_shaft  = sdCylinderZ(p, cx, cy, R, -4.0f, z_deck + 0.5f, 0.7f);
    float d_plinth = sdConeFrustumZ(p, cx, cy, -4.0f, z_plinth_top, R + 5.0f, R);
    float d_body   = smin(d_shaft, d_plinth, 1.4f);

    float R_crown  = R + 3.0f;
    float d_corbel = sdConeFrustumZ(p, cx, cy, z_deck - 7.5f, z_deck - 1.5f, R - 0.5f, R_crown);
    float d_top    = sdCylinderZ(p, cx, cy, R_crown, z_deck - 1.5f, z_deck + parapet_h, 0.65f);

    float corbEnv = smoothstep(z_deck - 8.2f, z_deck - 5.2f, p.z) * smoothstep(z_deck - 1.2f, z_deck - 2.6f, p.z)
                  * smoothstep(R - 2.0f, R, r) * smoothstep(R_crown + 2.0f, R_crown - 0.5f, r);
    if (corbEnv > 0.001f) {
        float cAng = std::fmod(ang + TAU * 2.0f, TAU / 20.0f);
        float cDist = std::fabs(cAng - 0.5f * TAU / 20.0f) * R;
        d_corbel -= 0.90f * smoothstep(2.3f, 1.3f, cDist) * corbEnv;
    }

    d_body = smin(d_body, smin(d_corbel, d_top, 0.5f), 0.65f);

    // Subtle dressed stone belt course halfway up
    float z_belt = 0.5f * (z_plinth_top + z_deck - 8.0f);
    if (std::fabs(p.z - z_belt) < 4.0f) {
        float d_b1 = sdConeFrustumZ(p, cx, cy, z_belt - 1.8f, z_belt, R - 0.2f, R + 1.1f);
        float d_b2 = sdConeFrustumZ(p, cx, cy, z_belt, z_belt + 1.4f, R + 1.1f, R - 0.2f);
        d_body = smin(d_body, std::min(d_b1, d_b2), 0.4f);
    }

    // Hollow SMOOTH FLAT walkable circular deck
    float R_inner = R_crown - 7.4f;
    float d_deck_cut = sdCylinderZ(p, cx, cy, R_inner, z_deck, z_deck + parapet_h + 10.0f, 0.55f);
    d_body = smax(d_body, -d_deck_cut, 0.5f);

    // Explicit radial stair-access opening + exact sliver-free merlon subdivision of the remaining parapet arc!
    // Parapet arc starts at gapAng1Deg and wraps CCW to (gapAng0Deg + 360), ending cleanly on full chunky merlons!
    if (p.z > z_deck - 2.0f) {
        float angDeg = ang * (180.0f / PI);
        float gapSpan = gapAng1Deg - gapAng0Deg; // e.g. 110 deg (front) or 46 deg (rear)
        float parapetSpan = 360.0f - gapSpan;

        // Relative angle from start of stair gap, in [0, 360)
        float relFromGap = std::fmod(angDeg - gapAng0Deg + 720.0f, 360.0f);
        float radScale = std::max(r, R_inner) * (PI / 180.0f); // mm per degree

        // 1. Cut clean full-height radial stairway opening down to exact z_deck!
        float distIntoGapDeg = std::min(relFromGap, gapSpan - relFromGap); // >0 inside gap, <0 outside gap
        // Signed distance to gap (negative inside gap)
        float d_gap_ang = (relFromGap <= gapSpan) ? -distIntoGapDeg * radScale
                                                  : std::min(relFromGap - gapSpan, 360.0f - relFromGap) * radScale;
        float d_gap_z = z_deck - p.z;
        float d_gap_r = std::max((R_inner - 2.5f) - r, r - (R_crown + 3.5f));
        float d_gap = std::max(std::max(d_gap_ang, d_gap_z), d_gap_r);
        d_body = smax(d_body, -(d_gap - 0.50f), 0.55f);

        // 2. Cut (num_merlons - 1) evenly spaced embrasures strictly INSIDE the parapet arc
        //    so EVERY merlon (including both end merlons bordering the stair gap!) has full chunky width (~10-12mm)!
        float z_emb = z_deck + parapet_h * 0.48f;
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
        float wallMask = smoothstep(0.0f, 1.5f, std::fabs(p.z - z_deck))
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
// Master Castle Signed Distance Field — v3
// Exact envelope: X in [-145, 145] (290mm), Y in [-145, 145] (290mm), Z in [0, 220] (220mm)
// - Courtyard floor: z = 20.0 mm (smooth flat, -20mm from v2)
// - Curtain wall & thickened flush gatehouse: deck z = 80.0 mm, parapet z = 94.0 mm (-20mm from v2)
// - Corner towers: Front deck z = 94.0 mm (para 108), Rear deck z = 102.0 mm (para 116)
//   with open stair-access gaps cut cleanly through parapet crenellations!
// - Full-width stairs (|x| in [52, 93]) filling the gaps beside the Keep & touching rear wall (y = 18..93)
// - Single flat-topped Keep lowered 30mm (roof deck z = 204.0 mm, merlons z = 220.0 mm)
// - Open-back Keep exposing 3 playable smooth-floored stories with pass-through Gothic lancet windows!
// ============================================================================
inline float castleSDF(const Vec3& p) {
    static constexpr float Z_COURT     = 20.0f;
    static constexpr float Z_WALL_DECK = 80.0f;
    static constexpr float Z_WALL_PARA = 94.0f;

    static constexpr float Z_TWR_F_DECK = 94.0f;
    static constexpr float Z_TWR_R_DECK = 102.0f;

    static constexpr float Z_KEEP_DECK = 204.0f;
    static constexpr float Z_KEEP_PARA = 220.0f;

    // Keep interior playable level heights (smooth flat floors, generous ~51mm clear headroom!)
    static constexpr float Z_L1_FLOOR = 28.0f;  // Level 1 Great Hall (z = 28 .. 79)
    static constexpr float Z_L2_FLOOR = 86.0f;  // Level 2 Mid Chamber (z = 86 .. 137)
    static constexpr float Z_L3_FLOOR = 144.0f; // Level 3 Upper Chamber (z = 144 .. 196)

    // ------------------------------------------------------------------------
    // 1. WIDE FLAT-BASED ROCKY PLINTH (Exact 290 x 290 mm at z=0, rising to smooth courtyard z=20mm)
    // ------------------------------------------------------------------------
    float d = 1e9f;
    {
        float t = clampf(p.z / Z_COURT, 0.0f, 1.0f);
        float halfW = lerpf(144.8f, 127.8f, t);
        float rad = lerpf(28.0f, 22.0f, t);

        float qx = std::fabs(p.x) - (halfW - rad);
        float qy = std::fabs(p.y) - (halfW - rad);
        float d2 = std::hypot(std::max(qx, 0.0f), std::max(qy, 0.0f)) + std::min(std::max(qx, qy), 0.0f) - rad;

        float ang = std::atan2(p.y, p.x);
        float causewayClear = (1.0f - smoothstep(20.0f, 36.0f, std::fabs(p.x))) * smoothstep(-95.0f, -118.0f, p.y);
        float rockMask = (1.0f - causewayClear) * smoothstep(Z_COURT + 0.2f, Z_COURT - 2.8f, p.z);
        float rockLobe = (1.1f * std::sin(ang * 7.0f + 0.5f)
                        + 0.75f * std::cos(ang * 13.0f - 0.8f)
                        + 0.45f * std::sin(ang * 21.0f)) * rockMask;
        d2 -= rockLobe * 0.65f;

        float d_side = d2 * 0.74f;
        float d_top = p.z - Z_COURT; // COMPLETELY SMOOTH flat courtyard floor!
        float d_base = std::max(d_side, d_top);
        if (d_side > 0.0f && d_top > 0.0f) d_base = std::hypot(d_side, d_top);

        if (std::fabs(d_base) < 5.0f && rockMask > 0.001f && p.z > -1.0f) {
            d_base -= bedrockDisplacement(p) * rockMask * 0.78f;
        }
        d = d_base;
    }

    // ------------------------------------------------------------------------
    // 2. FRONT STEPPED STONE CAUSEWAY (y = -145 to -126, climbing z = 0 -> 20 mm)
    // ------------------------------------------------------------------------
    {
        float d_b = sdBoxMinMax(p, -26.0f, 26.0f, -146.0f, -118.0f, -2.0f, Z_COURT + 8.0f);
        if (d_b < d + 3.0f) {
            float yStart = -144.8f;
            float yEnd   = -126.5f;
            int nSteps   = 4;
            float stepRun  = (yEnd - yStart) / float(nSteps);
            float stepRise = (Z_COURT - 2.0f) / float(nSteps);

            float d_steps = 1e9f;
            for (int s = 0; s < nSteps; ++s) {
                float sy0 = yStart + s * stepRun;
                float sz1 = 2.0f + (s + 1) * stepRise;
                float sb = sdBoxMinMax(p, -20.5f, 20.5f, sy0, -120.0f, -2.0f, sz1, 0.35f);
                d_steps = std::min(d_steps, sb);
            }
            // Flanking stone curbs
            float ty = clampf((p.y - yStart) / (yEnd - yStart), 0.0f, 1.0f);
            float z_curb = lerpf(5.5f, Z_COURT + 4.5f, ty);
            float dz_c = (p.z - z_curb) * 0.72f;
            float dx_c = std::fabs(std::fabs(p.x) - 21.8f) - 2.6f;
            float dy_c = std::max(-144.2f - p.y, p.y - (-124.0f));
            float cx = std::max(dx_c, 0.0f), cy = std::max(dy_c, 0.0f), cz = std::max(dz_c, 0.0f);
            float d_curb = std::sqrt(cx*cx + cy*cy + cz*cz) + std::min(std::max(dx_c, std::max(dy_c, dz_c)), 0.0f) - 0.45f;

            float d_ramp = smin(d_steps, d_curb, 0.5f);
            if (std::fabs(d_ramp) < 2.0f && std::fabs(p.x) > 22.8f && p.z > 2.0f) {
                d_ramp -= ashlarDisplacement(p.y + 150.0f, p.z, 4.4f, 8.2f, 0.40f, 0.24f, 88)
                        * smoothstep(22.5f, 24.0f, std::fabs(p.x));
            }
            d = smin(d, d_ramp, 0.65f);
        }
    }

    // ------------------------------------------------------------------------
    // 3. OUTER CURTAIN WALLS (outer ±121mm, inner ±93mm, SMOOTH deck z=80mm, para z=94mm)
    // ------------------------------------------------------------------------
    {
        float d_wb = sdBoxMinMax(p, -129.0f, 129.0f, -129.0f, 129.0f, -4.0f, Z_WALL_PARA + 3.0f);
        if (d_wb < d + 3.5f) {
            float ax = std::fabs(p.x);
            float ay = std::fabs(p.y);
            float maxXY = std::max(ax, ay);

            float d_out_main = sdBatteredBox(p, 0, 0, -4.0f, Z_COURT + 14.0f, 127.0f, 127.0f, 121.0f, 121.0f, 0.9f);
            float d_out_up   = sdBoxMinMax(p, -121.0f, 121.0f, -121.0f, 121.0f, Z_COURT + 10.0f, Z_WALL_DECK + 0.5f, 0.8f);
            float d_out_corb = sdBatteredBox(p, 0, 0, Z_WALL_DECK - 7.8f, Z_WALL_DECK - 1.5f,
                                             120.5f, 120.5f, 124.0f, 124.0f, 0.65f);
            float d_out_para = sdBoxMinMax(p, -124.0f, 124.0f, -124.0f, 124.0f,
                                           Z_WALL_DECK - 1.5f, Z_WALL_PARA, 0.65f);

            float d_outer = smin(std::min(d_out_main, d_out_up), smin(d_out_corb, d_out_para, 0.5f), 0.65f);
            // Cut all the way below Z_COURT so d_walls never overlaps d_base's glass-smooth courtyard floor!
            float d_court_cut = sdBoxMinMax(p, -93.0f, 93.0f, -93.0f, 93.0f, -8.0f, 120.0f, 0.9f);
            float d_walk_cut  = sdBoxMinMax(p, -116.4f, 116.4f, -116.4f, 116.4f, Z_WALL_DECK, 120.0f, 0.55f);

            float d_walls = smax(d_outer, -std::min(d_court_cut, d_walk_cut), 0.55f);

            // Corbel brackets under exterior overhang
            float corbM = smoothstep(Z_WALL_DECK - 8.0f, Z_WALL_DECK - 5.2f, p.z)
                        * smoothstep(Z_WALL_DECK - 1.4f, Z_WALL_DECK - 3.0f, p.z)
                        * smoothstep(118.5f, 121.0f, maxXY) * smoothstep(126.0f, 123.5f, maxXY);
            if (corbM > 0.001f) {
                float u = (ax > ay) ? p.y : p.x;
                float uf = std::fabs(std::fmod(u + 300.0f, 10.5f) - 5.25f);
                d_walls -= 0.72f * smoothstep(2.4f, 1.3f, uf) * corbM;
            }

            // Explicit sliver-free crenellation embrasures along all outer curtain walls!
            // Guarantees every merlon is >= 11mm wide (7.5mm thick) with zero narrow slivers at junctions.
            if (p.z > Z_WALL_DECK + 5.0f && maxXY > 113.0f) {
                float d_emb_u = 1e6f;
                if (ax > ay) {
                    // Left & Right side walls (clear span y in [-79.5, +79.0]):
                    // 6 evenly spaced embrasures at y = ±12.5, ±37.5, ±62.5 (width 10.5mm -> merlons 14.5mm, end merlons ~11.5mm!)
                    float yAbs = std::fabs(p.y);
                    float d1 = std::fabs(yAbs - 12.5f) - 5.25f;
                    float d2 = std::fabs(yAbs - 37.5f) - 5.25f;
                    float d3 = std::fabs(yAbs - 62.5f) - 5.25f;
                    d_emb_u = std::min(d1, std::min(d2, d3));
                } else if (p.y < 0.0f) {
                    // Front wall flanking the gatehouse (clear span |x| in [40.5, 79.5]):
                    // Embrasure at |x| = 46.0 ([40.5, 51.5]) and |x| = 74.0 ([68.5, 79.5]) -> chunky 17mm merlon in between!
                    float d1 = std::fabs(ax - 46.0f) - 5.5f;
                    float d2 = std::fabs(ax - 74.0f) - 5.5f;
                    d_emb_u = std::min(d1, d2);
                } else {
                    // Rear wall flanking the Keep (clear span |x| in [55.5, 79.0]):
                    // Single crisp centered embrasure at |x| = 67.25 (width 9.0mm -> sturdy 7.2mm shoulders fused into Keep & Tower!)
                    d_emb_u = std::fabs(ax - 67.25f) - 4.5f;
                }
                float d_emb = std::max(d_emb_u, (Z_WALL_DECK + 7.2f) - p.z);
                d_walls = smax(d_walls, -(d_emb - 0.55f), 0.55f);
            }

            // Exterior arrow slits along curtain walls (z = 40..58)
            float slitProtect = 1.0f;
            if (p.z > 35.0f && p.z < 64.0f && maxXY > 114.0f) {
                float u = (ax > ay) ? p.y : p.x;
                bool skipFrontGate = (p.y < -95.0f && std::fabs(p.x) < 42.0f);
                bool skipRearKeep  = (p.y >  95.0f && std::fabs(p.x) < 56.0f);
                if (!skipFrontGate && !skipRearKeep && std::fabs(u) < 76.0f) {
                    float uf = std::fmod(u + 306.0f, 36.0f) - 18.0f;
                    float d_s2 = sdGothicArch2D(uf, p.z, 1.55f, 40.0f, 54.0f, 58.0f);
                    float d_depth = (121.0f - 3.6f) - maxXY;
                    float d_sill = (40.0f + (121.0f - maxXY) * 0.9f) - p.z;
                    float d_slit = std::max(std::max(d_s2, d_depth), d_sill);
                    float d_cross = std::max(std::max(std::fabs(uf) - 3.4f, std::fabs(p.z - 49.5f) - 1.05f), d_depth + 0.7f);
                    float d_cut = std::min(d_slit, d_cross);
                    d_walls = smax(d_walls, -(d_cut - 0.22f), 0.30f);
                    slitProtect = smoothstep(-0.4f, 1.8f, d_cut);
                }
            }

            // Fine ashlar stone masonry on vertical wall faces ONLY (walltop & courtyard floors stay glass-smooth!)
            if (std::fabs(d_walls) < 2.5f && maxXY > 91.0f) {
                float u = (ax > ay) ? p.y : p.x;
                int faceSeed = (ax > ay) ? (p.x > 0 ? 11 : 17) : (p.y > 0 ? 23 : 29);
                float walkMask = smoothstep(0.0f, 1.5f, std::fabs(p.z - Z_WALL_DECK))
                               * smoothstep(0.0f, 1.2f, Z_WALL_PARA - p.z)
                               * smoothstep(Z_COURT - 2.0f, Z_COURT + 2.5f, p.z);
                float floorMask = (maxXY < 116.6f && maxXY > 92.5f) ? smoothstep(1.8f, 0.2f, std::fabs(p.z - Z_WALL_DECK)) : 0.0f;

                if (walkMask > 0.001f && floorMask < 0.85f) {
                    float disp = ashlarDisplacement(u + 150.0f, p.z, 4.6f, 9.0f, 0.50f, 0.32f, faceSeed);
                    d_walls -= disp * walkMask * slitProtect;
                }
            }
            d = smin(d, d_walls, 0.8f);
        }
    }

    // ------------------------------------------------------------------------
    // 4. FOUR CORNER BASTION TOWERS + CONTINUOUS STAIR PATHS & SLIVER-FREE PARAPETS!
    //    Front Towers: open stair arc [-10 deg, +100 deg] (110 deg), 7 full chunky merlons (~11mm wide!)
    //    Rear Towers:  open stair arc [-102 deg, -56 deg] (46 deg),  9 full chunky merlons (~10.5mm wide!)
    // ------------------------------------------------------------------------
    {
        float tFL = sdCylTower(p, -110.0f, -110.0f, 27.5f, Z_COURT + 14.0f, Z_TWR_F_DECK, 14.0f, false, -10.0f, 100.0f, 7, true, 101, d);
        d = smin(d, tFL, 0.85f);
        float tFR = sdCylTower(p, +110.0f, -110.0f, 27.5f, Z_COURT + 14.0f, Z_TWR_F_DECK, 14.0f, true,  -10.0f, 100.0f, 7, true, 102, d);
        d = smin(d, tFR, 0.85f);
        float tRL = sdCylTower(p, -110.0f, +110.0f, 28.0f, Z_COURT + 16.0f, Z_TWR_R_DECK, 14.5f, false, -102.0f, -56.0f, 9, true, 103, d);
        d = smin(d, tRL, 0.85f);
        float tRR = sdCylTower(p, +110.0f, +110.0f, 28.0f, Z_COURT + 16.0f, Z_TWR_R_DECK, 14.5f, true,  -102.0f, -56.0f, 9, true, 104, d);
        d = smin(d, tRR, 0.85f);

        float ax = std::fabs(p.x);

        // 4a. Side-wall stairs climbing from wall walk (z=80) -> Front Corner Towers (z=94): 3 steps
        float d_sbF = sdBoxMinMax(Vec3(ax, p.y, p.z), 93.0f, 116.0f, -96.0f, -68.0f, 76.0f, 98.0f);
        if (d_sbF < d + 2.5f) {
            float d_st = 1e9f;
            for (int s = 0; s < 3; ++s) {
                float y_hi = -72.0f - s * 6.0f;
                float z_hi = 84.7f + s * 4.65f;
                d_st = std::min(d_st, sdBoxMinMax(Vec3(ax, p.y, p.z), 95.0f, 114.0f, -94.0f, y_hi, 77.0f, z_hi, 0.4f));
            }
            d = smin(d, d_st, 0.4f);
        }

        // 4b. Front-wall stairs climbing from front wall walk (z=80) -> Front Corner Towers (z=94): 3 steps
        float d_sbFront = sdBoxMinMax(Vec3(ax, p.y, p.z), 68.0f, 96.0f, -116.0f, -93.0f, 76.0f, 98.0f);
        if (d_sbFront < d + 2.5f) {
            float d_st = 1e9f;
            for (int s = 0; s < 3; ++s) {
                float x_lo = 72.0f + s * 6.0f;
                float z_hi = 84.7f + s * 4.65f;
                d_st = std::min(d_st, sdBoxMinMax(Vec3(ax, p.y, p.z), x_lo, 94.0f, -114.0f, -95.0f, 77.0f, z_hi, 0.4f));
            }
            d = smin(d, d_st, 0.4f);
        }

        // 4c. Side-wall stairs climbing from wall walk (z=80) -> Rear Corner Towers (z=102): 4 steps
        float d_sbR = sdBoxMinMax(Vec3(ax, p.y, p.z), 93.0f, 116.0f, 58.0f, 96.0f, 76.0f, 106.0f);
        if (d_sbR < d + 2.5f) {
            float d_st = 1e9f;
            for (int s = 0; s < 4; ++s) {
                float y_lo = 60.0f + s * 6.6f;
                float z_hi = 85.5f + s * 5.5f;
                d_st = std::min(d_st, sdBoxMinMax(Vec3(ax, p.y, p.z), 95.0f, 114.0f, y_lo, 94.0f, 77.0f, z_hi, 0.4f));
            }
            d = smin(d, d_st, 0.4f);
        }
    }

    // ------------------------------------------------------------------------
    // 5. THICKENED FLUSH-HEIGHT GATEHOUSE WALL SECTION (NO TURRETS!)
    //    Exact same height as curtain wall (SMOOTH deck z=80mm, parapet z=94mm)!
    // ------------------------------------------------------------------------
    {
        float d_ghb = sdBoxMinMax(p, -44.0f, 44.0f, -135.0f, -82.0f, -4.0f, Z_WALL_PARA + 4.0f);
        if (d_ghb < d + 3.5f) {
            float d_gh_plinth = sdBatteredBox(p, 0.0f, -107.5f, -4.0f, Z_COURT + 14.0f, 41.5f, 23.0f, 38.0f, 20.0f, 0.9f);
            float d_gh_body   = sdBoxMinMax(p, -38.0f, 38.0f, -127.5f, -87.5f, Z_COURT + 10.0f, Z_WALL_DECK + 0.5f, 0.8f);
            float d_gh_corb   = sdBatteredBox(p, 0.0f, -107.5f, Z_WALL_DECK - 7.8f, Z_WALL_DECK - 1.5f,
                                              38.0f, 20.0f, 40.5f, 23.0f, 0.65f);
            float d_gh_top    = sdBoxMinMax(p, -40.5f, 40.5f, -130.5f, -84.5f, Z_WALL_DECK - 1.5f, Z_WALL_PARA, 0.65f);
            float d_pil       = sdBoxMinMax(Vec3(std::fabs(p.x), p.y, p.z), 31.0f, 39.5f, -129.0f, -121.0f,
                                            Z_COURT, Z_WALL_DECK - 6.0f, 0.7f);

            float d_gh = smin(std::min(d_gh_plinth, d_gh_body), std::min(smin(d_gh_corb, d_gh_top, 0.5f), d_pil), 0.65f);

            // Clean corbel brackets under thickened front gatehouse overhang
            float corbM = smoothstep(Z_WALL_DECK - 8.0f, Z_WALL_DECK - 5.2f, p.z)
                        * smoothstep(Z_WALL_DECK - 1.4f, Z_WALL_DECK - 3.0f, p.z)
                        * smoothstep(-126.0f, -128.0f, p.y) * smoothstep(-132.0f, -129.8f, p.y);
            if (corbM > 0.001f && std::fabs(p.x) < 38.5f) {
                float uf = std::fabs(std::fmod(p.x + 200.0f, 9.5f) - 4.75f);
                d_gh -= 0.72f * smoothstep(2.4f, 1.2f, uf) * corbM;
            }

            // Continuous SMOOTH flat walkable battlement deck at z = 80.0 mm
            float d_gh_deck = sdBoxMinMax(p, -44.0f, 44.0f, -122.9f, -82.0f, Z_WALL_DECK, 115.0f, 0.55f);
            d_gh = smax(d_gh, -d_gh_deck, 0.55f);

            // Sliver-free crenellation embrasures along front gatehouse parapet:
            // Only ONE symmetric pair at |x| in [12.5, 22.5] -> leaves a chunky 25mm center merlon (with shield!)
            // and two chunky 18mm corner merlons wrapping solidly around the gatehouse edges (ZERO slivers!).
            if (p.z > Z_WALL_DECK + 5.0f && p.y < -121.0f && std::fabs(p.x) < 34.0f) {
                float ax = std::fabs(p.x);
                float d_e1 = std::max(std::fabs(ax - 17.5f) - 4.75f, (Z_WALL_DECK + 7.2f) - p.z);
                d_gh = smax(d_gh, -(d_e1 - 0.55f), 0.55f);
            }

            // Flanking cruciform arrow slits on gate piers (z = 41..58)
            float ghProtect = 1.0f;
            if (p.z > 38.0f && p.z < 64.0f && p.y < -122.0f && std::fabs(std::fabs(p.x) - 29.0f) < 6.0f) {
                float ux = std::fabs(p.x) - 29.0f;
                float d_s2 = sdGothicArch2D(ux, p.z, 1.45f, 41.0f, 54.0f, 58.0f);
                float d_depth = (-127.5f + 3.4f) + p.y;
                float d_sill = (41.0f + (p.y - (-127.5f)) * 0.9f) - p.z;
                float d_slit = std::max(std::max(d_s2, d_depth), d_sill);
                float d_cross = std::max(std::max(std::fabs(ux) - 3.0f, std::fabs(p.z - 50.0f) - 1.0f), d_depth + 0.6f);
                float d_cut = std::min(d_slit, d_cross);
                d_gh = smax(d_gh, -(d_cut - 0.22f), 0.30f);
                ghProtect = std::min(ghProtect, smoothstep(-0.4f, 1.8f, d_cut));
            }

            // Carved stone Voussoir Arch Ring framing front & rear portals (z = 20..76.5)
            if (p.z > Z_COURT - 1.0f && p.z < 79.0f && std::fabs(p.x) < 27.0f) {
                float d_ao = sdGothicArch2D(p.x, p.z, 23.2f, Z_COURT - 1.0f, 48.0f, 76.5f);
                float d_ai = sdGothicArch2D(p.x, p.z, 19.0f, Z_COURT - 1.0f, 48.0f, 72.0f);
                float d_ring = std::max(d_ao, -d_ai);
                float dyFR = std::min(std::fabs(p.y - (-127.8f)) - 1.6f, std::fabs(p.y - (-87.2f)) - 1.6f);
                float d_vous = std::max(d_ring, dyFR);
                if (std::fabs(d_vous) < 2.2f && p.z > 47.0f) {
                    float va = std::atan2(p.z - 48.0f, p.x);
                    float vf = std::fmod(va + PI, PI / 15.0f);
                    float vg = std::min(vf, PI / 15.0f - vf) * 21.0f;
                    d_vous += 0.42f * (1.0f - smoothstep(0.12f, 0.55f, vg));
                }
                d_gh = smin(d_gh, d_vous, 0.32f);
                ghProtect = std::min(ghProtect, smoothstep(-0.4f, 1.5f, d_vous));
            }

            // Carved medieval heater shield centered on central gate parapet merlon (z = 80..92)
            {
                float sx = std::fabs(p.x);
                float sz = p.z - 86.5f;
                float wAtZ = (sz >= -0.5f) ? 4.8f : lerpf(4.8f, 0.5f, clampf((-0.5f - sz) / 5.5f, 0.0f, 1.0f));
                float d_sh2d = std::max(sx - wAtZ, std::max(sz - 5.2f, -6.0f - sz));
                float d_shield = std::max(d_sh2d, std::fabs(p.y - (-130.6f)) - 1.4f) - 0.35f;
                float d_cr = std::min(std::fabs(p.x) - 0.85f, std::fabs(p.z - 87.2f) - 0.85f);
                float d_sh_cr = std::max(std::max(d_cr, d_sh2d + 1.2f), std::fabs(p.y - (-131.6f)) - 0.8f) - 0.2f;
                d_gh = smin(d_gh, smin(d_shield, d_sh_cr, 0.25f), 0.35f);
                ghProtect = std::min(ghProtect, smoothstep(-0.4f, 1.5f, d_shield));
            }

            // Fine ashlar stone on vertical gatehouse walls ONLY (smooth top deck!)
            if (std::fabs(d_gh) < 2.5f) {
                float floorMask = (p.y > -123.5f && p.y < -85.0f)
                                ? smoothstep(1.8f, 0.2f, std::fabs(p.z - Z_WALL_DECK)) : 0.0f;
                if (floorMask < 0.85f && p.z > Z_COURT - 4.0f) {
                    float disp = ashlarDisplacement(p.x + 100.0f, p.z, 4.6f, 8.8f, 0.50f, 0.32f, 205);
                    float topMask = smoothstep(0.0f, 1.2f, Z_WALL_PARA - p.z)
                                  * smoothstep(0.0f, 1.5f, std::fabs(p.z - Z_WALL_DECK))
                                  * smoothstep(Z_COURT - 4.0f, Z_COURT + 2.0f, p.z);
                    d_gh -= disp * topMask * ghProtect;
                }
            }
            d = smin(d, d_gh, 0.75f);
        }

        // CARVE PASS-THROUGH POINTED GOTHIC GATE TUNNEL (38mm wide x 52mm tall: z=20..72mm, SMOOTH floor!)
        {
            float d_tb = sdBoxMinMax(p, -24.0f, 24.0f, -135.0f, -82.0f, Z_COURT - 2.0f, 76.0f);
            if (d_tb < 4.0f) {
                float d_tunnel = sdGothicTunnelY(p, 0.0f, 19.0f, -134.0f, -83.0f, Z_COURT, 48.0f, 72.0f);
                // Heavy oak doors folded open flush along left & right inner tunnel walls
                float doorMask = smoothstep(15.2f, 17.6f, std::fabs(p.x))
                               * smoothstep(-121.0f, -118.5f, p.y) * smoothstep(-92.0f, -94.5f, p.y)
                               * smoothstep(Z_COURT, Z_COURT + 1.5f, p.z) * smoothstep(51.0f, 48.5f, p.z);
                if (doorMask > 0.001f) {
                    float doorDisp = timberDoorDisplacement(p.y + 121.0f, p.z, Z_COURT);
                    d_tunnel += (1.35f + doorDisp) * doorMask;
                }
                // Gothic stone vault ribs along tunnel ceiling
                if (p.z > 48.0f && p.y > -124.0f && p.y < -91.0f) {
                    float rib = std::min(std::fabs(p.y - (-116.0f)), std::fabs(p.y - (-100.0f)));
                    d_tunnel += 0.9f * (1.0f - smoothstep(1.0f, 2.0f, rib));
                }
                d = smax(d, -d_tunnel, 0.50f);
            }
        }

        // 100% support-free sculpted raised portcullis arch grille tucked cleanly inside the upper Gothic arch
        {
            float d_pb = sdBoxMinMax(p, -20.0f, 20.0f, -126.0f, -119.0f, 52.0f, 74.0f);
            if (d_pb < d + 2.5f) {
                float d_arch_outer = sdGothicArch2D(p.x, p.z, 19.2f, Z_COURT, 48.0f, 72.2f);
                float d_arch_inner = sdGothicArch2D(p.x, p.z, 16.4f, Z_COURT, 48.0f, 67.6f);
                float d_port = std::max(std::max(d_arch_outer, -d_arch_inner), std::fabs(p.y - (-122.5f)) - 1.7f);
                d_port = std::max(d_port, 53.5f - p.z);
                float barF = std::fabs(std::fmod(p.x + 100.0f, 4.8f) - 2.4f);
                float iron = 0.55f * (1.0f - smoothstep(0.65f, 1.15f, barF));
                d_port -= iron * smoothstep(53.5f, 56.0f, p.z);
                d = smin(d, d_port, 0.32f);
            }
        }
    }

    // ------------------------------------------------------------------------
    // 6. FULL-WIDTH REAR-ANCHORED STAIRCASES (z = 20 -> 80 mm!)
    //    Entirely fill the gap between Keep sides (|x|=52) and side walls (|x|=93) -> 41mm WIDE!
    //    Moved all the way back to touch the rear curtain walls (y = +18 .. +93)!
    // ------------------------------------------------------------------------
    {
        float sx = std::fabs(p.x);
        float d_sb = sdBoxMinMax(Vec3(sx, p.y, p.z), 50.0f, 96.0f, 15.0f, 97.0f, Z_COURT - 3.0f, Z_WALL_DECK + 3.0f);
        if (d_sb < d + 3.0f) {
            float y0 = 18.0f;
            float y1 = 93.0f; // lands flush against the rear curtain wall walk (y >= 93, z = 80mm)!
            int numSteps = 10;
            float stepRun  = (y1 - y0) / float(numSteps);            // 7.5 mm deep treads!
            float stepRise = (Z_WALL_DECK - Z_COURT) / float(numSteps); // 6.0 mm rise!

            float d_stair = 1e9f;
            for (int i = 0; i < numSteps; ++i) {
                float sy0 = y0 + i * stepRun;
                float sz1 = Z_COURT + (i + 1) * stepRise;
                float b = sdBoxMinMax(Vec3(sx, p.y, p.z), 51.0f, 94.5f, sy0, 95.5f, Z_COURT - 2.0f, sz1, 0.35f);
                d_stair = std::min(d_stair, b);
            }
            d = smin(d, d_stair, 0.55f);
        }
    }

    // ------------------------------------------------------------------------
    // 7. SCULPTED MEDIEVAL COURTYARD WELL (tucked neatly at x = -54, y = -52, z = 20..33 mm)
    // ------------------------------------------------------------------------
    {
        float d_wb = sdCylinderZ(p, -54.0f, -52.0f, 13.0f, Z_COURT - 2.0f, Z_COURT + 16.0f);
        if (d_wb < d + 2.5f) {
            float wr = std::hypot(p.x + 54.0f, p.y + 52.0f);
            float wang = std::atan2(p.y + 52.0f, p.x + 54.0f);
            float d_out = sdCylinderZ(p, -54.0f, -52.0f, 10.2f, Z_COURT - 2.0f, Z_COURT + 12.5f, 0.7f);
            float d_rim = sdCylinderZ(p, -54.0f, -52.0f, 11.1f, Z_COURT + 10.0f, Z_COURT + 13.0f, 0.7f);
            float d_in  = sdCylinderZ(p, -54.0f, -52.0f, 6.8f, Z_COURT + 2.0f, Z_COURT + 16.0f, 0.45f);
            float d_well = smax(smin(d_out, d_rim, 0.45f), -d_in, 0.45f);
            if (std::fabs(d_well) < 2.0f && wr > 8.0f && p.z > Z_COURT + 0.5f && p.z < Z_COURT + 12.0f) {
                d_well -= ashlarDisplacement((wang + PI) * 10.2f, p.z, 3.2f, 5.4f, 0.38f, 0.22f, 401);
            }
            d = smin(d, d_well, 0.55f);
        }
    }

    // ------------------------------------------------------------------------
    // 8. SINGLE FLAT-TOPPED OPEN-BACK KEEP (DONJON) — LOWERED 30mm TO 220.0 mm!
    //    Spans x in [-52, +52] (104mm wide), y in [+36, +121] (85mm deep, anchored to rear wall)
    //    Flat smooth roof deck at z = 204.0 mm, crenellations to z = 220.0 mm!
    //    Back wall cleanly OPEN across all 3 levels (z = 28..79, 86..137, 144..196)
    //    with pass-through Gothic lancet windows for manual figure placement!
    // ------------------------------------------------------------------------
    {
        float d_kb = sdBoxMinMax(p, -61.0f, 61.0f, 16.0f, 132.0f, Z_COURT - 4.0f, Z_KEEP_PARA + 3.0f);
        if (d_kb < d + 4.0f) {
            float kx0 = -52.0f, kx1 = 52.0f;
            float ky0 =  36.0f, ky1 = 121.0f;
            float kcx = 0.0f,   kcy = 78.5f;
            float khx = 52.0f,  khy = 42.5f;

            // 8a. Main Keep Body + Battered Plinth + 38-deg Support-Free Corbelled Crown (solid overlap into roof!)
            float d_kp_plinth = sdBatteredBox(p, kcx, kcy, Z_COURT - 4.0f, Z_COURT + 20.0f, khx + 4.5f, khy + 4.5f, khx, khy, 0.9f);
            float d_kp_shaft  = sdBoxMinMax(p, kx0, kx1, ky0, ky1, Z_COURT + 16.0f, Z_KEEP_DECK + 1.0f, 0.9f);
            float d_kp_corb   = sdBatteredBox(p, kcx, kcy, Z_KEEP_DECK - 8.2f, Z_KEEP_DECK - 1.5f,
                                              khx - 0.5f, khy - 0.5f, khx + 3.5f, khy + 3.5f, 0.7f);
            float d_kp_crown  = sdBoxMinMax(p, kx0 - 3.5f, kx1 + 3.5f, ky0 - 3.5f, ky1 + 3.5f,
                                            Z_KEEP_DECK - 1.5f, Z_KEEP_PARA, 0.7f);
            float d_keep = smin(std::min(d_kp_plinth, d_kp_shaft), smin(d_kp_corb, d_kp_crown, 0.5f), 0.75f);

            // 8b. Classic Norman Stepped Corner Buttresses & Side Wall Pilasters
            //     (No rear center pilaster since back wall is open!)
            {
                float set1 = smoothstep(82.0f, 86.5f, p.z);
                float set2 = smoothstep(140.0f, 144.5f, p.z);
                float buttOut = 3.5f - 0.85f * set1 - 0.85f * set2;

                float axk = std::fabs(p.x - kcx);
                float ayk = std::fabs(p.y - kcy);
                // Corner square pilasters at all 4 corners (stop cleanly outside the open rear interior x in [-43, 43]!)
                float d_cbut = sdBoxMinMax(Vec3(axk, ayk, p.z), khx - 10.0f, khx + buttOut, khy - 12.0f, khy + buttOut,
                                           Z_COURT - 2.0f, Z_KEEP_DECK - 6.5f, 0.75f);
                // Central vertical buttress strips on left & right walls
                float d_sbutLR = sdBoxMinMax(Vec3(axk, ayk, p.z), khx - 2.0f, khx + buttOut * 0.75f, 0.0f, 6.8f,
                                             Z_COURT - 2.0f, Z_KEEP_DECK - 6.5f, 0.65f);
                d_keep = smin(d_keep, std::min(d_cbut, d_sbutLR), 0.55f);
            }

            // 8c. Projecting 45-deg Stone Stringcourses (Belt Courses) aligned with Floor 2 (z=84) & Floor 3 (z=142)
            for (float zb : {84.0f, 142.0f}) {
                if (std::fabs(p.z - zb) < 4.0f) {
                    float d_b1 = sdBatteredBox(p, kcx, kcy, zb - 2.0f, zb, khx - 0.2f, khy - 0.2f, khx + 1.5f, khy + 1.5f, 0.35f);
                    float d_b2 = sdBatteredBox(p, kcx, kcy, zb, zb + 1.5f, khx + 1.5f, khy + 1.5f, khx - 0.2f, khy - 0.2f, 0.35f);
                    d_keep = smin(d_keep, std::min(d_b1, d_b2), 0.4f);
                }
            }

            // 8d. Corbel brackets under Keep battlement overhang
            {
                float axk = std::fabs(p.x - kcx) - khx;
                float ayk = std::fabs(p.y - kcy) - khy;
                float mXY = std::max(axk, ayk);
                float corbM = smoothstep(Z_KEEP_DECK - 8.2f, Z_KEEP_DECK - 5.4f, p.z)
                            * smoothstep(Z_KEEP_DECK - 1.4f, Z_KEEP_DECK - 3.0f, p.z)
                            * smoothstep(-1.5f, 0.5f, mXY) * smoothstep(5.5f, 3.0f, mXY);
                if (corbM > 0.001f) {
                    float u = (axk > ayk) ? (p.y - kcy) : (p.x - kcx);
                    float uf = std::fabs(std::fmod(u + 200.0f, 10.5f) - 5.25f);
                    d_keep -= 0.78f * smoothstep(2.4f, 1.3f, uf) * corbM;
                }
            }

            // 8e. Hollow out Keep's HUGE Single SMOOTH Flat Walkable Roof Deck (z = 204.0 mm)
            float d_kp_deck = sdBoxMinMax(p, kx0 + 4.8f, kx1 - 4.8f, ky0 + 4.8f, ky1 - 4.8f, Z_KEEP_DECK, 240.0f, 0.65f);
            d_keep = smax(d_keep, -d_kp_deck, 0.55f);

            // 8f. Explicit sliver-free crenellations along Keep Crown (z = 212..220mm)
            // Front/Rear (111mm): 4 embrasures at x = ±11, ±33 (width 9.6mm -> 12.4mm interior & 17.7mm corner merlons!)
            // Left/Right (92mm):  3 embrasures at dy = 0, ±22  (width 9.6mm -> 12.4mm interior & 19.2mm corner merlons!)
            if (p.z > Z_KEEP_DECK + 6.0f && p.z < Z_KEEP_PARA + 3.0f) {
                float axk = std::fabs(p.x - kcx) - khx;
                float ayk = std::fabs(p.y - kcy) - khy;
                if (std::max(axk, ayk) > -6.0f) {
                    float d_emb_u = 1e6f;
                    if (axk > ayk) {
                        float dyAbs = std::fabs(p.y - kcy);
                        d_emb_u = std::min(dyAbs - 4.8f, std::fabs(dyAbs - 22.0f) - 4.8f);
                    } else {
                        float dxAbs = std::fabs(p.x - kcx);
                        d_emb_u = std::min(std::fabs(dxAbs - 11.0f) - 4.8f, std::fabs(dxAbs - 33.0f) - 4.8f);
                    }
                    float d_emb = std::max(d_emb_u, (Z_KEEP_DECK + 8.0f) - p.z);
                    d_keep = smax(d_keep, -(d_emb - 0.55f), 0.60f);
                }
            }

            // 8g. Grand Ceremonial Front Steps & Gothic Portal Frame (Front of Keep, y = +36)
            float portalProtect = 1.0f;
            {
                float d_fb = sdBoxMinMax(p, -28.0f, 28.0f, 20.0f, 44.0f, Z_COURT - 2.0f, 82.0f);
                if (d_fb < d_keep + 3.5f) {
                    // 2 broad ceremonial stone steps rising from courtyard z=20 -> z=28mm
                    for (int s = 0; s < 2; ++s) {
                        float sy0 = 24.0f + s * 6.0f;
                        float sz1 = Z_COURT + 4.0f * (s + 1);
                        d_keep = smin(d_keep, sdBoxMinMax(p, -21.0f, 21.0f, sy0, 38.0f, Z_COURT - 2.0f, sz1, 0.45f), 0.4f);
                    }
                    // Flanking low carved stone stair cheeks
                    float d_cheek = sdBoxMinMax(Vec3(std::fabs(p.x), p.y, p.z), 19.0f, 23.2f, 24.5f, 37.0f, Z_COURT - 2.0f, Z_COURT + 11.5f, 0.55f);
                    d_keep = smin(d_keep, d_cheek, 0.45f);

                    // Carved Gothic Portal Voussoir Frame on Keep Front Face (y = +36, z = 28..74)
                    float d_po = sdGothicArch2D(p.x, p.z, 18.0f, Z_L1_FLOOR - 1.0f, 54.0f, 79.0f);
                    float d_pi = sdGothicArch2D(p.x, p.z, 14.0f, Z_L1_FLOOR - 1.0f, 54.0f, 74.0f);
                    float d_pframe = std::max(std::max(d_po, -d_pi), std::fabs(p.y - 35.6f) - 1.8f);
                    if (std::fabs(d_pframe) < 2.0f && p.z > 53.0f) {
                        float va = std::atan2(p.z - 54.0f, p.x);
                        float vf = std::fmod(va + PI, PI / 13.0f);
                        float vg = std::min(vf, PI / 13.0f - vf) * 16.0f;
                        d_pframe += 0.38f * (1.0f - smoothstep(0.10f, 0.50f, vg));
                    }
                    d_keep = smin(d_keep, d_pframe, 0.35f);
                    portalProtect = smoothstep(-0.4f, 1.5f, d_pframe);
                }
            }

            // 8h. Fine Ashlar Masonry on Exterior Keep Walls ONLY (roof & interior floors stay completely SMOOTH!)
            if (std::fabs(d_keep) < 2.5f && p.z < Z_KEEP_PARA + 1.0f) {
                float axk = std::fabs(p.x - kcx) - khx;
                float ayk = std::fabs(p.y - kcy) - khy;
                float terraceMask = (p.x > kx0 + 4.5f && p.x < kx1 - 4.5f && p.y > ky0 + 4.5f && p.y < ky1 - 4.5f)
                                  ? smoothstep(1.8f, 0.2f, std::fabs(p.z - Z_KEEP_DECK)) : 0.0f;

                if (terraceMask < 0.85f && p.z > Z_COURT - 2.0f) {
                    float u = (axk > ayk) ? (p.y - kcy) : (p.x - kcx);
                    int fseed = (axk > ayk) ? (p.x > 0 ? 501 : 502) : (p.y > kcy ? 503 : 504);
                    float disp = ashlarDisplacement(u + 120.0f, p.z, 4.6f, 9.0f, 0.50f, 0.32f, fseed);
                    float topMask = smoothstep(0.0f, 1.2f, Z_KEEP_PARA - p.z)
                                  * smoothstep(0.0f, 1.5f, std::fabs(p.z - Z_KEEP_DECK))
                                  * smoothstep(Z_COURT - 3.0f, Z_COURT + 2.0f, p.z);
                    d_keep -= disp * topMask * portalProtect;
                }
            }

            d = smin(d, d_keep, 0.80f);
        }
    }

    // ------------------------------------------------------------------------
    // 9. CARVE OPEN-BACK KEEP INTERIOR LEVELS & PASS-THROUGH GOTHIC WINDOWS!
    //    Applied AFTER unioning curtain wall & Keep so the rear wall opens cleanly!
    //    3 generous playable levels with smooth flat floors & open-through windows:
    //      Level 1 (Great Hall):    floor z=28.0 .. ceiling z=79.0  (51mm clear) + front Gothic portal
    //      Level 2 (Mid Chamber):   floor z=86.0 .. ceiling z=137.0 (51mm clear) + pass-through twin windows
    //      Level 3 (Upper Chamber): floor z=144.0.. ceiling z=196.0 (52mm clear) + pass-through triple/twin windows
    // ------------------------------------------------------------------------
    {
        float d_open_bound = sdBoxMinMax(p, -58.0f, 58.0f, 30.0f, 134.0f, Z_L1_FLOOR - 2.0f, Z_KEEP_DECK);
        if (d_open_bound < 4.0f) {
            float d_cut = 1e9f;

            // Helper: Open-back room box (x in [-43, +43] = 86mm wide, y in [+45, +132] open all the way out rear!)
            // with slight 45-deg corbelled top cove on left/right/front ceiling edges for strength & realism
            float d_room1 = sdBoxMinMax(p, -43.0f, 43.0f, 45.0f, 132.0f, Z_L1_FLOOR, 79.0f, 0.8f);
            float d_room2 = sdBoxMinMax(p, -43.0f, 43.0f, 45.0f, 132.0f, Z_L2_FLOOR, 137.0f, 0.8f);
            float d_room3 = sdBoxMinMax(p, -43.0f, 43.0f, 45.0f, 132.0f, Z_L3_FLOOR, 196.0f, 0.8f);
            d_cut = std::min(d_room1, std::min(d_room2, d_room3));

            // Level 1 Front Gothic Portal opening ALL THE WAY THROUGH into Level 1 Great Hall!
            float d_portal = sdGothicTunnelY(p, 0.0f, 14.0f, 30.0f, 50.0f, Z_L1_FLOOR, 54.0f, 74.0f);
            d_cut = std::min(d_cut, d_portal);

            // Level 2 Pass-Through Gothic Lancet Windows (floor z=86 -> sill z=97, peak z=127 -> waist-high for figures!)
            if (p.z > 94.0f && p.z < 131.0f) {
                // Front face (y = 36..45): Twin lancet windows at x = ±20
                float d_w2fL = sdGothicTunnelY(p, -20.0f, 5.2f, 31.0f, 49.0f, 97.0f, 118.0f, 127.0f);
                float d_w2fR = sdGothicTunnelY(p, +20.0f, 5.2f, 31.0f, 49.0f, 97.0f, 118.0f, 127.0f);
                // Left & Right faces (x = ±43..±52): Twin lancet windows at y = 62 and y = 96
                float d_w2s1 = sdGothicTunnelX(Vec3(std::fabs(p.x), p.y, p.z), 62.0f, 5.0f, 40.0f, 58.0f, 97.0f, 118.0f, 126.5f);
                float d_w2s2 = sdGothicTunnelX(Vec3(std::fabs(p.x), p.y, p.z), 96.0f, 5.0f, 40.0f, 58.0f, 97.0f, 118.0f, 126.5f);
                d_cut = std::min(d_cut, std::min(std::min(d_w2fL, d_w2fR), std::min(d_w2s1, d_w2s2)));
            }

            // Level 3 Pass-Through Gothic Lancet Windows (floor z=144 -> sill z=155, peak z=185 -> waist-high for figures!)
            if (p.z > 152.0f && p.z < 189.0f) {
                // Front face (y = 36..45): Triple lancet windows at x = -24, 0, +24
                float d_w3fC = sdGothicTunnelY(p,   0.0f, 4.4f, 31.0f, 49.0f, 155.0f, 176.0f, 184.5f);
                float d_w3fS = sdGothicTunnelY(Vec3(std::fabs(p.x), p.y, p.z), 24.5f, 4.4f, 31.0f, 49.0f, 155.0f, 176.0f, 184.5f);
                // Left & Right faces (x = ±43..±52): Twin lancet windows at y = 62 and y = 96
                float d_w3s1 = sdGothicTunnelX(Vec3(std::fabs(p.x), p.y, p.z), 62.0f, 4.8f, 40.0f, 58.0f, 155.0f, 176.0f, 184.5f);
                float d_w3s2 = sdGothicTunnelX(Vec3(std::fabs(p.x), p.y, p.z), 96.0f, 4.8f, 40.0f, 58.0f, 155.0f, 176.0f, 184.5f);
                d_cut = std::min(d_cut, std::min(std::min(d_w3fC, d_w3fS), std::min(d_w3s1, d_w3s2)));
            }

            d = smax(d, -d_cut, 0.45f);
        }
    }

    // ------------------------------------------------------------------------
    // 10. EXACT DEAD-FLAT BASE AT z = 0.000 mm AND BOUNDING ENVELOPE CLAMP
    // ------------------------------------------------------------------------
    d = std::max(d, -p.z);
    d = std::max(d, p.z - Z_KEEP_PARA);
    d = std::max(d, std::fabs(p.x) - 145.0f);
    d = std::max(d, std::fabs(p.y) - 145.0f);

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
    Vec3 bmin(-147.0f, -147.0f, -0.5f);
    Vec3 bmax( 147.0f,  147.0f, 224.0f);
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
                float baseTint = smoothstep(16.0f, 21.0f, pos.z);
                float br = lerpf(0.56f, 0.78f, baseTint) * stoneVar;
                float bg = lerpf(0.54f, 0.76f, baseTint) * stoneVar;
                float bb = lerpf(0.51f, 0.72f, baseTint) * stoneVar;

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
    const float x0 = -147.0f, y0 = -147.0f;
    const float z0 = -0.5f * h;
    const int nx = (int)std::ceil(294.0f / h) + 3;
    const int ny = (int)std::ceil(294.0f / h) + 3;
    const int nz = (int)std::ceil(223.0f / h) + 3;

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
        #pragma omp parallel for schedule(static)
        for (size_t i = 0; i < mesh.verts.size(); ++i) {
            Vec3& v = mesh.verts[i];
            if (v.z == 0.0f) continue;
            float f = castleSDF(v);
            if (std::fabs(f) > 1e-4f && std::fabs(f) < h * 0.45f) {
                Vec3 n = calcNormal(v, h * 0.35f);
                Vec3 vn = v - n * (f * 0.65f);
                if (vn.z > 0.03f) v = vn;
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

    for (uint32_t ti = 0; ti < nT; ++ti) {
        const auto& t = mesh.tris[ti];
        vTris[t[0]].push_back(ti);
        vTris[t[1]].push_back(ti);
        vTris[t[2]].push_back(ti);
        Vec3 p0 = mesh.verts[t[0]], p1 = mesh.verts[t[1]], p2 = mesh.verts[t[2]];
        Vec3 n = cross(p1 - p0, p2 - p0);
        double len = std::sqrt(double(n.x)*n.x + double(n.y)*n.y + double(n.z)*n.z);
        if (len > 1e-12) {
            double nx = n.x / len, ny = n.y / len, nz = n.z / len;
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
    std::snprintf(header, sizeof(header), "Ironcrest Keep v3 290x290x220mm Open-Back Sculpted FDM Playset");
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
        // Rear isometric & direct open-back interior views lit from rear-top so all 3 interior levels shine!
        renderView(outDir + "/view_rear_iso.ppm",       W, H, { 280,  345, 225}, {0, 20,  95}, 42.0f, { 0.45f,  0.65f, 0.60f});
        renderView(outDir + "/view_rear_interior.ppm",  W, H, {  28,  345, 130}, {0, 65, 108}, 42.0f, { 0.35f,  0.72f, 0.58f});
        renderView(outDir + "/view_front_elev.ppm",     W, H, {   0, -445, 118}, {0,  0, 105}, 38.0f);
        renderView(outDir + "/view_top_courtyard.ppm",  W, H, {   0, -105, 470}, {0,  5,  35}, 42.0f);
        renderView(outDir + "/view_gate_closeup.ppm",   W, H, { -45, -225,  68}, {0, -110, 54}, 40.0f);
        std::cout << "Done rendering previews!\n";
    }

    if (mode == "mesh" || mode == "final") {
        float h = (argc > 3) ? std::stof(argv[3]) : 0.44f;
        size_t targetTris = (argc > 4) ? (size_t)std::stoull(argv[4]) : 1800000ULL;
        std::string stlPath = outDir + "/medieval_castle_290x220.stl";

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
