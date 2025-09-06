#include "../Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

#ifndef ENABLE_LUMA
#define ENABLE_LUMA 1
#endif

#ifndef ENABLE_WIDE_COLOR_GAMUT_BLOOM_TYPE
#define ENABLE_WIDE_COLOR_GAMUT_BLOOM_TYPE 1
#endif

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xyzw = t0.Sample(s0_s, w1.xy).xyzw; // Scene
  r1.xyzw = t1.Sample(s1_s, v1.xy).xyzw; // Bloom

#if ENABLE_LUMA // Prevent negative bloom, if we don't do this, it adds a lot of negative colors and darkens the scene
#if ENABLE_WIDE_COLOR_GAMUT_BLOOM_TYPE > 0
  r1.a = max(0.0, r1.a);
#if ENABLE_WIDE_COLOR_GAMUT_BLOOM_TYPE == 1 // Allow bloom to have negative RGB colors as long as the luminance is valid
  FixColorGradingLUTNegativeLuminance(r1.rgb);
#endif // ENABLE_WIDE_COLOR_GAMUT_BLOOM_TYPE == 1
#else // ENABLE_WIDE_COLOR_GAMUT_BLOOM <= 0
  r1.xyzw = max(0.0, r1.xyzw);
#endif // ENABLE_WIDE_COLOR_GAMUT_BLOOM > 0
#endif // ENABLE_LUMA

  float bloomIntensity = 1.0; // Looks good at default
  r1.xyz *= bloomIntensity; // We don't change the alpha for now

  o0.xyzw = r1.xyzw + r0.xyzw;
  
#if ENABLE_LUMA && ENABLE_WIDE_COLOR_GAMUT_BLOOM_TYPE == 2 // Allow bloom to have negative RGB colors as long as the composes luminance is valid (note: this is overly dark)
  FixColorGradingLUTNegativeLuminance(o0.rgb);
#endif // ENABLE_LUMA && ENABLE_WIDE_COLOR_GAMUT_BLOOM == 2
}