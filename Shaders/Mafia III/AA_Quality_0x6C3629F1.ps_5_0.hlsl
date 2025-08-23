#include "Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"
#include "../Includes/RCAS.hlsl"

Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

Texture2D<float2> dummyFloat2Texture : register(t2); // LUMA

cbuffer cb1 : register(b1)
{
  float4 cb1[1];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[2];
}

// FXAA
// Used when AA is set to medium or high quality, runs after tonemapping
void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4;

  o0.w = 1;

  bool skipAA = false;
  bool isWritingOnSwapchain = LumaData.CustomData1 != 0; // If true, this is after tonemapping
  bool hasRunLumaSR = LumaData.CustomData2 != 0; // True if this pass is done on an image that already had "super resolution" techniques applied
  if (isWritingOnSwapchain)
  {
#if !ALLOW_AA
    skipAA = true;
#endif // !ALLOW_AA
  }
  if (hasRunLumaSR)
  {
    skipAA = true; // No need for AA if we already did proper super resolution
  }

  if (skipAA)
  {
    r0.xyz = t0.Sample(s0_s, v1.xy).xyz;
  }
  else
  {
    r0.x = 0.5 + cb1[0].y;
    r0.xy = -cb0[0].xy * r0.x + v1.xy;
    r1.xyz = t0.Sample(s0_s, r0.xy).xyz;
    r2.xyz = t0.Sample(s0_s, r0.xy, int2(0, 0)).xyz;
    r3.xyz = t0.Sample(s0_s, r0.xy, int2(0, 0)).xyz;
    r0.xyz = t0.Sample(s0_s, r0.xy, int2(0, 0)).xyz;
    r4.xyz = t0.Sample(s0_s, v1.xy).xyz;
    // Luma: fixed BT.601 luminance formulas
    r0.w = GetLuminance(r1.xyz);
    r1.x = GetLuminance(r2.xyz);
    r1.y = GetLuminance(r3.xyz);
    r0.x = GetLuminance(r0.xyz);
    r0.y = GetLuminance(r4.xyz);
    r0.z = min(r1.x, r0.w);
    r1.z = min(r1.y, r0.x);
    r0.z = min(r1.z, r0.z);
    r0.z = min(r0.y, r0.z);
    r1.z = max(r1.x, r0.w);
    r1.w = max(r1.y, r0.x);
    r1.z = max(r1.z, r1.w);
    r0.y = max(r1.z, r0.y);
    r1.z = r1.x + r0.w;
    r1.xw = r1.xy + r0.x;
    r1.w = r1.z + -r1.w;
    r2.xz = -r1.ww;
    r0.w = r1.y + r0.w;
    r2.yw = r0.ww + -r1.x;
    r0.w = r1.z + r1.y;
    r0.x = r0.w + r0.x;
    r0.x = 0.03125 * r0.x;
    r0.x = max(0.0078125, r0.x);
    r0.w = min(abs(r2.w), abs(r1.w));
    r0.x = r0.w + r0.x;
    r0.x = 1 / r0.x;
    r1.xyzw = r2.xyzw * r0.x;
    r1.xyzw = max(float4(-8,-8,-8,-8), r1.xyzw);
    r1.xyzw = min(float4(8,8,8,8), r1.xyzw);
    r1.xyzw = cb0[0].xyxy * r1.xyzw;
    r2.xyzw = r1.zwzw * float4(-0.166666672,-0.166666672,0.166666672,0.166666672) + v1.xyxy;
    r3.xyz = t0.Sample(s0_s, r2.xy).xyz;
    r2.xyz = t0.Sample(s0_s, r2.zw).xyz;
    r2.xyz = r3.xyz + r2.xyz;
    r3.xyz = float3(0.5,0.5,0.5) * r2.xyz;
    r1.xyzw = r1.xyzw * float4(-0.5,-0.5,0.5,0.5) + v1.xyxy;
    r4.xyz = t0.Sample(s0_s, r1.xy).xyz;
    r1.xyz = t0.Sample(s0_s, r1.zw).xyz;
    r1.xyz = r4.xyz + r1.xyz;
    r1.xyz = float3(0.25,0.25,0.25) * r1.xyz;
    r1.xyz = r2.xyz * float3(0.25,0.25,0.25) + r1.xyz;
    r0.x = GetLuminance(r1.xyz); // Luma: fixed BT.601 luminance formula
    r0.z = (r0.x < r0.z);
    r0.x = (r0.y < r0.x);
    r0.x = asfloat(asint(r0.x) | asint(r0.z));
    r0.xyz = r0.x ? r3.xyz : r1.xyz;
  }
  
  // Do TM at the very very last
  if (isWritingOnSwapchain)
  {
#if ENABLE_SHARPENING // Note that this is possibly after film grain, but so far I haven't noticed any in the game
    //if (skipAA) // Theoretically we can't do both at the same time, given they both do 4 surrounding samples and do an average thing, so we'd need an extra pass, but whatever, this mod is meant to be played with DLSS/FSR etc, which already disable FXAA above (it won't look super broken otherwise)
    {
      float sharpenAmount = LumaData.CustomData3;
	    r0.rgb = RCAS(v0.xy, 0, 0x7FFFFFFF, sharpenAmount, t0, dummyFloat2Texture, 1.0, true, float4(r0.rgb, 1.0)).rgb;
    }
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
    float3 ditherScale = min(cb0[1].z, r2.xyz + cb0[1].w); // TODO: reduce these from 8bit to 10bit or something for HDR?
    r2.xyz += dither * ditherScale;
#if ENABLE_LUMA
    r0.xyz = sqr(r2.xyz) * sign(r2.xyz);
#else
    r0.xyz = sqr(r2.xyz);
#endif
  }
#endif // ENABLE_DITHERING

  o0.xyz = r0.xyz;

  // Clouds use this shader too, just as post processing, and the rear view mirror hud rendering too
  if (isWritingOnSwapchain)
  {
    o0.rgb = linear_to_sRGB_gamma(o0.rgb, GCT_MIRROR); // Needed because the original view was a R8G8B8A8_UNORM_SRGB, with the input being float/linear, so there was an implicity sRGB encoding. Following passes are UI and work with non sRGB views.
#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  	o0.rgb *= pow(LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits, 1.0 / DefaultGamma);
#endif
  }
}