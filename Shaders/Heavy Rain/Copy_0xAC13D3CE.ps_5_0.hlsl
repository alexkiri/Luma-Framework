SamplerState sampler0_s : register(s0);
Texture2D<float4> texture0 : register(t0);

#ifndef ENABLE_POST_PROCESS_EFFECTS
#define ENABLE_POST_PROCESS_EFFECTS 1
#endif

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_TARGET0)
{
  o0.xyzw = texture0.Sample(sampler0_s, v1.xy).xyzw;
#if !ENABLE_POST_PROCESS_EFFECTS
  o0.xyzw = 0;
#endif
}