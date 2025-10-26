// ---- Created with 3Dmigoto v1.3.16 on Thu Aug 21 00:46:21 2025

cbuffer MultisliceConstants : register(b1)
{
  uint gSliceIndex : packoffset(c0);
  float3 _padding : packoffset(c0.y);
}

cbuffer VignetteConstants : register(b13)
{
  float4 gVigCenterEyes : packoffset(c0);
  float4 gCenterColor_RadiusV : packoffset(c1);
  float4 gOuterColor_Aspect : packoffset(c2);
  float4 gMaxOutputColor : packoffset(c3);
}

// Vignette only (it's either an unused permutation of the post process unified shader, or actually used as multiplicative blend vignette)
// This has been bundled in the tonemap pass shader with all permutations
void main(
  float v0 : SV_ClipDistance0,
  float w0 : SV_CullDistance0,
  float4 v1 : SV_Position0,
  float2 v2 : TEXCOORD0,
  float2 w2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  static const float4 icb[] = { { 1.000000, 0, 0, 0},
                                { 0, 1.000000, 0, 0},
                                { 0, 0, 1.000000, 0},
                                { 0, 0, 0, 1.000000} };

  float4 r0;
  int4 r0i;

  // bfi r0i.x, l(31), l(1), gSliceIndex, l(1)
  uint bitmask = ((~(-1 << 31)) << 1) & 0xffffffff;
  r0i.x = ((gSliceIndex << 1) & bitmask) | (1 & ~bitmask);

  r0i.x -= 1;
  r0.z = dot(gVigCenterEyes.yw, icb[r0i.x+0].xz);
  r0i.x = gSliceIndex << 1;
  r0.y = dot(gVigCenterEyes.xz, icb[r0i.x+0].xz);
  r0.yz = w2.xy - r0.yz;
  r0.x = gOuterColor_Aspect.w * r0.y;
  r0.x = dot(r0.xz, r0.xz);
  r0.x = sqrt(r0.x);
  float vignette = saturate(r0.x / gCenterColor_RadiusV.w);

  o0.xyz = vignette;
  o0.w = 1;
}