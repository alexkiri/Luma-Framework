Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[6];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[15];
}

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xy = v2.xy / v2.ww;
  r1.xyzw = t0.SampleLevel(s2_s, r0.xy, 0).xyzw;
  r0.xyzw = t1.Sample(s1_s, r0.xy).xyzw;
  r0.xyz = pow(max(r0.xyz, 0.0), cb0[14].x);
  r0.w = cb1[5].z * r1.x + -v2.z;
  r1.x = r0.w < 0;
  r0.w = saturate(r0.w);
  if (r1.x != 0) discard;
  r1.x = 1 + -cb0[14].y;
  r0.xyz = r0.xyz * cb0[14].yyy + r1.x;
  r1.xyzw = t2.Sample(s0_s, v1.xy).xyzw;
  r1.x = -v1.w + r1.x;
  r0.w = r1.x * r0.w;
  r1.x = saturate(v1.z);
  r0.w = r1.x * r0.w;
  r0.xyz = r0.w * r0.xyz;
  o0.xyz = cb0[12].xyz * r0.xyz;
  o0.w = 1;

  // Luma: typical UNORM like clamping
  o0.xyz = max(o0.xyz, 0.0);
}