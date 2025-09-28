#include "Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"
#include "../Includes/Reinhard.hlsl"

cbuffer DrawableBuffer : register(b1)
{
  float4 FogColor : packoffset(c0);
  float4 DebugColor : packoffset(c1);
  float MaterialOpacity : packoffset(c2);
  float AlphaThreshold : packoffset(c3);
}

cbuffer SceneBuffer : register(b2)
{
  row_major float4x4 View : packoffset(c0);
  row_major float4x4 ScreenMatrix : packoffset(c4);
  float2 DepthExportScale : packoffset(c8);
  float2 FogScaleOffset : packoffset(c9);
  float3 CameraPosition : packoffset(c10);
  float3 CameraDirection : packoffset(c11);
  float3 DepthFactors : packoffset(c12);
  float2 ShadowDepthBias : packoffset(c13);
  float4 SubframeViewport : packoffset(c14);
  row_major float3x4 DepthToWorld : packoffset(c15);
  float4 DepthToView : packoffset(c18);
  float4 OneOverDepthToView : packoffset(c19);
  float4 DepthToW : packoffset(c20);
  float4 ClipPlane : packoffset(c21);
  float2 ViewportDepthScaleOffset : packoffset(c22);
  float2 ColorDOFDepthScaleOffset : packoffset(c23);
  float2 TimeVector : packoffset(c24);
  float3 HeightFogParams : packoffset(c25);
  float3 GlobalAmbient : packoffset(c26);
  float4 GlobalParams[16] : packoffset(c27);
  float DX3_SSAOScale : packoffset(c43);
  float4 ScreenExtents : packoffset(c44);
  float2 ScreenResolution : packoffset(c45);
  float4 PSSMToMap1Lin : packoffset(c46);
  float4 PSSMToMap1Const : packoffset(c47);
  float4 PSSMToMap2Lin : packoffset(c48);
  float4 PSSMToMap2Const : packoffset(c49);
  float4 PSSMToMap3Lin : packoffset(c50);
  float4 PSSMToMap3Const : packoffset(c51);
  float4 PSSMDistances : packoffset(c52);
  row_major float4x4 WorldToPSSM0 : packoffset(c53);
}

cbuffer InstanceBuffer : register(b5)
{
  float4 InstanceParams[8] : packoffset(c0);
}

SamplerState p_default_Material_0C25AF6416088781_Param_sampler_s : register(s0);
Texture2D<float4> p_default_Material_0C25AF6416088781_Param_texture : register(t0);

#ifndef ENABLE_IMPROVED_COLOR_GRADING
#define ENABLE_IMPROVED_COLOR_GRADING 1
#endif
#ifndef ENABLE_VIGNETTE
#define ENABLE_VIGNETTE 1
#endif
// Undefined it as this used to be exposed to users but we've moved it to a cbuffer now
#ifdef ENABLE_COLOR_GRADING_DESATURATION
#undef ENABLE_COLOR_GRADING_DESATURATION
#endif
#ifndef ENABLE_COLOR_GRADING_DESATURATION
#define ENABLE_COLOR_GRADING_DESATURATION 1
#endif

