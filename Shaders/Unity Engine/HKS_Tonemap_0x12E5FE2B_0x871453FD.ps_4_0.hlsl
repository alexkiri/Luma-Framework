#include "../Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"
#include "../Includes/Reinhard.hlsl"

Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}

#ifndef ENABLE_LUMA
#define ENABLE_LUMA 1
#endif

// Sample that allows to go beyond the 0-1 coordinates range through extrapolation.
// It finds the rate of change (acceleration) of the LUT color around the requested clamped coordinates, and guesses what color the sampling would have with the out of range coordinates.
// Extrapolating LUT by re-apply the rate of change has the benefit of consistency. If the LUT has the same color at (e.g.) uv 0.9 0.9 and 1.0 1.0, thus clipping to white or black, the extrapolation will also stay clipped.
// Additionally, if the LUT had inverted colors or highly fluctuating colors, extrapolation would work a lot better than a raw LUT out of range extraction with a luminance multiplier.
//
// This function does not acknowledge the LUT transfer function nor any specific LUT properties.
// This function allows your to pick whether you want to extrapolate diagonal, horizontal or veretical coordinates.
// Note that this function might return "invalid colors", they could have negative values etc etc, so make sure to clamp them after if you need to.
// This version is for a 2D float4 texture with a single gradient (not a 3D map reprojected in 2D with horizontal/vertical slices), but the logic applies to 3D textures too.
//
// "unclampedUV" is expected to have been remapped within the range that excludes that last half texels at the edges.
// "extrapolationDirection" 0 is both hor and ver. 1 is hor only. 2 is ver only.
float4 sampleLUTWithExtrapolation(Texture2D<float4> lut, SamplerState samplerState, float2 unclampedUV, const int extrapolationDirection = 0)
{
  // LUT size in texels
  float lutWidth;
  float lutHeight;
  lut.GetDimensions(lutWidth, lutHeight);
  const float2 lutSize = float2(lutWidth, lutHeight);
  const float2 lutMax = lutSize - 1.0;
  const float2 uvScale = lutMax / lutSize;        // Also "1-(1/lutSize)"
  const float2 uvOffset = 1.0 / (2.0 * lutSize);  // Also "(1/lutSize)/2"
  // The uv distance between the center of one texel and the next one
  const float2 lutTexelRange = 1.0 / lutMax;

  // Remap the input coords to also include the last half texels at the edges, essentually working in full 0-1 range,
  // we will re-map them out when sampling, this is essential for proper extrapolation math.
  if (lutMax.x != 0)
    unclampedUV.x = (unclampedUV.x - uvOffset.x) / uvScale.x;
  if (lutMax.y != 0)
    unclampedUV.y = (unclampedUV.y - uvOffset.y) / uvScale.y;

  const float2 clampedUV = saturate(unclampedUV);
  const float distanceFromUnclampedToClamped = length(unclampedUV - clampedUV);
  const bool uvOutOfRange = distanceFromUnclampedToClamped > FLT_MIN;  // Some threshold is needed to avoid divisions by tiny numbers

  const float4 clampedSample = lut.Sample(samplerState, (clampedUV * uvScale) + uvOffset).xyzw;  // Use "clampedUV" instead of "unclampedUV" as we don't know what kind of sampler was in use here

  if (uvOutOfRange && extrapolationDirection >= 0)
  {

    float2 centeredUV;
    // Diagonal
    if (extrapolationDirection == 0)
    {
      // Find the direction between the clamped and unclamped coordinates, flip it, and use it to determine
      // where more centered texel for extrapolation is.
      centeredUV = clampedUV - (normalize(unclampedUV - clampedUV) * (1.0 - lutTexelRange));
    }
    // Horizontal or Vertical (use Diagonal if you want both Horizontal and Vertical at the same time)
    else
    {
      const bool extrapolateHorizontalCoordinates = extrapolationDirection == 0 || extrapolationDirection == 1;
      const bool extrapolateVerticalCoordinates = extrapolationDirection == 0 || extrapolationDirection == 2;

      float2 backwardsAmount = lutTexelRange;
#if 1 // New distance to travel back of, to avoid the hue shifts that are often at the edges of LUTs. Taking two samples in two different backwards points and blending them also looks worse in this game.
      if (extrapolateHorizontalCoordinates)
        backwardsAmount.x = 0.5;
      if (extrapolateVerticalCoordinates)
        backwardsAmount.y = 0.5;
#endif

      centeredUV = float2(clampedUV.x >= 0.5 ? max(clampedUV.x - backwardsAmount.x, 0.5) : min(clampedUV.x + backwardsAmount.x, 0.5), clampedUV.y >= 0.5 ? max(clampedUV.y - backwardsAmount.y, 0.5) : min(clampedUV.y + backwardsAmount.y, 0.5));
      centeredUV = float2(extrapolateHorizontalCoordinates ? centeredUV.x : unclampedUV.x, extrapolateVerticalCoordinates ? centeredUV.y : unclampedUV.y);
    }

    const float4 centeredSample = lut.Sample(samplerState, (centeredUV * uvScale) + uvOffset).xyzw;
    // Note: if we are only doing "Horizontal" or "Vertical" extrapolation, we could replace this "length()" calculation with a simple subtraction
    const float distanceFromClampedToCentered = length(clampedUV - centeredUV);
    const float extrapolationRatio = distanceFromClampedToCentered == 0.0 ? 0.0 : (distanceFromUnclampedToClamped / distanceFromClampedToCentered);
#if 1  // Lerp in gamma space, this seems to look better for this game (the whole rendering is in gamma space, never linearized), and the "extrapolationRatio" is in gamma space too
    const float4 extrapolatedSample = lerp(centeredSample, clampedSample, 1.0 + extrapolationRatio);
#else  // Lerp in linear space to make it more "accurate"
    float4 extrapolatedSample = lerp(pow(centeredSample, 2.2), pow(clampedSample, 2.2), 1.0 + extrapolationRatio);
    extrapolatedSample = pow(abs(extrapolatedSample), 1.0 / 2.2) * sign(extrapolatedSample);
#endif
    return extrapolatedSample;
  }
  return clampedSample;
}

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 sceneColor = t0.SampleLevel(s1_s, w1.xy, 0);
  o0.w = sceneColor.a;

  float saturation = cb0[2].z;
  float brightness = cb0[2].x;
  float contrast = cb0[2].y;

  const bool vanilla = ShouldForceSDR(w1.xy, true) && LumaSettings.DisplayMode == 1;

  // The game uses a 256x4 LUT, with the horizontal axis being contrast, and each vertical line being a different color (rgb, 4th axis is unknown)
