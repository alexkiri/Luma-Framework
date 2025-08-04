#include "../Includes/Common.hlsl"

SamplerState BlitSampler_s : register(s0);
Texture2D<float4> BlitTexture : register(t0);

void main(
  float2 v0 : TEXCOORD0,
  float4 v1 : SV_POSITION0,
  out float4 o0 : SV_Target0)
{
  o0.rgba = BlitTexture.Sample(BlitSampler_s, v0.xy).rgba;
  
//TODOFT: only do for Prince of Persia or also implement in other games
#if UI_DRAW_TYPE == 2 && 0 // Restore the native white level after the UI has drawn (already done in the final shader!!!)
  //o0.rgb *= LumaSettings.UIPaperWhiteNits / LumaSettings.GamePaperWhiteNits;
  o0.rgb /= LumaSettings.UIPaperWhiteNits / sRGB_WhiteLevelNits;
#endif

  // Note: we could do paper white scaling here and apply gamma correction etc (by enabling "EARLY_DISPLAY_ENCODING"),
  // which would allow the final shader to be skipped, though ultimately it seems more complicated than not.
}