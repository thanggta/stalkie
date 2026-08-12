// Sources/CarveDamage/MetalShaders.swift

/// The MSL source, embedded as a string so the shader is a single source of
/// truth checked into the repo (no binary .metallib asset to keep in sync).
/// Compiled once at first use via `device.makeLibrary(source:)`.
///
/// Determinism contract (the whole point of `damage.seed`):
///   - No time, frame index, display size, or unseeded random anywhere.
///   - Every stochastic decision comes from `seed` through 32-bit integer
///     hashes, which are identical on every Metal device.
///   - All geometry is in normalized uv space, never pixel coordinates, so a
///     fragment renders the same damage regardless of the view size it is
///     drawn at.
///   - Intensity only scales the amount/magnitude of damage (via uniforms);
///     it does not move the pattern, so progressive reveal keeps the same
///     damage receding rather than reshuffling.
enum MetalShaders {
  static let source = """
  #include <metal_stdlib>
  using namespace metal;

  struct DamageUniforms {
    float4 u0;   // (intensity, p1, p2, p3)
    float4 u1;   // reserved
    uint   seed;
    uint   profile;
    uint   _pad0;
    uint   _pad1;
  };

  // 32-bit integer hash family — deterministic on every GPU. No floats in
  // the hash input, so precision modes cannot change the output.
  //
  // The finalizer is a well-known avalanche hash: changing one input bit
  // flips ~half the output bits. That property is load-bearing here — a poor
  // mixer makes consecutive seeds (8812 vs 8813) produce near-identical hash
  // values, which 8-bit output quantization then rounds to the same color.
  // (A first draft used a weaker mixer and the "different seed must change
  // the output" determinism test caught exactly that.)
  static inline uint hash11(uint n) {
    n ^= n >> 16U;
    n *= 0x7FEB352DU;
    n ^= n >> 15U;
    n *= 0x846CA68BU;
    n ^= n >> 16U;
    return n;
  }

  static inline uint hash21(uint x, uint y, uint seed) {
    uint h = x * 0x45D9F3BU + y * 0x27D4EB2DU + seed * 0x9E3779B1U;
    return hash11(h);
  }

  // Uses only the low 24 bits: exactly representable in float32, so no
  // precision rounding collapses distinct hash values onto the same color.
  static inline float hash01(uint h) {
    return float(h & 0xFFFFFFU) / 16777216.0;
  }

  // Two independent hash01 values for a cell coordinate.
  static inline float2 hash2f(uint x, uint y, uint seed) {
    uint a = hash21(x, y, seed);
    uint b = hash11(a ^ 0x9E3779B9U);
    return float2(hash01(a), hash01(b));
  }

  struct RasterizerData {
    float4 position [[position]];
    float2 uv;
  };

  vertex RasterizerData carve_vertex(uint vid [[vertex_id]]) {
    RasterizerData out;
    float2 pos = float2(float(vid & 1U) * 4.0 - 1.0, float(vid & 2U) * 2.0 - 1.0);
    out.position = float4(pos, 0.0, 1.0);
    // uv (0,0) is the top-left of the source texture; texture row 0 is the
    // top of the render target, so no vertical flip is needed.
    float2 uv = pos * 0.5 + 0.5;
    out.uv = float2(uv.x, 1.0 - uv.y);
    return out;
  }

  fragment float4 carve_damage_fragment(
      RasterizerData in [[stage_in]],
      texture2d<float> source [[texture(0)]],
      const device DamageUniforms &u [[buffer(0)]],
      sampler samp [[sampler(0)]]) {
    float2 uv = in.uv;
    float intensity = u.u0.x;
    uint seed = u.seed;

    float4 src = source.sample(samp, uv);
    if (intensity <= 0.0) {
      return src;
    }

    if (u.profile == 0U) {
      // block-loss: a normalized grid of cells; lost cells are a flat,
      // seeded noise block the way a half-decoded JPEG block reads.
      float cells = u.u0.y;
      float threshold = u.u0.z;
      uint2 cell = uint2(uv * cells);
      float2 n = hash2f(cell.x, cell.y, seed);
      if (n.x < threshold) {
        float g = n.y;
        return float4(float3(g), 1.0);
      }
      return src;
    }

    if (u.profile == 1U) {
      // scanline-tear: horizontal bands displaced sideways. Which bands tear
      // and by how much come from the seed; intensity scales band count,
      // tear probability, and displacement.
      float bands = u.u0.y;
      float tearProb = u.u0.z;
      float maxShift = u.u0.w;
      uint band = uint(floor(uv.y * bands));
      float2 n = hash2f(band, 0U, seed);
      if (n.x < tearProb) {
        float shift = (n.y - 0.5) * 2.0 * maxShift;
        float2 suv = clamp(float2(uv.x + shift, uv.y), 0.0, 1.0);
        return source.sample(samp, suv);
      }
      return src;
    }

    if (u.profile == 2U) {
      // partial-decode: the bottom of the image is seeded noise, with a
      // jagged boundary — a JPEG that loaded from the top and gave up.
      float decodeFrac = u.u0.y;
      float jitter = u.u0.z;
      float scale = u.u0.w;
      uint xc = uint(floor(uv.x * scale));
      float2 n = hash2f(xc, 0U, seed);
      float boundary = clamp(decodeFrac + (n.x - 0.5) * 2.0 * jitter, 0.0, 1.0);
      if (uv.y > boundary) {
        float2 noise = hash2f(
            uint(floor(uv.x * scale)), uint(floor(uv.y * scale)), seed);
        return float4(float3(noise.y), 1.0);
      }
      return src;
    }

    if (u.profile == 3U) {
      // chroma-bleed: color channels sampled at slightly different offsets,
      // varying per region — desynced channels, not displaced pixels.
      float scale = u.u0.y;
      float regions = u.u0.z;
      uint2 rc = uint2(uv * regions);
      float2 n = hash2f(rc.x, rc.y, seed);
      float2 off = (n - 0.5) * 2.0 * scale;
      float r = source.sample(samp, clamp(uv + off, 0.0, 1.0)).r;
      float b = source.sample(samp, clamp(uv - off, 0.0, 1.0)).b;
      return float4(r, src.g, b, 1.0);
    }

    if (u.profile == 4U) {
      // overwrite: seeded patches of foreign data bleeding through, shown as
      // hard-edged binary columns (a different file's bitstream).
      float count = u.u0.y;
      float size = u.u0.z;
      float scale = u.u0.w;
      bool inside = false;
      uint phase = 0U;
      uint maxP = uint(count);
      for (uint i = 0U; i < maxP && !inside; i++) {
        float2 center = hash2f(i, 1U, seed);
        float radius = hash2f(i, 2U, seed).y * size;
        if (distance(uv, center) < radius) {
          inside = true;
          phase = i;
        }
      }
      if (inside) {
        uint col = uint(floor(uv.x * scale));
        uint row = uint(floor(uv.y * scale));
        float v = hash01(hash21(col, row, seed ^ hash11(phase)));
        float g = v > 0.5 ? 0.9 : 0.1;
        return float4(float3(g), 1.0);
      }
      return src;
    }

    return src;
  }
  """
}
