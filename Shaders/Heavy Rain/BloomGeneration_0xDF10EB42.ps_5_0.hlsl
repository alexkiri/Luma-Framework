cbuffer ConstantValue : register(b0)
{
  float3 register0 : packoffset(c0);
  float3 register1 : packoffset(c1);
  float3 register2 : packoffset(c2);
  float3 register3 : packoffset(c3);
}

SamplerState sampler0_s : register(s0);
SamplerState sampler1_s : register(s1);
SamplerState sampler2_s : register(s2);
SamplerState sampler3_s : register(s3);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);
Texture2D<float4> texture2 : register(t2);
Texture2D<float4> texture3 : register(t3);

#ifndef ENABLE_POST_PROCESS_EFFECTS
#define ENABLE_POST_PROCESS_EFFECTS 1
#endif

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1;
  r0.xyz = texture1.Sample(sampler1_s, v1.zw).xyz;
  r0.xyz = register1.xyz * r0.xyz;
  r1.xyz = texture0.Sample(sampler0_s, v1.xy).xyz;
  r0.xyz = r1.xyz * register0.xyz + r0.xyz;
  r1.xyz = texture2.Sample(sampler2_s, v2.xy).xyz;
  r0.xyz = r1.xyz * register2.xyz + r0.xyz;
  r1.xyz = texture3.Sample(sampler3_s, v2.zw).xyz;
  o0.xyz = r1.xyz * register3.xyz + r0.xyz;
  o0.w = 1;
#if !ENABLE_POST_PROCESS_EFFECTS
  o0.rgb = 0;
#endif
}