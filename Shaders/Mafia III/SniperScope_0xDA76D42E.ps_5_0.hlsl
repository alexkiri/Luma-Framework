#include "Includes/Common.hlsl"
#include "../Includes/Tonemap.hlsl"
#include "../Includes/RCAS.hlsl"

Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

Texture2D<float2> dummyFloat2Texture : register(t3); // LUMA

cbuffer cb1 : register(b1)
{
  float4 cb1[11];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[1];
}

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;

  o0.w = 1;
  
  bool isWritingOnSwapchain = true; // This is always the case until proven otherwise

  r0.x = cb1[10].w / cb1[10].z;
  r0.y = cb1[10].z * 0.5;
  r1.xz = -0.5 + v1.xy;
  r1.y = r1.x * r0.x - r0.y;
  r0.xy = 1.0 / cb0[0].xy;
  r0.xy = saturate(r1.yz * r0.xy + float2(0.5,0.5));
  r1.xyz = t2.Sample(s0_s, r0.xy).xyw; // Normal map
  r0.x = t0.Sample(s0_s, r0.xy).y; // Alpha map
  r1.x = r1.x * r1.z;
  r1.xy = r1.xy * 2.0 - 1.0;
  r0.y = dot(r1.xy, r1.xy);
  r0.y = min(1, r0.y);
  r0.xy = 1.0 - r0.xy;
  r1.z = sqrt(r0.y);
  r0.y = dot(r1.xyz, r1.xyz);
  r0.y = rsqrt(r0.y);
  r0.yz = r1.xy * r0.yy;
  r0.yz = saturate(r0.yz * cb0[0].z + v1.xy);

  float alpha = r0.x;

  r0.rgb = t1.Sample(s1_s, r0.yz).rgb; // Scene

  // Do TM at the very very last
  if (isWritingOnSwapchain)
  {
#if ENABLE_SHARPENING // Note that this is possibly after film grain, but so far I haven't noticed any in the game
    float sharpenAmount = LumaSettings.GameSettings.Sharpening;
	  r0.rgb = RCAS(v0.xy, 0, 0x7FFFFFFF, sharpenAmount, t0, dummyFloat2Texture, 1.0, true, float4(r0.rgb, 1.0)).rgb;
#endif // !ENABLE_SHARPENING

#if ENABLE_LUMA
    if (LumaSettings.DisplayMode == 1)
    {
      const float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
      const float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;

#if !STRETCH_ORIGINAL_TONEMAPPER && !ENABLE_LUT_EXTRAPOLATION
      DICESettings settings = DefaultDICESettings(DICE_TYPE_BY_LUMINANCE_PQ_CORRECT_CHANNELS_BEYOND_PEAK_WHITE); // We already tonemapped by channel and restored hue/chrominance so let's not shift it anymore by tonemapping by channel
#else
      DICESettings settings = DefaultDICESettings();
#endif // !STRETCH_ORIGINAL_TONEMAPPER && !ENABLE_LUT_EXTRAPOLATION
#if 0
      settings.ShoulderStart = paperWhite / peakWhite; // Only tonemap beyond paper white, so we leave the SDR range untouched (roughly), even if we only blend in the SDR tonemapper up to mid grey, if we start earlier HDR would lose range
#endif
      r0.rgb = DICETonemap(r0.rgb * paperWhite, peakWhite, settings) / paperWhite;
    }
#endif // ENABLE_LUMA
  }

  o0.xyz = r0.rgb * alpha;

  if (isWritingOnSwapchain)
  {
#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
    ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, VANILLA_ENCODING_TYPE, GAMMA_CORRECTION_TYPE, true);
    o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
    ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, GAMMA_CORRECTION_TYPE, VANILLA_ENCODING_TYPE, true);
#endif

    o0.rgb = linear_to_sRGB_gamma(o0.rgb, GCT_MIRROR); // Needed because the original view was a R8G8B8A8_UNORM_SRGB, with the input being float/linear, so there was an implicit sRGB encoding. Following passes are UI and work with non sRGB views.
  }
}