// This is from the original game, or the golder filter restoration mod. The DC edition doesn't run it be default.
void main(
  float4 v0 : SV_POSITION0,
  out float4 o0 : SV_Target0)
{
  float2 uv = v0.xy * ScreenExtents.zw + ScreenExtents.xy;
  float3 color = p_default_Material_0C25AF6416088781_Param_texture.Sample(p_default_Material_0C25AF6416088781_Param_sampler_s, uv).rgb;
  bool isLinear = false; // The game was drawing all in gamma space
#if ENABLE_IMPROVED_COLOR_GRADING
  color = gamma_to_linear(color, GCT_MIRROR);
  isLinear = true;
#endif

  float saturationAmount = InstanceParams[0].y; // <1 is desaturation, >1 is saturation
  saturationAmount = lerp(max(saturationAmount, 1.0), saturationAmount, LumaSettings.GameSettings.DesaturationIntensity);
  float rgbAverage = (color.r + color.g + color.b) / 3.0;
#if ENABLE_IMPROVED_COLOR_GRADING

  // Apply desaturation in linear space and base the rgb average on linear colors instead of gamma space colors.
  // To preserve the grading look, it's important to keep the rgb average instead of swapping it with the luminance.
  float rgbAverageGammaSpace = linear_to_gamma1(max(rgbAverage, 0.0));
#if ENABLE_COLOR_GRADING_DESATURATION
  float luminance = GetLuminance(color);
  float luminanceGammaSpace = linear_to_gamma1(max(luminance, 0.0));
#if 1
  saturationAmount = lerp(saturationAmount, pow(saturationAmount, 1.0 / DefaultGamma), saturate(luminanceGammaSpace)); // Desaturate less in highlights, when working in linear space, to emulate the gamma space desaturation behaviour
#elif 1 // This makes it look worse, even if it should be more correct
  saturationAmount = lerp(pow(saturationAmount, 1.0 / DefaultGamma), saturationAmount, saturate(luminanceGammaSpace)); // Desaturate more in the shadow when working in linear space, to emulate the gamma space desaturation behaviour
#endif
  color = lerp(luminance, color, saturationAmount);
#endif // ENABLE_COLOR_GRADING_DESATURATION

#else // !ENABLE_IMPROVED_COLOR_GRADING

  float rgbAverageGammaSpace = rgbAverage;
#if ENABLE_COLOR_GRADING_DESATURATION
  // Note: this can generate colors with invalid luminances (too low negative values), and also crush shadow.
  // However, it might have expanded saturation in shadow, which could have arguably looked good.
  color -= rgbAverage;
  color *= saturationAmount;
  color += rgbAverage;
#endif // ENABLE_COLOR_GRADING_DESATURATION

#endif // ENABLE_IMPROVED_COLOR_GRADING

  bool forceSDR = ShouldForceSDR(uv, true);

  float scaledAverage = saturate(InstanceParams[0].z * rgbAverageGammaSpace); // We still need to saturate, otherwise the highlights filter would apply too strongly (it will apply stronger than SDR anyway, as the source colors are beyond 1)
  float shadowAmount = -scaledAverage * 2.0 + 1.0; // Maps 1 to -1, 0.5 to 0 and 0 to 1
  float highlightAmount = scaledAverage * 2.0 - 1.0; // Maps 1 to 1, 0.5 to 0 and 0 to -1
  float midtonesAmount = 1.0 - abs(highlightAmount); // Maps (the original value) 1 to 0, 0.5 to 1 and 0 to 0
  shadowAmount = max(0.0, shadowAmount); // Ignore original values beyond 0.5, the max will be 1
  highlightAmount = max(0.0, highlightAmount); // Ignore original values below 0.5, the max will be 1
  // The following rgb param filters are meant to be within 0-1 to keep the filter within 0-1 (it's important it doesn't go below 0)
  float3 finalFilter = InstanceParams[2].xyz * midtonesAmount;
  finalFilter += InstanceParams[1].xyz * shadowAmount;
  finalFilter += InstanceParams[3].xyz * highlightAmount;
  finalFilter = (2.0 * finalFilter) - 1.0; // From 0|1 to -1|1
  finalFilter = (InstanceParams[0].x * finalFilter) + 1.0; // Back to >= 0 range (scaled by the grading intensity)
#if ENABLE_IMPROVED_COLOR_GRADING
  // Color filter (e.g. golden)
  if (!isLinear)
  {
    color = gamma_to_linear(color, GCT_MIRROR);
    isLinear = true;
  }
  // "pow(pow(x, gamma) * pow(y, gamma), 1.0 / gamma)" is equal to "x * y", so we should only do it if we want to preserve the exact original behaviour
  finalFilter = gamma_to_linear(finalFilter);
  
  // Do the main color filter in BT.2020 to generate more HDR colors
  if (LumaSettings.DisplayMode == 1 && !forceSDR)
  {
    finalFilter = BT709_To_BT2020(finalFilter);
    color = BT709_To_BT2020(color);
  }

  color = (color >= 0.0 || abs(finalFilter) <= FLT_EPSILON) ? (color * finalFilter) : (color / finalFilter); // Scale negative colors with the inverse value

  if (LumaSettings.DisplayMode == 1 && !forceSDR)
  {
    color = BT2020_To_BT709(color);
  }

#else // !ENABLE_IMPROVED_COLOR_GRADING
  color *= finalFilter;
#endif // ENABLE_IMPROVED_COLOR_GRADING

#if ENABLE_VIGNETTE
  float2 ndc = uv * 2.0 - 1.0;
  float2 scaledNDC = InstanceParams[4].zw * ndc;
  float centerDistance = dot(scaledNDC, scaledNDC);
  centerDistance = pow(centerDistance, InstanceParams[4].x);
  centerDistance = min(1, centerDistance);
  float vignette = 1.0 - (centerDistance * InstanceParams[4].y);
  color *= isLinear ? gamma_to_linear1(vignette) : vignette;
#endif // ENABLE_VIGNETTE

  o0.rgb = color;
  o0.a = MaterialOpacity; // Unused

#if 1 // Luma
  if (!isLinear)
  {
    o0.rgb = gamma_to_linear(o0.rgb, GCT_MIRROR);
    isLinear = true;
  }

#if ENABLE_COLOR_GRADING_DESATURATION && 0 // Theoretically it's another setting, but whatever // Disabled for now as it just doesn't look right, the game relies on saturated highlights for many things
  // Desaturate bright highlights as they can get ridiculously high and still be very saturated in this game, while in SDR it would have all clipped at 1
  // TODO: try with oklab or something else, and maybe restore the vanilla hue, however it's very much lost at this point as many saturates were skipped
  o0.rgb = Saturation(o0.rgb, lerp(1.0, 0.5, pow(saturate((average(o0.rgb) - MidGray) / 20.0), 0.5)));
#endif
  
  if (!forceSDR)
  {
    const float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
    const float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;
    if (LumaSettings.DisplayMode == 1)
    {
      DICESettings settings = DefaultDICESettings(DICE_TYPE_BY_LUMINANCE_PQ_CORRECT_CHANNELS_BEYOND_PEAK_WHITE); // The game simply clipped all values beyond 1, many times across rendering, but anyway it doesn't seem to rely on hue shifts so tonemapping by luminance is the best
#if 0
      settings.ShoulderStart = paperWhite / peakWhite; // Only tonemap beyond paper white, so we leave the SDR range untouched (roughly)
#endif
      o0.rgb = DICETonemap(o0.rgb * paperWhite, peakWhite, settings) / paperWhite;
    }
    else // Per channel doesn't look good in this game
    {
      o0.rgb = RestoreLuminance(o0.rgb, Reinhard::ReinhardRange(GetLuminance(o0.rgb), MidGray, -1.0, peakWhite / paperWhite, false).x, true);
      o0.rgb = CorrectOutOfRangeColor(o0.rgb, true, true, 0.5, 0.5, peakWhite / paperWhite); // TM by luminance generates out of gamut colors (beyond 1), so recompress them
    }
  }
  
#if UI_DRAW_TYPE == 2
  o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif // UI_DRAW_TYPE == 2

  o0.rgb = linear_to_gamma(o0.rgb, GCT_MIRROR);
#endif
}