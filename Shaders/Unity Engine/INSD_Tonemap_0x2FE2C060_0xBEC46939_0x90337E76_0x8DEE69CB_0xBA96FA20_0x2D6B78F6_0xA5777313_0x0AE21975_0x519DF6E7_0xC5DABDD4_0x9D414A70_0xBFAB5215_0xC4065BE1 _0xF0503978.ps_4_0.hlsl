#include "../Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

#if !defined(ENABLE_FILM_GRAIN)
#define ENABLE_FILM_GRAIN 1
#endif

#if !defined(ENABLE_LENS_DISTORTION)
#define ENABLE_LENS_DISTORTION 1
#endif

#if !defined(ENABLE_CHROMATIC_ABERRATION)
#define ENABLE_CHROMATIC_ABERRATION 1
#endif

#if !defined(ENABLE_FAKE_HDR)
#define ENABLE_FAKE_HDR 0
#endif

#if !defined(ENABLE_LUMA)
#define ENABLE_LUMA 1
#endif

Texture2D<float4> bloomTexture : register(t4); // Very blurred
Texture2D<float4> sceneTexture : register(t3); // TAA'd
Texture2D<float4> colorFilterTexture : register(t2); // RGB color palette/filter. 3x2
Texture2D<float4> noiseTexture : register(t1); // 256x256
Texture2D<float4> lensDistortionAndChromaticAberrationTexture : register(t0); // Matches your aspect ratio at its lower resolution (e.g. 16x9, 32x9), given it's generated in the previous pass

SamplerState s4_s : register(s4);
SamplerState s3_s : register(s3);
SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

// Shader permutations:
// 0x2FE2C060 - Default gameplay
// 0xBEC46939 - Default gameplay but user lowered brightness
// 0x90337E76 - Default gameplay but during menu change resolution view
// 0x8DEE69CB - Default gameplay but user lowered brightness and during menu change resolution view
// 0xBA96FA20 - Rare scene with extra color filter
// 0x2D6B78F6 - Rare scene with extra color filter but user lowered brightness
// 0xA5777313 - Rare scene with extra color filter but during menu change resolution view
// 0x0AE21975 - Rare scene with extra color filter but user lowered brightness and during menu change resolution view
// 0x519DF6E7 - Water gameplay (does chromatic aborration differently, they also have the extra color filter)
// 0xC5DABDD4 - Water gameplay but user lowered brightness
// 0x9D414A70 - Water gameplay but during menu change resolution view
// 0xBFAB5215 - Water gameplay but user lowered brightness and during menu change resolution view
// 0xC4065BE1 - Death (game can't be paused during death)
// 0xF0503978 - Death but user lowered brightness
// 
// TODO: play the whole game to get all permutations, e.g. death in water, or water without color filter etc
// (e.g. search for "0x7ef311c3", there seems to be 64 in total, so 8 base setings, there's a copy of each shader without lens distortion (and thus chromatic aberration))
// TODO: make sure that with our settings disabled, it looks identical to vanilla (e.g. try the trailer scene with the guys looking at the curved window)

cbuffer cb0 : register(b0)
{
#if _BA96FA20 || _519DF6E7 || _2D6B78F6 || _0AE21975 || _C5DABDD4 || _BFAB5215 || _9D414A70 || _A5777313
  float4 cb0[14];
#elif _90337E76 || _8DEE69CB || _C4065BE1 || _F0503978
  float4 cb0[13];
#elif _2FE2C060 || _BEC46939
  float4 cb0[12];
#endif
}

float3 Quake_rsqrt(float3 number)
{
    int3 i = asint(number);                  // reinterpret float bits as int
    i = 0x5F375A86 - (i >> 1);               // the magic number bit hack (in Quake it was 0x5F3759DF)
    float3 y = asfloat(i);                   // reinterpret back to float
    y = y * (1.5f - 0.5f * number * y * y);  // 1 Newton-Raphson iteration
    return y;
}

