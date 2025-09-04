#include "../Includes/Common.hlsl"

SamplerState BlitSampler_s : register(s0);
Texture2D<float4> BlitTexture : register(t0);

void main(
  float2 v0 : TEXCOORD0,
  float4 v1 : SV_POSITION0,
  out float4 o0 : SV_Target0)
{
  o0.rgba = BlitTexture.Sample(BlitSampler_s, v0.xy).rgba;
  
  // Note: we could do paper white scaling here and apply gamma correction etc (by enabling "EARLY_DISPLAY_ENCODING"),
  // which would allow the final shader to be skipped, though ultimately it seems more complicated than not.
}