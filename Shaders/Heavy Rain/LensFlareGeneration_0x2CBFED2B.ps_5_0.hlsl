#include "Includes/Common.hlsl"
#include "../Includes/Reinhard.hlsl"

cbuffer _Params : register(b0)
{
  float4 register0 : packoffset(c0);
}

SamplerState sampler0_s : register(s0);
SamplerState sampler1_s : register(s1);
SamplerState sampler2_s : register(s2);
SamplerState sampler3_s : register(s3);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);
Texture2D<float4> texture2 : register(t2);
Texture2D<float4> texture3 : register(t3);

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1;
  r0.xyz = texture0.Sample(sampler0_s, v1.xy).xyz;
  r1.xyz = texture1.Sample(sampler1_s, v1.xy).xyz;
#if !ENABLE_LUMA
  r0.xyz = saturate(r0.xyz);
  r1.xyz = saturate(r1.xyz);
#endif
  r0.xyz = r1.xyz + r0.xyz;
  r1.xyz = texture2.Sample(sampler2_s, v1.xy).xyz;
#if !ENABLE_LUMA
  r1.xyz = saturate(r1.xyz);
#endif
  r0.xyz = r1.xyz + r0.xyz;
  r1.xyz = texture3.Sample(sampler3_s, v1.xy).xyz;
#if !ENABLE_LUMA
  r1.xyz = saturate(r1.xyz);
#endif
  r0.xyz = r1.xyz + r0.xyz;

  o0.xyz = register0.x * r0.xyz;
  o0.w = 0;
}