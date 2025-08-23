#include "Includes/Common.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[4];
}

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 color = float4(t0.Sample(s0_s, v1.xy).rgb, 1.0);
  float3 transformedColor = color.rgb;
  // This filter would have been linear in, linear out, if it applied to the game scene (it is during cutscenes), otherwise gamma in, gamma out, if it applied to UI elements
  transformedColor.r = dot(cb0[1].rgba, color.rgba);
  transformedColor.g = dot(cb0[2].rgba, color.rgba);
  transformedColor.b = dot(cb0[3].rgba, color.rgba);
#if !ENABLE_LUMA // Avoid clipping gamut, even if possibly the filter about could generate crazy scRGB colors
  transformedColor = max(transformedColor, 0.0);
#endif
  o0.xyz = transformedColor;
  o0.w = 1;

  bool isWritingOnSwapchain = LumaData.CustomData1 != 0;
  bool isSourceScene = LumaData.CustomData2 != 0;
  // It's the last time the scene gets drawn before UI
  if (isWritingOnSwapchain && isSourceScene)
  {
    o0.rgb = linear_to_sRGB_gamma(o0.rgb, GCT_MIRROR); // Needed because the original view was a R8G8B8A8_UNORM_SRGB, with the input being float/linear, so there was an implicity sRGB encoding.
#if UI_DRAW_TYPE == 2 // This is drawn in the UI phase but it's not UI, so make sure it scales with the game brightness instead
    o0.rgb *= pow(LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits, 1.0 / DefaultGamma);
#endif
  }
}