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
  r0.xyzw = r1.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, v2.xy).xyzw;
  r0.xyzw = r1.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, v2.zw).xyzw;
  r0.xyzw = r1.xyzw + r0.xyzw;
  o0.xyzw = float4(0.25,0.25,0.25,0.25) * r0.xyzw;
}