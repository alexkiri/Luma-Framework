#include "../Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

Texture2D<float4> SourceTexture : register(t0);
#if _FA1EB89D
Texture2D<float4> InternalGradingLUT : register(t1);
#elif _A8D65F39 // Bloom
Texture2D<float4> BloomTexture : register(t1);
Texture2D<float4> InternalGradingLUT : register(t2);
#elif _DB8E089A // Bloom + Vignette
Texture2D<float4> BloomTexture : register(t1);
Texture2D<float4> VignetteTexture : register(t2);
Texture2D<float4> InternalGradingLUT : register(t3);
#endif
SamplerState sampler0 : register(s0);  // Bilinear

// The base params are the same, Bloom and Vignette shaders just add more on top
#if _FA1EB89D
cbuffer cb0 : register(b0)
{
  float4 cb0[131];
}
#elif _A8D65F39
cbuffer cb0 : register(b0)
{
  float4 cb0[143];
}
#elif _DB8E089A
cbuffer cb0 : register(b0)
{
  float4 cb0[145];
}
#endif

float3 GetSceneColor(float2 inCoords, Texture2D<float4> _texture, SamplerState _sampler)
{
  const float sampleBias = cb0[21].x; // Expected to be zero, though it could be used by the game to do a very ugly game blur effect
  return _texture.SampleBias(_sampler, inCoords.xy, sampleBias).rgb;
}

float3 ApplyBloom(float2 inCoords, float3 color, Texture2D<float4> _texture, SamplerState _sampler)
{
  const float sampleBias = cb0[21].x; // Expected to be zero, though it could be used by the game to do a very ugly game blur effect
  const float3 bloomColor = _texture.SampleBias(_sampler, inCoords.xy, sampleBias).rgb;
  const float bloomStrength = cb0[142].z; // Expected to be > 0 and < 1
  return color + (bloomColor * bloomStrength);
}

float3 ApplyExposure(float3 color)
{
  const float exposure = cb0[130].w;
  return color * exposure;
}

float3 ApplyLUT(float3 color, Texture2D<float4> _texture, SamplerState _sampler)
{
  float3 postLutColor;

  bool lutExtrapolation = true;
#if DEVELOPMENT
  lutExtrapolation = LumaSettings.DevSetting01 <= 0.5;
#endif
  if (lutExtrapolation)
  {
    LUTExtrapolationData extrapolationData = DefaultLUTExtrapolationData();
    extrapolationData.inputColor = color.rgb;
  
    LUTExtrapolationSettings extrapolationSettings = DefaultLUTExtrapolationSettings();
    extrapolationSettings.lutSize = round(1.0 / cb0[130].y);
    // Empirically found value for Prey. Anything less will be too compressed, anything more won't have a noticieable effect.
    // This helps keep the extrapolated LUT colors at bay, avoiding them being overly saturated or overly desaturated.
    // At this point, Prey can have colors with brightness beyond 35000 nits, so obviously they need compressing.
    //extrapolationSettings.inputTonemapToPeakWhiteNits = 1000.0; // Relative to "extrapolationSettings.whiteLevelNits" // NOT NEEDED UNTIL PROVEN OTHERWISE
    // Empirically found value for Prey. This helps to desaturate extrapolated colors more towards their Vanilla (HDR tonemapper but clipped) counterpart, often resulting in a more pleasing and consistent look.
    // This can sometimes look worse, but this value is balanced to avoid hue shifts.
    //extrapolationSettings.clampedLUTRestorationAmount = 1.0 / 4.0; // NOT NEEDED UNTIL PROVEN OTHERWISE
    extrapolationSettings.inputLinear = true;
    extrapolationSettings.lutInputLinear = true;
    extrapolationSettings.lutOutputLinear = true;
    extrapolationSettings.outputLinear = true;
  
    postLutColor = SampleLUTWithExtrapolation(_texture, _sampler, extrapolationData, extrapolationSettings);
  }
  else
  {
    // This code looks weird, but it is the standard 2D LUT sampling math, just done with a slightly different order for the math
    const float lutMax = cb0[130].z; // The 3D LUT max: "LUT_SIZE - 1"
    const float2 lutInvSize = cb0[130].xy; // The 3D LUT size (before unwrapping it): "1 / LUT_SIZE", likely equal in value on x and y
    const float2 lutCoordsOffset = float2(0.5, 0.5) * lutInvSize; // The uv bias: "0.5 / LUT_SIZE"
    float3 lutTempCoords3D = saturate(color) * lutMax;
    float2 lutCoords2D = (lutTempCoords3D.xy * lutInvSize) + lutCoordsOffset;
    float lutSliceIdx = floor(lutTempCoords3D.z);
    // Offset the horizontal axis by the index of z (blue) slice
    lutCoords2D.x += lutSliceIdx * lutInvSize.y;
    float lutSliceFrac = lutTempCoords3D.z - lutSliceIdx;
    float3 lutColor1 = _texture.SampleLevel(_sampler, lutCoords2D, 0).rgb;
    // Sample the next slice
    float3 lutColor2 = _texture.SampleLevel(_sampler, lutCoords2D + float2(lutInvSize.y, 0), 0).rgb;
    // Blend the two slices with the z (blue) ratio
    postLutColor = lerp(lutColor1, lutColor2, lutSliceFrac);
    
    float hueRestoration = 0.0;
    bool restorePostProcessInBT2020 = true;
#if DEVELOPMENT
    hueRestoration = LumaSettings.DevSetting02;
    restorePostProcessInBT2020 = LumaSettings.DevSetting03 <= 0.5;
#endif
    postLutColor = RestorePostProcess(color, saturate(color), postLutColor, hueRestoration, restorePostProcessInBT2020);
  }
  
  return postLutColor;
}

