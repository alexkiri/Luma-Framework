#include "Includes/Common.hlsl"

cbuffer ConstentValue : register(b0)
{
  float4 register0 : packoffset(c0);
  float4 register1 : packoffset(c1);
}

SamplerState sampler0_s : register(s0);
Texture2D<float4> texture0 : register(t0);

// Often used for bloom like effects, or sun shafts and lens camera effects, but also as a general "copy" shader
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_TARGET0)
{
  float4 r0;
  r0.xyzw = texture0.Sample(sampler0_s, v1.xy).xyzw;
  o0.xyzw = r0.xyzw * register0.xyzw + register1.xyzw;

  // Note: these can draw after tonemap, so they they will go beyond peak, but it's not important...
  // If multiple viewports are drawn, this flag won't be set as each viewport has its own tonemapper, this means some of these effects might scale with UI brightness, but whatever.
  if (LumaSettings.GameSettings.DrewTonemap)
  {
#if !ENABLE_POST_PROCESS_EFFECTS
    o0.xyzw = 0;
#else
    o0.xyzw *= LumaSettings.GameSettings.BloomAndLensFlareIntensity; // Scale in gamma space

#if UI_DRAW_TYPE == 2 // These are not part of the UI so we need to scale them by the same intensity as the scene
    const float gamePaperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
    const float UIPaperWhite = LumaSettings.UIPaperWhiteNits / sRGB_WhiteLevelNits;
    o0.rgb /= pow(UIPaperWhite, 1.0 / DefaultGamma);
    o0.rgb *= pow(gamePaperWhite, 1.0 / DefaultGamma);
#endif // UI_DRAW_TYPE == 2
#endif
  }
}