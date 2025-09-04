#include "Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"
#include "../Includes/Reinhard.hlsl"

cbuffer _Globals : register(b0)
{
  float2 resolution : packoffset(c0);
  float2 invResolution : packoffset(c0.z);
}

SamplerState s_framebuffer_s : register(s0);
Texture2D<float4> s_framebuffer : register(t0);

void main(
  float4 v0 : SV_Position0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD1,
  float2 v2 : TEXCOORD2,
  float2 w2 : TEXCOORD3,
  float2 v3 : TEXCOORD4,
  out float4 o0 : SV_Target0)
{
  o0.w = 0;
#if !ALLOW_AA // Disable AA (it's already exposed in the game settings)
  o0.rgb = s_framebuffer.Load(v0.xyz).rgb;
#else
  // TODO: implemented more modern spatial AA
  float4 r0,r1,r2,r3,r4,r5;
  r0.xyzw = resolution.xyxy * v1.xyxy;
  r1.xyzw = s_framebuffer.Sample(s_framebuffer_s, v1.xy).xyzw;
  r2.xyzw = s_framebuffer.Sample(s_framebuffer_s, w1.xy).xyzw;
  r3.xyzw = s_framebuffer.Sample(s_framebuffer_s, v2.xy).xyzw;
  r4.xyzw = s_framebuffer.Sample(s_framebuffer_s, w2.xy).xyzw;
  r5.xyzw = s_framebuffer.Sample(s_framebuffer_s, v3.xy).xyzw;
  // Luma: fixed BT.601 luminance coeffs, and the fact that they were calculated in gamma space // TODO: fix more of these (e.g. bloom?)
  r1.x = linear_to_gamma1(max(GetLuminance(gamma_to_linear(r1.xyz, GCT_MIRROR)), 0.0));
  r1.y = linear_to_gamma1(max(GetLuminance(gamma_to_linear(r2.xyz, GCT_MIRROR)), 0.0));
  r1.z = linear_to_gamma1(max(GetLuminance(gamma_to_linear(r3.xyz, GCT_MIRROR)), 0.0));
  r1.w = linear_to_gamma1(max(GetLuminance(gamma_to_linear(r4.xyz, GCT_MIRROR)), 0.0));
  r2.x = linear_to_gamma1(max(GetLuminance(gamma_to_linear(r5.xyz, GCT_MIRROR)), 0.0));
  r2.y = min(r1.y, r1.z);
  r2.z = min(r2.x, r1.w);
  r2.y = min(r2.y, r2.z);
  r2.y = min(r2.y, r1.x);
  r2.z = max(r1.y, r1.z);
  r2.w = max(r2.x, r1.w);
  r2.z = max(r2.z, r2.w);
  r2.z = max(r2.z, r1.x);
  r2.w = r1.y + r1.z;
  r3.x = r2.x + r1.w;
  r3.x = -r3.x + r2.w;
  r4.xz = -r3.xx;
  r1.y = r1.y + r1.w;
  r1.z = r2.x + r1.z;
  r4.yw = r1.yy + -r1.zz;
  r1.y = r2.w + r1.w;
  r1.y = r1.y + r2.x;
  r1.y = 0.03125 * r1.y;
  r1.y = max(0.0078125, r1.y);
  r1.z = min(abs(r4.w), abs(r3.x));
  r1.y = r1.z + r1.y;
  r1.y = 1 / r1.y;
  r3.xyzw = r4.xyzw * r1.yyyy;
  r3.xyzw = max(float4(-8,-8,-8,-8), r3.xyzw);
  r3.xyzw = min(float4(8,8,8,8), r3.xyzw);
  r3.xyzw = invResolution.xyxy * r3.xyzw;
  r0.xyzw = invResolution.xyxy * r0.xyzw;
  r4.xyzw = r3.zwzw * float4(-0.166666672,-0.166666672,0.166666672,0.166666672) + r0.zwzw;
  r5.xyzw = s_framebuffer.Sample(s_framebuffer_s, r4.xy).xyzw;
  r4.xyzw = s_framebuffer.Sample(s_framebuffer_s, r4.zw).xyzw;
  r1.yzw = r5.xyz + r4.xyz;
  r0.xyzw = r3.xyzw * float4(-0.5,-0.5,0.5,0.5) + r0.xyzw;
  r3.xyzw = s_framebuffer.Sample(s_framebuffer_s, r0.xy).xyzw;
  r0.xyzw = s_framebuffer.Sample(s_framebuffer_s, r0.zw).xyzw;
  r0.xyz = r3.xyz + r0.xyz;
  r0.xyz = 0.25 * r0.xyz;
  r0.xyz = r1.yzw * 0.25 + r0.xyz;
  r0.w = dot(r0.xyz, r1.xxx);
  r1.x = (r0.w < r2.y);
  r0.w = (r2.z < r0.w);
  r0.w = asfloat(asint(r0.w) | asint(r1.x));
  if (r0.w != 0) {
    o0.xyz = 0.5 * r1.yzw;
  } else {
    o0.xyz = r0.xyz;
  }
#endif

// In vanilla this would have happened in the actual TM shader, and all later passes would clipped too (so multiple stacked layers of clipping), but this should be similar enough, even if slightly better
#if TONEMAP_TYPE == 0
  o0.rgb = saturate(o0.rgb);
#endif

#if TONEMAP_TYPE == 1 || UI_DRAW_TYPE == 2 || DEFAULT_GAMMA_RAMP_EMULATION_MODE > 0
  o0.rgb = gamma_to_linear(o0.rgb, GCT_MIRROR);
  
#if DEFAULT_GAMMA_RAMP_EMULATION_MODE > 0 // TODO: apply this on UI too?
  // Apply an approximation of the gamma ramp the game came with (the game defaulted to a secondary gamma of 1.2, making everything brighter). Theoretically this was applied on gamma space images, but the math result is the same is linear too.
#if DEFAULT_GAMMA_RAMP_EMULATION_MODE >= 2 // Vanilla like, per channel (decreases saturation given that it brightnes up values)
  o0.rgb = pow(abs(o0.rgb), 1.0 / 1.2) * sign(o0.rgb);
#else // Do this by luminance to avoid crushing channels and shifting hues (desaturating)
  o0.rgb = RestoreLuminance(o0.rgb, pow(max(GetLuminance(o0.rgb), 0.0), 1.0 / 1.2));
#endif // DEFAULT_GAMMA_RAMP_EMULATION_MODE >= 2
#endif // DEFAULT_GAMMA_RAMP_EMULATION_MODE > 0

#if TONEMAP_TYPE == 1 // The game does quite a few passes between the actual "tonemap" shader and FXAA, so tonemap here to avoid going beyond the peak etc
  const float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
  const float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;
  // DICE doesn't look good in SDR so fall back on Reinhard
  if (LumaSettings.DisplayMode == 1)
  {
    bool perChannel = true; // TODO: expose as TONEMAP_TYPE or something. They both look good, but per channel is more reliable in general
    DICESettings settings = DefaultDICESettings(perChannel ? DICE_TYPE_BY_CHANNEL_PQ : DICE_TYPE_BY_LUMINANCE_PQ_CORRECT_CHANNELS_BEYOND_PEAK_WHITE);
    o0.rgb = DICETonemap(o0.rgb * paperWhite, peakWhite, settings) / paperWhite;
  }
  else
  {
    // Don't tonemap below 0.5 in SDR (as opposed to "MidGray", even if 0.5 is meaningless in linear), to preserve an identical look on shadow as vanilla (saturated), and to avoid desaturation on highlights (the game was raw clippied)
    float shoulderStart = 0.5;
    o0.rgb = Reinhard::ReinhardRange(o0.rgb, shoulderStart, -1.0, peakWhite / paperWhite, false);
  }
#endif

#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif

  o0.rgb = linear_to_gamma(o0.rgb, GCT_MIRROR);
#endif // TONEMAP_TYPE <= 1 || UI_DRAW_TYPE == 2 || DEFAULT_GAMMA_RAMP_EMULATION_MODE > 0
}