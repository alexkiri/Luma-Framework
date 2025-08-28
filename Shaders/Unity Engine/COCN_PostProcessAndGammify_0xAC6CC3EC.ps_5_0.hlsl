#include "../Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"

#if !defined(ENABLE_FILM_GRAIN)
#define ENABLE_FILM_GRAIN 1
#endif

Texture2D<float4> t0 : register(t0); // Noise A
Texture2D<float4> t1 : register(t1); // Noise B
Texture2D<float4> sceneTexture : register(t2);

SamplerState s0_s : register(s0); // Likely point
SamplerState s1_s : register(s1); // Likely point
SamplerState s2_s : register(s2); // Likely linear

cbuffer cb0 : register(b0)
{
  float4 cb0[147];
}

#define cmp

// Post processing (film grain, screen distortion)
// Input was float and output was unorm sRGB (SDR), so no direct gamma, but implicitly sRGB
void main(
  float4 v0 : SV_POSITION0,
  out float4 outColor : SV_Target0)
{
  outColor.a = 0.0;

  float4 r0,r1,r2,r3,r4;
  r0.xy = frac(cb0[8].zw);
  r1.y = cb0[15].y - v0.y;
  r1.x = v0.x;
  r0.xy = r1.xy * cb0[121].xy + r0.xy;
  r0.zw = r1.xy * 2.0 - cb0[15].xy;
  r0.zw = r0.zw / cb0[15].y;
  r0.x = t1.Sample(s0_s, r0.xy).x; // Screen distortion?
  r0.x = -0.5 + r0.x;
  r0.x = -abs(r0.x) * 2 + 1;
  r0.x = sqrt(r0.x);
  r0.x = -r0.x * 0.5 + 0.5;
#if 1
  r0.y = float(int(((r0.x < 0.0) ? 4294967295u : 0u) + uint(r0.x > 0.0)));
#elif 1
  r0.y = cmp(0 < r0.x);
  r1.x = cmp(r0.x < 0);
  int r0yi = asint(r1.x) - asint(r0.y);
  r0.y = r0yi;
#else
  r0.y = cmp(0 < r0.x);
  r1.x = cmp(r0.x < 0);
  int r0yi = (int)-r0.y + (int)r1.x;
  r0.y = r0yi;
#endif
  r0.x = r0.y * r0.x;
  r0.x = cb0[136].y * r0.x;
  r0.x = exp2(r0.x);
  r0.xy = r0.zw * r0.x;
  r1.x = dot(r0.xy, r0.xy);
  r1.x = -r1.x * cb0[136].x + 1;
  r1.x = rsqrt(r1.x);
  r1.yz = r1.x * r0.xy;
  r0.x = cb0[15].y / cb0[15].x;
  r1.x = r0.x * r1.y;
  r0.xy = r1.xz * 0.5 + 0.5;
  r0.xy = cb0[141].xy * r0.xy;
  r0.xy = r0.xy / cb0[141].xy;
  r0.xy = cb0[141].z * r0.xy;

  r1.xyz = sceneTexture.SampleLevel(s2_s, r0.xy, 0).xyz;
#if 0 // TEST: raw color
  outColor.rgb = r1.xyz; return;
#endif
  r2.xyz = 1.0 - r1.xyz;
  r3.xyz = cb0[138].xyz - 0.5;
  r3.xyz = cb0[138].w * r3.xyz + 0.5;
  r4.xyz = 1.0 - r3.xyz;
  r4.xyz = r4.xyz + r4.xyz;
  r2.xyz = -r4.xyz * r2.xyz + 1.0;
  r1.xyz = r3.xyz * r1.xyz;
  r3.xyz = cmp(r3.xyz < 0.5);
  r1.xyz = r1.xyz + r1.xyz;
  r1.xyz = r3.xyz ? r1.xyz : r2.xyz;
  r2.xyz = 1.0 - r1.xyz;

  r0.x = dot(r0.zw, r0.zw);
  r0.x = -1.44269502 * r0.x;
  r0.x = exp2(r0.x);
  r0.x = 1 - r0.x;
  r0.x = log2(r0.x);
  r0.x = 2.2 * r0.x;
  r0.x = exp2(r0.x);
  r0.x = cb0[139].w * r0.x;
  
  r3.xyz = cb0[139].xyz - 0.5;
  r0.xyz = r0.x * r3.xyz + 0.5;
  r3.xyz = 1.0 - r0.xyz;
  r3.xyz = r3.xyz + r3.xyz;
  r2.xyz = -r3.xyz * r2.xyz + 1.0;
  r1.xyz = r0.xyz * r1.xyz;
  r0.xyz = cmp(r0.xyz < 0.5);
  r1.xyz = r1.xyz + r1.xyz;
  r0.xyz = r0.xyz ? r1.xyz : r2.xyz;
  r1.xyz = 1.0 - r0.xyz;
  r1.w = r0.w * r0.w;
  r0.w = 0.5 * r0.w;
  r0.w = r1.w * 0.25 - r0.w;
  r0.w = 0.25 + r0.w;
  r0.w = -1.44269502 * r0.w;
  r0.w = exp2(r0.w);
  r0.w = 1 - r0.w;
  r0.w = log2(r0.w);
  r0.w = 2.2 * r0.w;
  r0.w = exp2(r0.w);
  r0.w = cb0[140].w * r0.w;
  r2.xyz = cb0[140].xyz - 0.5;
  r2.xyz = r0.w * r2.xyz + 0.5;
  r3.xyz = 1.0 - r2.xyz;
  r3.xyz = r3.xyz + r3.xyz;
  r1.xyz = -r3.xyz * r1.xyz + 1.0;
  r0.xyz = r2.xyz * r0.xyz;
  r2.xyz = cmp(r2.xyz < 0.5);
  r0.xyz = r0.xyz + r0.xyz;
  r0.xyz = r2.xyz ? r0.xyz : r1.xyz;

  outColor.rgb = r0.xyz;

#if ENABLE_FILM_GRAIN
  r0.w = 10 * cb0[8].y;
  r0.w = frac(r0.w);
  r1.xy = v0.xy * cb0[144].xy + r0.w; // Distortion?
  float3 filmGrain = t0.SampleLevel(s1_s, r1.xy, 0).xyz;
  filmGrain = filmGrain * 2.0 - 1.0; // Remap from 0|1 to -1|1, with 0.5 being 0 (supposedly in gamma space)
  outColor.rgb += filmGrain * cb0[146].x;
#endif

#if 1 // Luma: HDR display mapping
  const float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
  const float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;

  DICESettings settings = DefaultDICESettings();
#if !STRETCH_ORIGINAL_TONEMAPPER
  settings.Type = DICE_TYPE_BY_LUMINANCE_PQ_CORRECT_CHANNELS_BEYOND_PEAK_WHITE; // We already tonemapped by channel and restored hue/chrominance so let's not shift it anymore by tonemapping by channel
#endif
  settings.ShoulderStart = paperWhite / peakWhite; // Only tonemap beyond paper white, so we leave the SDR range untouched (roughly)

  float sourceWidth, sourceHeight;
  sceneTexture.GetDimensions(sourceWidth, sourceHeight);
  float2 uv = v0.xy / float2(sourceWidth, sourceHeight);
  bool forceSDR = ShouldForceSDR(uv, true) || LumaSettings.DisplayMode != 1;
  if (!forceSDR)
    outColor.rgb = DICETonemap(outColor.rgb * paperWhite, peakWhite, settings) / paperWhite;
#endif

#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  outColor.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif
}