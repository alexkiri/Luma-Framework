Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[11];
}

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  nointerpolation float4 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xyzw = t0.Sample(s0_s, v1.xy).xyzw;
  r0.xy = r0.wx * v2.xy + v2.zw;
  r0.z = dot(r0.xy, r0.xy);
  r0.xy = r0.xy * cb0[10].xx + v1.zw;
  r1.xyzw = t1.Sample(s1_s, r0.xy).xyzw;
  o0.xyz = r1.xyz;
  r0.x = 256 * r0.z;
  o0.w = min(1, r0.x);
  
  // Luma: typical UNORM like clamping
  o0.rgb = max(o0.rgb, 0.0);
  o0.a = max(o0.a, 0.0);
}