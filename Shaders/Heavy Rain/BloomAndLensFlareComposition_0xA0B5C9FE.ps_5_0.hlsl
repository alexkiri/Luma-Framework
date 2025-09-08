cbuffer _Params : register(b0)
{
  float4 register0 : packoffset(c0);
}

SamplerState sampler0_s : register(s0);
SamplerState sampler1_s : register(s1);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1;
  r0.xyz = texture0.Sample(sampler0_s, v1.xy).xyz;
  r1.xyz = texture1.Sample(sampler1_s, v1.xy).xyz;
  // TODO: add TM here for them? It's better than clamping them at source. However, they've already been scaled by intensity here, so it'd be hard to know what was the original PS3 range
  r0.xyz = r1.xyz + r0.xyz;
  o0.xyz = register0.x * r0.xyz;
  o0.w = 0;
}