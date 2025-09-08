cbuffer ConstantValue : register(b0)
{
  float4 register0 : packoffset(c0);
}

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
#if ENABLE_LUMA
  r0.a = saturate(r0.a);
  r1.xyz = max(r0.rgb * r0.a - register0.w, min(r0.rgb * r0.a, 0.0)); // Preserve negative colors, but don't generate additional ones
  r0.xyz = max(r0.xyz - register0.y, min(r0.xyz, 0.0));
#else
  r0 = saturate(r0); // Clamp to UNORM
  r1.xyz = saturate(r0.rgb * r0.a - register0.w);
  r0.xyz = saturate(r0.xyz - register0.y);
#endif
  r1.xyz = register0.z * r1.xyz;
  o0.xyz = r0.xyz * register0.x + r1.xyz;
  o0.w = 1;
}