float GetSceneWeightFromAlpha(float sceneColorAlpha)
{
  float sceneWeight = saturate(sceneColorAlpha); // Luma: add saturate on alpha just to make sure texture upgrades didn't make the value go beyond 0-1
  sceneWeight += 0.629960537;
  sceneWeight *= sceneWeight;
  sceneWeight *= sceneWeight;
  sceneWeight += 0.842509866;
  return sceneWeight;
}

float3 AdjustBloom(float3 bloomColor)
{
#if ENABLE_LUMA
  return sqr_mirrored(bloomColor); // Luma: added mirroring to preserve scRGB colors
#else // !ENABLE_LUMA
  return sqr(bloomColor);
#endif // ENABLE_LUMA
}

// Quick test to enable/disable Luma changes
float3 OptionalSaturate(float3 x)
{
#if ENABLE_LUMA
  return x;
#else // !ENABLE_LUMA
  return saturate(x);
#endif // ENABLE_LUMA
}

// Cubic polynomial
float3 ApplyCustomCurve(float3 color, float levelMultiplication, float levelAdditive, float4 polynomialParams)
{
  // Params:
  // x: highlights intensity  (directly proportional) (can be 0, and defaults to it, changes if the user changes the brightness)
  // y: midtones and highlights intensity (directly proportional) (can be 0, and defaults to it, changes if the user changes the brightness)
  // z: subtractive color (higher means darker, on the whole range, similar to pow) (best left untouched, it cold crush and clip blacks if changed)
  // w: additive color (higher means brighter, usually 0)
  // levelAdditive: raises blacks a bit, but if set to 0, it can crush them, so it's likely compensated by the other params (e.g. z and "levelAdditive"?).
  
#if ENABLE_LUMA && DEVELOPMENT && 0 // TODO: play the whole game making sure these params are always 0, so that the mod can reliably change them (it should work anyway!)? These are changed by the user brightness setting, so it's ok!
  if (polynomialParams.x != 0.0 || polynomialParams.y != 0.0)
  {
    return float3(1.0, 0.0, 1.0);
  }
#endif

#if ENABLE_LUMA && 1
  // Changing these will automatically output images in the HDR range!
  if (LumaSettings.DisplayMode == 1) // HDR mode, leave SDR as it was
  {
    // TODO: further raise highlights if our peak is beyond 1000 nits?
    polynomialParams.x += 1.0; // Raise highlights (we could afford to go a bit higher too, but it looks too much in some scenes, AutoHDR like)
    polynomialParams.y += 1.0; // Raise midtones and highlights
  }
#elif DEVELOPMENT && 0
  polynomialParams.x += LumaSettings.DevSetting06 * 2.0;
  polynomialParams.y += LumaSettings.DevSetting07 * 2.0;
#elif DEVELOPMENT && 0
  levelMultiplication *= 1.0 - LumaSettings.DevSetting04;
  levelAdditive *= 1.0 - LumaSettings.DevSetting05;
  polynomialParams.x *= 1.0 - LumaSettings.DevSetting06;
  polynomialParams.y *= 1.0 - LumaSettings.DevSetting07;
  polynomialParams.z *= 1.0 - LumaSettings.DevSetting08;
  polynomialParams.w *= 1.0 - LumaSettings.DevSetting09;
#endif

  float3 c1 = OptionalSaturate(color * levelMultiplication + levelAdditive); // Multiply and add (first) // Luma: removed saturate

#if _BA96FA20 || _519DF6E7 || _9D414A70 || _BFAB5215 || _C5DABDD4 || _0AE21975 || _2D6B78F6 || _A5777313 // These shader permutations have more parameters, it's seemengly some color filter
  // TODO: expose the cbs as func params
  float3 scaledC = cb0[3].rgb * c1;
  float2 rg_rb = scaledC.rr + scaledC.gb;
  float filterOffset = (c1.b * cb0[3].b) + rg_rb.x + (sqrt(scaledC.g * rg_rb.y) * 2.0 * cb0[3].w);
  c1 -= filterOffset;
  c1 *= cb0[13].x;
  c1 += filterOffset;
#endif

  float3 c2 = (c1 * polynomialParams.x) + polynomialParams.y; // Multiply and add (second)

  float3 c3 = (c1 * c2) + polynomialParams.z;

  return (c1 * c3) + polynomialParams.w;
}