float3 Tonemap(float3 color)
{
  DICESettings config = DefaultDICESettings();
  config.Type = DICE_TYPE_BY_CHANNEL_PQ; // Do DICE by channel to desaturate highlights and keep the SDR range unotuched
  float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;
  float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
#if 0 // Test: make PQ tonemapping indepdenent from the user paper white (the result seems about identical if we start the shoulder from paper white), this isn't what the design intended
  peakWhite /= paperWhite;
  paperWhite = 1.0;
#endif
  config.ShoulderStart = paperWhite / peakWhite; // Start tonemapping beyond paper white, so we leave the SDR range untouched (roughly, given that this tonemaps in BT.2020)
  return DICETonemap(color * paperWhite, peakWhite, config) / paperWhite;
}

float3 ApplyVignette(float2 inCoords, float3 color, Texture2D<float4> _texture, SamplerState _sampler)
{
  const float sampleBias = cb0[21].x; // Expected to be zero, though it could be used by the game to do a very ugly game blur effect
  float4 vignette;
  vignette.rgba = _texture.SampleBias(_sampler, inCoords.xy, sampleBias).rgba;
  vignette.rgb = vignette.rgb * cb0[144].rgb + -color.rgb;
  float alpha = cb0[144].w * vignette.a;
  return color.rgb + vignette.rgb * alpha;
}

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 outColor : SV_Target0)
{
  const float2 inCoords = v1.xy;

  float3 color;
  color = GetSceneColor(inCoords, SourceTexture, sampler0);
#if _A8D65F39 || _DB8E089A
  color = ApplyBloom(inCoords, color, BloomTexture, sampler0);
#endif
  color = ApplyExposure(color);
  color = ApplyLUT(color, InternalGradingLUT, sampler0);
  color = Tonemap(color); // Added by Luma. the game was just clipping
#if _DB8E089A
  color = ApplyVignette(inCoords, color, VignetteTexture, sampler0);
#endif

#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  color.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif

  outColor = float4(color.rgb, 1.0);
}