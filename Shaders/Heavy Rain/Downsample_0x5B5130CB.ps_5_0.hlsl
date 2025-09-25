#include "Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

SamplerState sampler0_s : register(s0);
Texture2D<float4> texture0 : register(t0);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1;
  r0.xyzw = texture0.Sample(sampler0_s, v1.xy).xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, v1.zw).xyzw;
#if !LUMA_ENABLED
  r0.xyzw = saturate(r0.xyzw);
  r1.xyzw = saturate(r1.xyzw);
#endif
  r0.xyzw = r1.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, v2.xy).xyzw;
#if !LUMA_ENABLED
  r1.xyzw = saturate(r1.xyzw);
#endif
  r0.xyzw = r1.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, v2.zw).xyzw;
#if !LUMA_ENABLED
  r1.xyzw = saturate(r1.xyzw);
#endif
  r0.xyzw = r1.xyzw + r0.xyzw;
  o0.xyzw = r0.xyzw / 4.0;

#if LUMA_ENABLED
  o0.xyz = IsNaN_Strict(o0.xyz) ? 0.0 : o0.xyz;

  o0.rgb = gamma_to_linear(o0.rgb, GCT_MIRROR);
  FixColorGradingLUTNegativeLuminance(o0.rgb);
  o0.rgb = linear_to_gamma(o0.rgb, GCT_MIRROR);
#endif
}