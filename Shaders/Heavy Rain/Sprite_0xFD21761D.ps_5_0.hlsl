SamplerState sampler0_s : register(s0);
Texture2D<float4> texture0 : register(t0);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_TARGET0)
{
  float4 r0;
  r0.xyzw = texture0.Sample(sampler0_s, v1.xy).xyzw;
  o0.xyzw = v2.xyzw * r0.xyzw;
  
  // LUMA: emulate UNORM
  o0.rgb = max(o0.rgb, 0.0);
  o0.a = saturate(o0.a);
}