#if ENABLE_LUMA
  const bool extrapolateLUTsMethod = vanilla ? -1 : 1;
  
  float lutWidth;
  float lutHeight;
  t1.GetDimensions(lutWidth, lutHeight);
  float xScale = (lutWidth - 1.f) / lutWidth;
  float xOffset = 1.f / (2.f * lutWidth);
  if (vanilla)
  {
    xScale = 1.0;
    xOffset = 0.0;
  }

  float4 redLUT = sampleLUTWithExtrapolation(t1, s1_s, float2((sceneColor.r * xScale) + xOffset, 0.125), extrapolateLUTsMethod).rgba;
  float4 greenLUT = sampleLUTWithExtrapolation(t1, s1_s, float2((sceneColor.g * xScale) + xOffset, 0.375), extrapolateLUTsMethod).rgba;
  float4 blueLUT = sampleLUTWithExtrapolation(t1, s1_s, float2((sceneColor.b * xScale) + xOffset, 0.625), extrapolateLUTsMethod).rgba;
  float3 gradedSceneColor = float3(redLUT.r, greenLUT.g, blueLUT.b);
  float3 gradedSceneColorLinear;

  // Hues correction
  if (!vanilla)
  {
    float4 redBlackLUT = t1.Sample(s1_s, float2((0 * xScale) + xOffset, 0.125)).rgba;
    float4 greenBlackLUT = t1.Sample(s1_s, float2((0 * xScale) + xOffset, 0.375)).rgba;
    float4 blueBlackLUT = t1.Sample(s1_s, float2((0 * xScale) + xOffset, 0.625)).rgba;
    float3 gradedBlackColorLinear = gamma_to_linear(float3(redBlackLUT.r, greenBlackLUT.g, greenBlackLUT.b));

    float lutMidGreyIn = 0.75; // Customize it (bad naming)
    float4 redMidGreyLUT = t1.Sample(s1_s, float2((lutMidGreyIn * xScale) + xOffset, 0.125)).rgba;
    float4 greenMidGreyLUT = t1.Sample(s1_s, float2((lutMidGreyIn * xScale) + xOffset, 0.375)).rgba;
    float4 blueMidGreyLUT = t1.Sample(s1_s, float2((lutMidGreyIn * xScale) + xOffset, 0.625)).rgba;
    float3 gradedMidGreyColorLinear = gamma_to_linear(float3(redMidGreyLUT.r, greenMidGreyLUT.g, blueMidGreyLUT.b));

    gradedSceneColorLinear = gamma_to_linear(gradedSceneColor, GCT_MIRROR);

    // Fix potentially raised LUT floor
    float3 blackFloorFixColorLinear = gradedSceneColorLinear - (gradedBlackColorLinear * (1.0 - saturate(gradedSceneColorLinear * 10.0)));
    float3 blackFloorFixColorOklab = linear_srgb_to_oklab(blackFloorFixColorLinear);
    float3 gradedSceneColorOklab = linear_srgb_to_oklab(gradedSceneColorLinear);
    gradedSceneColorOklab.x = lerp(gradedSceneColorOklab.x, blackFloorFixColorOklab.x, 2.0 / 3.0); // Keep the hue and chrominance of the raised/tinted shadow, but restore much of the original shadow level for contrast
    gradedSceneColorLinear = oklab_to_linear_srgb(gradedSceneColorOklab);

    float minChrominanceChange = 0.8; // Mostly desaturation for now, we only want the hue shifts (e.g. turning white into yellow)
    float maxChrominanceChange = FLT_MAX; // Setting this to 1 works too, it prevents the clipped color from boosting saturation, however, that's very unlikely to happen
    float3 clippedColorOklab = linear_srgb_to_oklab(saturate(gradedSceneColorLinear));
    float hueStrength = 0.0;
    float chrominanceStrength = 0.8 * saturate(clippedColorOklab.x); // Desaturate bright colors more
    gradedSceneColorLinear = RestoreHueAndChrominance(gradedSceneColorLinear, saturate(gradedSceneColorLinear), hueStrength, chrominanceStrength, minChrominanceChange, maxChrominanceChange);
    
    // Restore the highlights color filter on new highlights, this helps avoiding turning highlights to pure white/yellow
    hueStrength = max(saturate(clippedColorOklab.x) - (2.0 / 3.0), 0.0) * 3.0 * 0.8; // Never restore hue to 100%, it messes up
    gradedSceneColorLinear = RestoreHueAndChrominance(gradedSceneColorLinear, gradedMidGreyColorLinear, hueStrength, 0.0);

    gradedSceneColor = linear_to_gamma(gradedSceneColorLinear, GCT_MIRROR);
  }
