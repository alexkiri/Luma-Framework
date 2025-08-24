#include "Includes/Common.hlsl"
#include "../Includes/Tonemap.hlsl"
#include "../Includes/RCAS.hlsl"

Texture2D<float4> t3 : register(t3);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

Texture2D<float2> dummyFloat2Texture : register(t4); // LUMA

SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[5];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[1];
}

#define cmp

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;

  o0.w = 1;
  
  bool isWritingOnSwapchain = true; // This is always the case until proven otherwise

  r0.rgb = t0.Sample(s0_s, v1.xy).rgb; // Scene

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

      DICESettings settings = DefaultDICESettings();
#if !STRETCH_ORIGINAL_TONEMAPPER && !ENABLE_LUT_EXTRAPOLATION
      settings.Type = DICE_TYPE_BY_LUMINANCE_PQ_CORRECT_CHANNELS_BEYOND_PEAK_WHITE; // We already tonemapped by channel and restored hue/chrominance so let's not shift it anymore by tonemapping by channel
#endif // !STRETCH_ORIGINAL_TONEMAPPER
      settings.ShoulderStart = paperWhite / peakWhite; // Only tonemap beyond paper white, so we leave the SDR range untouched (roughly), even if we only blend in the SDR tonemapper up to mid grey, if we start earlier HDR would lose range
      r0.rgb = DICETonemap(r0.rgb * paperWhite, peakWhite, settings) / paperWhite;
    }
#endif // ENABLE_LUMA
  }

  r1.xyz = t1.Sample(s0_s, v1.xy).xyz; // Full res intel view (e.g. police cars are highlighted in blue etc)
  r2.xyz = t3.Sample(s0_s, v1.xy).xyz; // Blurred red
  r1.xyz = cb1[3].w * r1.xyz;
  r1.xyz = cb1[4].x * r2.xyz - r1.xyz;
  r2.xyz = cb1[1].xyz * r1.y;
  r1.xyw = r1.x * cb1[0].xyz + r2.xyz;
  r1.xyz = saturate(r1.z * cb1[2].xyz + r1.xyw); // Generate edges by subtracting blurred from full res mask
  r0.w = max(r0.y, r0.z);
  r0.w = max(r0.x, r0.w);
  r1.w = min(r0.y, r0.z);
  r1.w = min(r1.w, r0.x);
  r1.w = r0.w - r1.w;
  r2.x = cmp(r1.w != 0.0);
  r3.y = r1.w / r0.w;
  r2.yzw = r0.w - r0.xyz;
  r2.yzw = r2.yzw / r1.w;
  r2.yzw = r2.yzw - r2.wyz;
  r2.yz = float2(2,4) + r2.yz;
  r0.xy = cmp(r0.xy >= r0.w);
  r0.y = r0.y ? r2.y : r2.z;
  r0.x = r0.x ? r2.w : r0.y;
  r0.x = 0.166666672 * r0.x;
  r3.x = frac(r0.x);
  r0.xy = r2.x ? r3.xy : 0;
  r0.yz = cb1[3].xy * r0.yw;
  r2.xyz = r0.x * 6.0 + float3(-3,-2,-4); // ?
  r2.xyz = saturate(abs(r2.xyz) * float3(1,-1,-1) + float3(-1,2,2)); // The saturate here actually helps desaturate the scene
  r0.xyw = (r2.xyz - 1.0) * r0.y + 1.0;
  r0.xyz = r0.xyw * r0.z + r1.xyz;
  
#if ENABLE_DITHERING // Optionally disable dithering, it's not needed in HDR
  bool applyDithering = cb0[0].z > 0.0;
  if (applyDithering) {
    r1.xy = cb0[0].xy + v0.xy; // Temporally shift dithering
    int4 r1i = int4((int2)r1.xy, 0, 0);
    r1i.xy = r1i.xy & int2(63,63);
    float3 dither = t2.Load(r1i.xyz).xyz;
    dither = dither * 2.0 - 1.0; // From 0|1 to -1|1
#if ENABLE_LUMA
    r2.xyz = sqrt(abs(r0.xyz)) * sign(r0.xyz);
#else
    r2.xyz = sqrt(max(0, r0.xyz));
#endif
    float3 ditherScale = min(cb0[0].z, r2.xyz + cb0[0].w);
    r2.xyz += dither * ditherScale; // Apply dither in gamma space
#if ENABLE_LUMA
    r0.xyz = sqr(r2.xyz) * sign(r2.xyz);
#else
    r0.xyz = sqr(r2.xyz);
#endif
  }
#endif // ENABLE_DITHERING

  o0.xyz = r0.xyz;

  if (isWritingOnSwapchain)
  {
    o0.rgb = linear_to_sRGB_gamma(o0.rgb, GCT_MIRROR); // Needed because the original view was a R8G8B8A8_UNORM_SRGB, with the input being float/linear, so there was an implicity sRGB encoding. Following passes are UI and work with non sRGB views.
#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  	o0.rgb *= pow(LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits, 1.0 / DefaultGamma);
#endif
  }
}