#include "../Includes/Common.hlsl"

Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

#ifndef ENABLE_VIGNETTE
#define ENABLE_VIGNETTE 1
#endif

#ifndef ENABLE_DARKNESS_EFFECT
#define ENABLE_DARKNESS_EFFECT 1
#endif

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : COLOR0,
  float4 v2 : TEXCOORD0,
  float4 v3 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  
  float2 uv = v3.xy / v3.w;

  float w, h;
  t1.GetDimensions(w, h);
  float ar = w / h;

  float2 uv2 = v2.xy;
  float ndc2 = (uv2.x - 0.5) * 2.0;
  ndc2 = pow(abs(ndc2), max(ar / (21.0 / 9.0), 1.0)) * sign(ndc2); // Adjust by aspect ratio as vignette was extremely stretched at 32:9, we do it at 21:9 because the game supports that, and scaling it from 16:9 seems too much
  uv2.x = (ndc2 / 2.0) + 0.5;

  r0.xyzw = t1.Sample(s1_s, uv).xyzw; // Darkness effect
  r0.x = 1.0 - (r0.x * 0.8);
  r1.xyzw = t0.Sample(s0_s, uv2).xyzw; // Vignette
  r1.xyzw = v1.xyzw * r1.xyzw; // Vignette tint
#if 0 // Luma: vignette intensity (1 is vanilla)
  r1.a *= LumaData.CustomData3;
#endif
#if !ENABLE_VIGNETTE
  r1.a = 0.0;
#endif
  r0.x = r1.w * r0.x;
  o0.xyz = r1.xyz * r0.x;
#if !ENABLE_DARKNESS_EFFECT // TODO: find a way to split these, as of now they do the same thing...
  r0.x = 0.0;
#endif
  o0.w = r0.x;
}