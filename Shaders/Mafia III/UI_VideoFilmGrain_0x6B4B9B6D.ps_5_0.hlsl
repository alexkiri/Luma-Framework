#include "Includes/Common.hlsl"
#include "../Includes/Reinhard.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

Texture2D<float4> t2 : register(t2); // Film Grain
Texture2D<float4> t1 : register(t1); // Dither
Texture2D<float4> t0 : register(t0); // Source

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb2 : register(b2)
{
  float4 cb2[55];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[1];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[2];
}

#define cmp

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5;
  float4 fDest;
  t2.GetDimensions(0, fDest.x, fDest.y, fDest.z);
  r0.xy = fDest.xy;
  r0.xy = cb0[0].xy * r0.xy;
  r0.xy = float2(1,1) / r0.xy;
  r0.xy = v1.xy * r0.xy;
  r0.z = 1.0 / cb1[0].y; // This automatically scales by resolution, which means film grain always draws per pixel, so at 4k it'd be tiny
#if ENABLE_LUMA && 1 // Fix film grain being nearly invisible at 4k
  float sourceWidth, sourceHeight;
  t0.GetDimensions(sourceWidth, sourceHeight);
  r0.z *= 1080.0 / sourceHeight; // Multiplying by a smaller number makes film grain bigger
#endif

  r0.w = dot(cb2[54].xxxx, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.x = frac(r0.w);
  r1.w = cb2[54].x;
  r0.w = dot(r1.xwww, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.y = frac(r0.w);
  r0.w = dot(r1.xyww, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.z = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.w = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.x = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.y = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.z = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.w = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.x = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.y = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.z = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.w = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));
  r1.x = frac(r0.w);
  r0.w = dot(r1.xyzw, float4(97.4090881,54.5981483,56.20541,44.6878014));

  r1.y = frac(r0.w);
  r0.xy = r0.xy * r0.z + r1.xy;
  r1.xyz = t0.Sample(s1_s, v1.xy).xyz;
  r0.xyz = t2.Sample(s0_s, r0.xy).xyz; // Film Grain
  
  float3 rawVideoColor = r1.xyz;
  float3 filmGrainVideoColor = rawVideoColor;
#if ENABLE_AUTO_HDR // Approximately undo PumboAutoHDR if it was already applied or film grain would go wild on > 1 colors (the PumboAutoHDR is not easily reversible). If we don't do this, film grain would go wild in bright areas.
  filmGrainVideoColor = Reinhard::ReinhardRange(rawVideoColor, MidGray, 400.0 / sRGB_WhiteLevelNits, 1.0, false);
  float3 reinhardScale = safeDivision(rawVideoColor / filmGrainVideoColor, 1);
#endif

  // Apply gamma to do film grain in gamma space
#if ENABLE_LUMA
  r2.xyz = pow(abs(filmGrainVideoColor), 1.0 / 2.2) * sign(filmGrainVideoColor);
#else
  r2.xyz = pow(abs(filmGrainVideoColor), 1.0 / 2.2);
#endif

  // Change contrast
  r2.xyz = (r2.xyz - 0.5) * cb1[0].z + 0.5;
  r3.xyz = cmp(r2.xyz < 0.5);
  r0.w = dot(r0.xx, r2.xx); // r0.x*r2.x*2.0
  r4.xyz = (1.0 - r2.xyz) * 2.0; // It's ok if this goes negative
  r5.xyz = 1.0 - r0.xyz;
  r4.xyz = -r4.xyz * r5.xyz + 1.0;
  r0.x = dot(r0.yy, r2.yy);
  r5.xy = r3.xy ? r0.wx : r4.xy;
  r0.x = dot(r0.zz, r2.zz);
  r5.z = r3.z ? r0.x : r4.z;
#if ENABLE_LUMA
  r0.xyz = pow(abs(r5.xyz), 2.2) * sign(r5.xyz);
#else
  r0.xyz = pow(abs(r5.xyz), 2.2);
#endif
#if ENABLE_AUTO_HDR // Scale back with the tonemapping factor (now film grain is included too, so it might make it stronger, but it shouldn't be too bad)
  r0.xyz *= reinhardScale;
#endif
  r0.xyz = lerp(rawVideoColor, r0.xyz, cb1[0].x); // Filter intensity

#if ENABLE_DITHERING // Optionally disable dithering, it's not needed in HDR
  bool applyDithering = cb0[1].z > 0.0;
  if (applyDithering) {
    r1.xy = cb0[1].xy + v0.xy; // Temporally shift dithering
    int4 r1i = int4((int2)r1.xy, 0, 0);
    r1i.xy = r1i.xy & int2(63,63);
    float3 dither = t1.Load(r1i.xyz).xyz;
    dither = dither * 2.0 - 1.0; // From 0|1 to -1|1
#if ENABLE_LUMA
    r2.xyz = sqrt(abs(r0.xyz)) * sign(r0.xyz);
#else
    r2.xyz = sqrt(max(0, r0.xyz));
#endif
    float3 ditherScale = min(cb0[1].z, r2.xyz + cb0[1].w);
    r2.xyz += dither * ditherScale; // Apply dither in gamma space
#if ENABLE_LUMA
    r0.xyz = sqr(r2.xyz) * sign(r2.xyz);
#else
    r0.xyz = sqr(r2.xyz);
#endif
  }
#endif // ENABLE_DITHERING

  o0.xyz = r0.xyz;
  o0.w = 1;

  bool isWritingOnSwapchain = LumaData.CustomData1 != 0;
  bool isSourceScene = LumaData.CustomData2 != 0;
  // Videos run the UI Sprite shader after (0xB6F720AE), while the scene would run another UI Sprite shader (0x2C052C85)
  if (isWritingOnSwapchain)
  {
#if ENABLE_AUTO_HDR && 0 // This was already linear->linear. Note that PumboAutoHDR was moved to the previous UI pass, as film grain only runs sometimes and we can't know upfront.
    if (!isSourceScene)
    {
      o0.rgb = PumboAutoHDR(o0.rgb, 400.0, LumaSettings.GamePaperWhiteNits);
    }
#endif

#if UI_DRAW_TYPE == 2 // This is drawn in the UI phase but it's not UI (it's either videos or scene), so make sure it scales with the game brightness instead
    ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, VANILLA_ENCODING_TYPE, GAMMA_CORRECTION_TYPE, true);
    o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
    ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, GAMMA_CORRECTION_TYPE, VANILLA_ENCODING_TYPE, true);
#endif

    // TODO: this is always needed? Sometimes? Only when writing on swapchain? Also make sure this always runs after video playback as that's where we do videos HDR. It seems fine so far.
    o0.xyz = linear_to_sRGB_gamma(o0.xyz, GCT_MIRROR); // Needed because the original view was a R8G8B8A8_UNORM_SRGB, with the input being float/linear, so there was an implicit sRGB encoding.
  }
}