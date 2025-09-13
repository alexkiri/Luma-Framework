#include "Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

cbuffer ConstantBuffer : register(b0)
{
  float4 register1 : packoffset(c1);
  float4 register2 : packoffset(c2);
}

SamplerState diffuseMapSampler_s : register(s0);
SamplerState DistortionMapSampler_s : register(s2);
SamplerState BlurMapSampler_s : register(s6);
SamplerState depthMapSampler_s : register(s8);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);
Texture2D<float4> texture2 : register(t2);
Texture2D<float4> texture6 : register(t6);
Texture2D<float4> depthMap : register(t8);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD2,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1,r2;
  o0.w = 1;
  r0.x = depthMap.Sample(depthMapSampler_s, v1.xy).x;
  r0.x = -r0.x * register1.z + register1.y;
  r0.x = register1.x / r0.x;
  r0.x -= 3.0;
  r0.x = saturate(0.2 * r0.x);
  r0.y = texture2.Sample(DistortionMapSampler_s, v3.xy).x;
  r0.z = texture2.Sample(DistortionMapSampler_s, v3.zw).y;
  r0.y = r0.y * r0.z;
  r0.y = register1.w * r0.y;
  r0.x = r0.y * r0.x;
  r0.z = -r0.x;
  r0.y = 0;
  r0.zw = v1.xy + r0.zy;
  r0.xy = v1.xy + r0.xy;
  r1.xyz = texture0.Sample(diffuseMapSampler_s, r0.xy).xyz;
  r0.xyz = texture0.Sample(diffuseMapSampler_s, r0.zw).xyz;
  r0.xyz = r1.xyz + r0.xyz;
  r1.xyz = texture0.Sample(diffuseMapSampler_s, v1.xy).xyz;
#if !ENABLE_POST_PROCESS
  o0.xyz = r1.xyz;
  return;
#endif
  r0.xyz = r0.xyz * 0.5 - r1.xyz;
  r0.xyz = register2.x * r0.xyz + r1.xyz;
  r1.xyz = texture6.Sample(BlurMapSampler_s, v2.xy).xyz;
  r2.xyz = -0.24 + r1.xyz;
#if !ENABLE_LUMA
  r2.xyz = max(float3(0,0,0), r2.xyz);
#else // This cam generate some nice extra gamut
  FixColorGradingLUTNegativeLuminance(r2.xyz);
#endif
  r2.xyz = 1.2 * r2.xyz;
  r1.xyz = r1.xyz * float3(0.8,0.88,1) + r2.xyz;
  r1.xyz = r1.xyz - r0.xyz;
  r0.w = texture1.Sample(BlurMapSampler_s, v1.zw).x;
  o0.xyz = r0.w * r1.xyz + r0.xyz;
}