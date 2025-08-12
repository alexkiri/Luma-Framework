#include "Includes/Common.hlsl"

Texture2D<float4> t3 : register(t3); // Film grain / noise / dither
Texture2D<float> t2 : register(t2); // Y (luminance)
Texture2D<float2> t1 : register(t1); // Co/Cg
Texture2D<float4> t0 : register(t0); // Source color (SDR or HDR)
#if 1 // LUMA
RWTexture2D<float4> u0 : register(u0); // Output
#else
RWTexture2D<unorm float4> u0 : register(u0); // Output
#endif

cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}

#define cmp -

#define IN_POW_2 0
#define OUT_SRGB 0
// Note that dither was applied in gamma space, which makes more sense, applying it in linear isn't perceptually correct.
// Either way, the game doesn't seem to need dithering, especially not in HDR.
#define DITHER 0

static const float DitherIntensity = DITHER ? 0.00787401572 : 0;

[numthreads(64, 1, 1)]
void main(uint3 vThreadGroupID : SV_GroupID, uint3 vThreadIDInGroup : SV_GroupThreadID)
{
  float4 r0,r1,r2,r3,r4,r5;
  uint4 bitmask;
  
  r1.x = (uint)vThreadIDInGroup.x >> 3;
  bitmask.y = ((~(-1 << 1)) << 0) & 0xffffffff;  r1.y = (((uint)vThreadIDInGroup.x << 0) & bitmask.y) | ((uint)r1.x & ~bitmask.y);
  if (3 == 0)
  {
    r1.x = 0;
  }
  else if (3+1 < 32)
  {
    r1.x = (uint)vThreadIDInGroup.x << (32-(3 + 1)); r1.x = (uint)r1.x >> (32-3);
  }
  else
  {
    r1.x = (uint)vThreadIDInGroup.x >> 1;
  }
  r1.xz = mad((int2)vThreadGroupID.xy, int2(16,16), (int2)r1.xy);
  
  r0.zw = 0.0;
  r2.xy = (int2)r1.xz + asint(cb0[1].zw);
  r0.xy = (int2)r2.xy & int2(63,63);
  r0.xyz = t3.Load(r0.xyz).xyz;
  r0.xyz = r0.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r2.xyz = cmp(0.0 < r0.xyz);
  r3.xyz = cmp(r0.xyz < 0.0);
  r0.xyz = float3(1,1,1) + -abs(r0.xyz);
  r0.xyz = sqrt(r0.xyz);
  r0.xyz = float3(1,1,1) + -r0.xyz;
  r2.xyz = (int3)-r2.xyz + (int3)r3.xyz;
  r2.xyz = (int3)r2.xyz;
  r0.xyz = r2.xyz * r0.xyz;
  r1.yw = 0.0;
  r2.xyz = t0.Load(r1.xzy).xyz;
#if IN_POW_2
  r2.xyz = sqr(abs(r2.xyz)) * sign(r2.xyz);
#endif
#if OUT_SRGB
  r2.xyz = linear_to_sRGB_gamma(r2.xyz);
#endif
  r0.xyz = r0.xyz * DitherIntensity + r2.xyz;
  r0.w = 1;
  r2.xy = (int2)r1.xz + asint(cb0[2].xy);
  r1.xy = (int2)r1.xz + int2(8,8);
  u0[r2.xy] = r0.xyzw;

  r0.zw = 0.0;
  r2.xyzw = (int4)r1.xzxy + asint(cb0[1].zwzw);
  r0.xy = (int2)r2.xy & int2(63,63);
  r2.xy = (int2)r2.zw & int2(63,63);
  r0.xyz = t3.Load(r0.xyz).xyz;
  r0.xyz = r0.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r3.xyz = cmp(0.0 < r0.xyz);
  r4.xyz = cmp(r0.xyz < 0.0);
  r0.xyz = float3(1,1,1) + -abs(r0.xyz);
  r0.xyz = sqrt(r0.xyz);
  r0.xyz = float3(1,1,1) + -r0.xyz;
  r3.xyz = (int3)-r3.xyz + (int3)r4.xyz;
  r3.xyz = (int3)r3.xyz;
  r0.xyz = r3.xyz * r0.xyz;
  r3.xyz = t0.Load(r1.xzw).xyz;
#if IN_POW_2
  r3.xyz = sqr(abs(r3.xyz)) * sign(r3.xyz);
#endif
#if OUT_SRGB
  r3.xyz = linear_to_sRGB_gamma(r3.xyz);
#endif
  r0.xyz = r0.xyz * DitherIntensity + r3.xyz;
  r0.w = 1;
  r3.xy = (int2)r1.xz + asint(cb0[2].xy);
  u0[r3.xy] = r0.xyzw;
  r3.yzw = r1.yww;
  r0.xyz = t0.Load(r1.xyw).xyz;
#if IN_POW_2
  r0.xyz = sqr(abs(r0.xyz)) * sign(r0.xyz);
#endif
#if OUT_SRGB
  r0.xyz = linear_to_sRGB_gamma(r0.xyz);
#endif
  r2.zw = 0.0;
  r2.xyz = t3.Load(r2.xyz).xyz;
  r2.xyz = r2.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r4.xyz = cmp(0.0 < r2.xyz);
  r5.xyz = cmp(r2.xyz < 0.0);
  r2.xyz = float3(1,1,1) + -abs(r2.xyz);
  r2.xyz = sqrt(r2.xyz);
  r2.xyz = float3(1,1,1) + -r2.xyz;
  r4.xyz = (int3)-r4.xyz + (int3)r5.xyz;
  r4.xyz = (int3)r4.xyz;
  r2.xyz = r4.xyz * r2.xyz;
  r0.xyz = r2.xyz * DitherIntensity + r0.xyz;
  r2.xy = (int2)r1.xy + asint(cb0[2].xy);
  r3.x = (int)r1.x + -8;
  r0.w = 1;
  u0[r2.xy] = r0.xyzw;
  r0.xy = (int2)r3.xy + asint(cb0[1].zw);
  r0.xy = (int2)r0.xy & int2(63,63);
  r0.zw = 0.0;
  r0.xyz = t3.Load(r0.xyz).xyz;
  r0.xyz = r0.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r1.xyz = cmp(0.0 < r0.xyz);
  r2.xyz = cmp(r0.xyz < 0.0);
  r0.xyz = float3(1,1,1) + -abs(r0.xyz);
  r0.xyz = sqrt(r0.xyz);
  r0.xyz = float3(1,1,1) + -r0.xyz;
  r1.xyz = (int3)-r1.xyz + (int3)r2.xyz;
  r1.xyz = (int3)r1.xyz;
  r0.xyz = r1.xyz * r0.xyz;
  r2.xy = (int2)r3.xy + asint(cb0[2].xy);
  r1.xyz = t0.Load(r3.xyz).xyz;
#if IN_POW_2
  r1.xyz = sqr(abs(r1.xyz)) * sign(r1.xyz);
#endif
#if OUT_SRGB
  r1.xyz = linear_to_sRGB_gamma(r1.xyz);
#endif
  r0.xyz = r0.xyz * DitherIntensity + r1.xyz;
  r0.w = 1;
  u0[r2.xy] = r0.xyzw;
}