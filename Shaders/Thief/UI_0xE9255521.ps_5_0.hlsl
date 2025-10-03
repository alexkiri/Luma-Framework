Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.x = dot(cb0[1].xyzw, cb0[1].xyzw);
  r0.x = r0.x != 0.0;
  r1.xyzw = t0.Sample(s0_s, v0.xy).xyzw;
  r0.y = dot(r1.xyzw, cb0[1].xyzw);
  r0.xyzw = r0.xxxx ? r0.yyyy : r1.xyzw;
  r0.w = dot(r0.xyzw, cb0[2].xyzw);
  o0.xyzw = v1.xyzw * r0.xyzw;

  // Luma: fix UI negative values to emulate UNORM blends
  o0.w = saturate(o0.w);
  o0.xyz = max(o0.xyz, 0.f);
}