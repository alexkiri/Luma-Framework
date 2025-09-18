#include "Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

cbuffer ConstantBuffer : register(b0)
{
  float4 register1 : packoffset(c1);
  float4 register2 : packoffset(c2);
}

SamplerState diffuseMapSampler_s : register(s0);
SamplerState BlurMaskMapSampler_s : register(s1); // TODO: fix in UW? For both permutations. It'd probably stretch in it, though it might be fine
SamplerState BlurMapSampler_s : register(s6);
SamplerState depthMapSampler_s : register(s8);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);
Texture2D<float4> texture6 : register(t6);
Texture2D<float4> depthMap : register(t8);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD2,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1;
  o0.w = 1;
  r0.x = depthMap.Sample(depthMapSampler_s, v1.xy).x;
  r0.x = -r0.x * register1.z + register1.y;
  r0.x = register1.x / r0.x;
  r0.x -= 5;
  r0.x = saturate(0.0666666701 * r0.x);
  r0.y = texture1.Sample(BlurMaskMapSampler_s, v1.zw).x;
  r0.x = r0.y * r0.x;
  r0.yzw = texture6.Sample(BlurMapSampler_s, v2.xy).xyz;
  r1.xyz = r0.yzw - 0.2;
#if !ENABLE_LUMA
  r1.xyz = max(float3(0,0,0), r1.xyz);
#else // This can generate some nice extra gamut
  r1.rgb = gamma_to_linear(r1.rgb, GCT_MIRROR);
  FixColorGradingLUTNegativeLuminance(r1.rgb);
  r1.rgb = linear_to_gamma(r1.rgb, GCT_MIRROR);
#endif
  r1.xyz *= 1.8;
  r0.yzw = r0.yzw * float3(1, 1, 1.1) + r1.xyz;
  r1.xyz = texture0.Sample(diffuseMapSampler_s, v1.xy).xyz;
#if !ENABLE_POST_PROCESS
  o0.xyz = r1.xyz;
  return;
#endif
  r0.yzw -= r1.xyz;
  o0.xyz = r0.x * r0.yzw + r1.xyz;
}