// Applies bloom and some minor color filtering, and lens distortion
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0, // TODO: very the signature is right (it should be!)
  nointerpolation float4 v2 : TEXCOORD1,
#if _8DEE69CB || _BEC46939 || _C5DABDD4 || _BFAB5215 || _0AE21975 || _2D6B78F6 || _F0503978
  nointerpolation float2 v3 : TEXCOORD2,
#else
  nointerpolation float3 v3 : TEXCOORD2,
#endif
  out float4 outColor : SV_Target0)
{
  outColor.w = 1;

  const float fadeToWhite = cb0[11].x; // White at 1
  const float colorFilterIntensity = cb0[6].z; // Neutral (unfiltered) at 0. Color filtering isn't always used
  const float blackFloor = cb0[10].x * DVS2; // TODO: clear
  const float colorPow = cb0[10].z;
#if _8DEE69CB || _BEC46939 || _C5DABDD4 || _BFAB5215 || _0AE21975 || _2D6B78F6 || _F0503978
  const float fadeToBlackOrVignetteOrUserBrightness = 1.0; // TODO: rename
#else
  // Black at 0 (could also be vignette (exclusively based on the horizontal axis), though that's not used (at least not in every scene))
  // Update: this is likely to be the user brightness (if the brightness is >= default), as it's not in the shader if the user lowers the brightness
  const float fadeToBlackOrVignetteOrUserBrightness = v3.z;
#endif
	float screenWidth, screenHeight;
	sceneTexture.GetDimensions(screenWidth, screenHeight);

  // Start from the "center"
  const int numIterations = 8;
  const float uvStep = 1.0 / float(numIterations);

  const float lensDistortionScale = 42.5; // Probably a manually picked constant, not the size of the texture, the same variable is found in the generation shader.
  float4 lensDistortionAndChromaticAberration = lensDistortionAndChromaticAberrationTexture.SampleLevel(s4_s, v1.xy, 0).xyzw;
  float2 lensDistortion = (lensDistortionAndChromaticAberration.xy / lensDistortionScale) - (0.5 / lensDistortionScale); // Outwards lens distortion. Neutral at 0.
  float2 chromaticAberration = (lensDistortionAndChromaticAberration.zw * (0.5 / lensDistortionScale)) - (0.25 / lensDistortionScale); // Chromatic aberration + inwards lens distortion. Neutral at 0.
#if !ENABLE_LENS_DISTORTION
  lensDistortion = 0;
#elif ENABLE_LUMA // Fix lens distortion being stronger on the sides for Ultrawide
  const float sourceAspectRatio = screenWidth / screenHeight; // Not exactly the size of the screen, but of the current viewport anyway (at least the source one, this texture might add black bars, but probably doesn't, they are added later if the screen aspect ratio is different from the render resolution)
  const float originalAspectRatio = 16.0 / 9.0;
  float2 ndc = (v1 - 0.5) * 2.0;
  float aspectRatiosRatio = sourceAspectRatio / originalAspectRatio;
  float lensDistortionHorizontalPow = 0.666; // Manually found value to match UW lens distortion with the 16:9 look
  lensDistortion.x = pow(abs(lensDistortion.x), pow(lerp(1.0, aspectRatiosRatio, sqr(abs(ndc.x))), lensDistortionHorizontalPow)) * sign(lensDistortion.x);
#endif
#if !ENABLE_CHROMATIC_ABERRATION
  chromaticAberration = 0;
#endif

  const float2 noiseRandomOffset = cb0[9].yz; // Slides it across the screen (it's too fast at high frame rates... noise becomes hard to see)
  const float2 noiseTextureInvSize = cb0[8].xy; // 256x256
  float2 noiseUV = v0.xy + noiseRandomOffset; // This is per pixel and is properly scaled by screen aspect ratio
  noiseUV *= noiseTextureInvSize;
#if ENABLE_LUMA // Fix grain being near invisible at 4k, set it to 1080, the most common resolution of when the game shipped
  noiseUV *= 1080.0 / screenHeight;
#endif // ENABLE_LUMA
  float4 noise = noiseTexture.SampleLevel(s3_s, noiseUV, 0).rgba;

#if ENABLE_FILM_GRAIN
#if ENABLE_LUMA // Fixed film grain raising blacks (see "blackFloorScale" above if you change this)
  noise.rgb = noise.rgb * 4.0 - 2.0;
  noise.rgb *= 5.0 / 4.0; // Slightly increase the intensity to kinda match the previous range
#else // !ENABLE_LUMA
  noise.rgb = noise.rgb * 5.0 - 2.0; // Not exactly centered, this raises blacks!
#endif // ENABLE_LUMA
  noise.rgb /= 219.0; // Random scale that probably looked good
#else // !ENABLE_FILM_GRAIN
  noise.rgb = 0.0;
#endif // ENABLE_FILM_GRAIN

  // The palette starting shift (between 0 and 1 (or more)) determines what color we shift towards
  float colorPaletteShift = 0.5;
#if _519DF6E7 || _C5DABDD4 || _9D414A70 || _BFAB5215 // Water permutations
  colorPaletteShift = noise.a;
#endif

  float2 currentSceneUV = v1.xy + lensDistortion;
  currentSceneUV += chromaticAberration * uvStep * colorPaletteShift;
  float2 currentColorPaletteUV = float2(uvStep * colorPaletteShift, 0.5); // This will do all horizontal samples from 0.0625 to 0.9375, as if the texture had an orizontal size 0f 8, though it doesn't, but it's fine anyway (8 is our horizontal iterations)

  // First iteration
  float3 centralColorFilter = colorFilterTexture.SampleLevel(s1_s, currentColorPaletteUV, 0).rgb;
  centralColorFilter = lerp(1.0, centralColorFilter, colorFilterIntensity);
  float4 centralSceneColor = sceneTexture.Sample(s0_s, currentSceneUV).rgba;
#if 0 // Test: passthrough color (a lot dimmer!)
  outColor = centralSceneColor; return;
#endif
  centralSceneColor.rgb *= GetSceneWeightFromAlpha(centralSceneColor.a);
  float3 centralBloomColor = bloomTexture.Sample(s2_s, currentSceneUV).rgb;
  centralBloomColor = AdjustBloom(centralBloomColor);

  float3 sceneColor = centralSceneColor.rgb * centralColorFilter;
  float3 bloomColor = centralBloomColor * centralColorFilter;
  float3 colorFilter = centralColorFilter;

  // Other 7 iterations.
  // This does some blurring and chromatic aberration.
  for (int i = 1; i < numIterations; i++)
  {
    currentColorPaletteUV.x += uvStep;
    currentSceneUV += chromaticAberration * uvStep;

    float3 currentColorFilter = colorFilterTexture.SampleLevel(s1_s, currentColorPaletteUV, 0).rgb;
    currentColorFilter = lerp(1.0, currentColorFilter, colorFilterIntensity);
    colorFilter += currentColorFilter;

    float4 currentSceneColor = sceneTexture.Sample(s0_s, currentSceneUV).rgba;
    currentSceneColor.rgb *= GetSceneWeightFromAlpha(currentSceneColor.a);
    sceneColor += currentSceneColor.rgb * currentColorFilter;
    
    float3 currentBloomColor = bloomTexture.Sample(s2_s, currentSceneUV).rgb;
    currentBloomColor = AdjustBloom(currentBloomColor);
    bloomColor += currentBloomColor * currentColorFilter;
  }
#if 0 // Test: passthrough color (a lot dimmer)
  outColor.rgb = sceneColor / float(numIterations); return;
#endif

  float3 finalColorFilter = 1.0 / numIterations;
#if 1 // Some kind of hacky performance optimization (pow/sqrt like) to do brightness scaling... The image is overly dark without it
  int3 r0i = 0x7ef311c3 - asint(colorFilter);
  float3 hackyMathResult = 2.0 - (asfloat(r0i) * colorFilter);
  finalColorFilter = hackyMathResult * asfloat(r0i);
#endif

  float3 scaledSceneColor = OptionalSaturate(sceneColor * finalColorFilter); // Luma: removed saturate
  float3 scaledBloomColor = OptionalSaturate(bloomColor * finalColorFilter); // Luma: removed saturate
  float3 invertedScaledSceneColor = 1.0 - scaledSceneColor;
  float3 invertedScaledBloomColor = 1.0 - scaledBloomColor;
  // Compose bloom
#if ENABLE_LUMA // Luma: added abs*sign to preserve negative colors, though we can't restore two signs or we'd turn positive again, so we only restore the primary one for now (ideally we'd find the influence of each of the two and pick an average of the two signs? Or do this in a wider color space, but the bloom here is so blurred that it has little influence)
  float3 invertedScaledComposedColor = abs(invertedScaledBloomColor) * abs(invertedScaledSceneColor) * sign(invertedScaledSceneColor); // TODO: make sure that restoring only one of the original signs here makes sense, as in case only one of the two was negative, it might create a step in colors? It's fine!
#else // !ENABLE_LUMA
  float3 invertedScaledComposedColor = invertedScaledBloomColor * invertedScaledSceneColor; 
#endif // ENABLE_LUMA
  float3 scaledComposedColor = 1.0 - invertedScaledComposedColor;

#if ENABLE_LUMA && 1 // Luma: replace the clipped min black + black crush, with a lerp to black, given it killed black detail (this lowers brightness usually)
  const float blackFloorScale = 2.0; // Empyrically found value that keeps the blacks level roughly the same without clipping it (note that this is calibrated to also match the original black level with the additive film grain). Values like 5 would be a better match in some scenes, but they'd completely destroy other scenes.
  scaledComposedColor = lerp(0.0, scaledComposedColor, blackFloor == 0.0 ? 1.0 : sqr(saturate(scaledComposedColor / (blackFloor * blackFloorScale))));
#else // !ENABLE_LUMA
  scaledComposedColor = max(blackFloor, scaledComposedColor) - blackFloor;
#endif // ENABLE_LUMA
  scaledComposedColor /= cb0[10].y - blackFloor; // Raises brightness usually
#if ENABLE_LUMA // Luma: added abs*sign to preserve negative colors (the alternaitve would have caused NaNs in SDR too anyway)
  scaledComposedColor = pow(abs(scaledComposedColor), colorPow) * sign(scaledComposedColor); // Lowers brightness usually
#else
  scaledComposedColor = pow(scaledComposedColor, colorPow); // Lowers brightness usually
#endif
  scaledComposedColor = lerp(scaledComposedColor, 1.0, fadeToWhite); // Raises brightness usually
  
#if 1 // Some kind of brightness scaling... It adds a lot of contrast and flattens highlights
  float3 someColor1 = 1.0 - scaledComposedColor;

#if ENABLE_LUMA && 0 // Luma: high quality version, plus mirroring to support scRGB colors. This looks quite different
  float3 someColor2 = sqr_mirrored(someColor1) + (0.2 * cb0[10].w); // Luma: added mirroring to preserve scRGB colors
  float3 sqrtColor = sqrt(abs(someColor2)) * sign(someColor2);
  someColor1 -= safeDivision(someColor2, sqrtColor, 0);
#elif ENABLE_LUMA // Luma: Conserve the hacky optimized square root, but make it work in scRGB
  float3 someColor2 = sqr(max(someColor1, 0.0)) + (0.2 * cb0[10].w);
  float3 invSqrtColor = Quake_rsqrt(someColor2);
  someColor1 -= someColor2 * invSqrtColor;
#else // !ENABLE_LUMA
  float3 someColor2 = sqr(someColor1) + (0.2 * cb0[10].w);
  float3 invSqrtColor = Quake_rsqrt(someColor2);
  someColor1 -= someColor2 * invSqrtColor;
#endif // ENABLE_LUMA

  scaledComposedColor += someColor1 * 0.5;
#endif

  // The main tonemapping (it seemengly darkens the game usually)
#if ENABLE_LUMA // Luma: added support for scRGB (negative colors), though given that the curve might not return 0 for 0, and thus already shift the sign, we need to carefully work around that
  const float3 zeroShift = ApplyCustomCurve(0.0, v3.y, v3.x, v2); //TODO: run in BT.2020?
  float3 scaledComposedColorSigns = sign(scaledComposedColor);
  scaledComposedColor = ApplyCustomCurve(abs(scaledComposedColor), v3.y, v3.x, v2);
  scaledComposedColor -= zeroShift;
  scaledComposedColor *= scaledComposedColorSigns;
  scaledComposedColor += zeroShift;
#else
  scaledComposedColor = ApplyCustomCurve(scaledComposedColor, v3.y, v3.x, v2);
#endif

  float3 otherFilter = 1.0;
#if _90337E76 || _8DEE69CB || _0AE21975 || _9D414A70 || _BFAB5215 || _A5777313
  float barsColor = (v1.y > cb0[12].w) ? cb0[12].y : cb0[12].z;
  otherFilter = (1.0 - barsColor) * float3(0.0980392173, 0.121568628, 0.141176477) + barsColor;
#endif

  outColor.rgb = (scaledComposedColor * fadeToBlackOrVignetteOrUserBrightness * otherFilter) + noise.rgb;

#if ENABLE_LUMA // Luma: HDR display mapping and UI etc
  outColor.rgb = gamma_to_linear(outColor.rgb, GCT_MIRROR);

#if ENABLE_FAKE_HDR // Not really needed anymore after tweaking the tonemapper
  float normalizationPoint = 0.25; // Found empyrically
  float fakeHDRIntensity = 0.5;
  bool boostSaturation = false;
#if 0 // TODO: delete
  normalizationPoint = LumaSettings.DevSetting01;
  fakeHDRIntensity =  LumaSettings.DevSetting02;
  boostSaturation =  LumaSettings.DevSetting03 > 0.5;
#endif
  outColor.rgb = FakeHDR(outColor.rgb, normalizationPoint, fakeHDRIntensity, boostSaturation);
#endif

  const float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
  const float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;

  DICESettings settings = DefaultDICESettings();
#if 0 // Since we boosted the SDR tonemapper to produce an HDR image, we can benefit from extra desaturation as it increases it a bit too much for the mood of the game
  settings.Type = DICE_TYPE_BY_LUMINANCE_PQ_CORRECT_CHANNELS_BEYOND_PEAK_WHITE; // There's not much HDR range in this game so don't add extra hue shifts with tonemapping by channel
#endif
  settings.ShoulderStart = paperWhite / peakWhite; // Only tonemap beyond paper white, so we leave the SDR range untouched (roughly)
  outColor.rgb = DICETonemap(outColor.rgb * paperWhite, peakWhite, settings) / paperWhite;

#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  outColor.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif

  outColor.rgb = linear_to_gamma(outColor.rgb, GCT_MIRROR);
#endif // ENABLE_LUMA

#if _C4065BE1 || _F0503978 // Death permutations
  // Darken screen, or anyway fade to black. For consistency, we do this after the HDR tonemapping.
  outColor.rgb *= cb0[12].x;
#endif
}