#else // !ENABLE_LUMA
  // Note: Vanilla was using a nearest neighbor sampler, which butchered detail beyond 8bit (that's why the LUT input colors (UVs) didn't the half texel offset acknowledged).
  float4 redLUT = t1.Sample(s0_s, float2(sceneColor.r, 0.125)).rgba;
  float4 greenLUT = t1.Sample(s0_s, float2(sceneColor.g, 0.375)).rgba;
  float4 blueLUT = t1.Sample(s0_s, float2(sceneColor.b, 0.625)).rgba;
  float3 gradedSceneColor = float3(redLUT.r, greenLUT.g, blueLUT.b);
#endif // ENABLE_LUMA
  float luminance = GetLuminance(gradedSceneColor); // Luma: fixed slightly wrong BT.709 luminance
  gradedSceneColor = lerp(luminance, gradedSceneColor, saturation);
#if _12E5FE2B
  gradedSceneColor *= brightness;
  gradedSceneColor = ((gradedSceneColor - 0.5) * contrast) + 0.5;
#endif

#if ENABLE_LUMA
  gradedSceneColorLinear = gamma_to_linear(gradedSceneColor, GCT_MIRROR);
#if defined(ENABLE_COLOR_GRADING) && !ENABLE_COLOR_GRADING // TODO: expose? mmm Nah
  float3 sceneColorLinear = gamma_to_linear(sceneColor.rgb, GCT_MIRROR);
  gradedSceneColorLinear = lerp(sceneColorLinear, gradedSceneColorLinear, 0.0);
#endif

  const float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
  const float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;
  if (vanilla)
  {
    gradedSceneColorLinear = saturate(gradedSceneColorLinear); // This isn't even needed really
  }
  // AutoHDR on videos
  else if (LumaData.CustomData1)
  {
    gradedSceneColorLinear = PumboAutoHDR(gradedSceneColorLinear, lerp(sRGB_WhiteLevelNits, 600.0, LumaData.CustomData3), LumaSettings.GamePaperWhiteNits);
  }
  // TODO: try Reinhard for all. it seems next to identical?
  else if (LumaSettings.DisplayMode == 1)
  {
    // The game doesn't have many bright highlights, the dynamic range is relatively low, this helps alleviate that.
    // All values found empyrically
    float normalizationPoint = 0.02;
    float fakeHDRIntensity = 0.4;
    
    float3 fakeHDRColor = FakeHDR(gradedSceneColorLinear, normalizationPoint, fakeHDRIntensity, false);
    
    // Boost saturation
    float highlightsSaturationIntensity = 0.25; // Anything more is deep fried.
    float luminanceTonemap = saturate(Reinhard::ReinhardRange(GetLuminance(gradedSceneColorLinear), 0.18, -1.0, 1.0, false).x);
    //gradedSceneColorLinear = Saturation(gradedSceneColorLinear, DVS4 * 5);
    fakeHDRColor = linear_srgb_to_oklab(fakeHDRColor);
    fakeHDRColor.yz *= lerp(1.0, max(pow(luminanceTonemap, 1.0 / 2.2) + 0.5, 1.0), highlightsSaturationIntensity); // Arbitrary formula
	  fakeHDRColor = oklab_to_linear_srgb(fakeHDRColor);
    
    gradedSceneColorLinear = lerp(gradedSceneColorLinear, fakeHDRColor, LumaData.CustomData3);

    bool perChannel = true; // There's basically no difference in this game
    DICESettings settings = DefaultDICESettings(perChannel ? DICE_TYPE_BY_CHANNEL_PQ : DICE_TYPE_BY_LUMINANCE_PQ_CORRECT_CHANNELS_BEYOND_PEAK_WHITE);
    gradedSceneColorLinear = DICETonemap(gradedSceneColorLinear * paperWhite, peakWhite, settings) / paperWhite;
  }
  else
  {
    float shoulderStart = 0.75; // High, but preserves the look of the game
    // Restore per channel chrominance on luminance TM, the vanilla SDR tonemapping is fully clipped
    float3 gradedSceneColorLinearLuminanceTM = RestoreLuminance(gradedSceneColorLinear, Reinhard::ReinhardRange(GetLuminance(gradedSceneColorLinear), shoulderStart, -1.0, peakWhite / paperWhite, false).x);
    gradedSceneColorLinear = Reinhard::ReinhardRange(gradedSceneColorLinear, shoulderStart, -1.0, peakWhite / paperWhite, false);
    gradedSceneColorLinear = RestoreHueAndChrominance(gradedSceneColorLinearLuminanceTM, gradedSceneColorLinear, 0.0, 0.8);
  }

#if UI_DRAW_TYPE == 2
  gradedSceneColorLinear *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif

  gradedSceneColor = linear_to_gamma(gradedSceneColorLinear, GCT_MIRROR);
#endif
  
  o0.xyz = gradedSceneColor;
}