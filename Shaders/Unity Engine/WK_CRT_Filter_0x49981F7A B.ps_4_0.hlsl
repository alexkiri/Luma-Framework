#include "../Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"

Texture2D<float4> t0 : register(t0);
Texture2D<float4> t1 : register(t1);

SamplerState s0_s : register(s0);
SamplerState s1_s : register(s1);

cbuffer cb0 : register(b0)
{
  float4 cb0[17];
}

#define cmp -

// This is the last shader, it applies a CRT color filter
// TODO: something is broken in this shader's decomp, it looks different (restore changes before testing it)
void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9;
  r0.xyzw = t0.Sample(s0_s, v1.xy).xyzw;
  bool enabled = cb0[16].w == 0.0;
  // Chromatic aberration (4 times)
  if (enabled) {
    r1.xyzw = t1.Sample(s1_s, w1.xy).xyzw;
  } else {
    r2.x = cb0[16].w * -cb0[4].x;
    r2.yw = float2(0,0);
    r2.xy = w1.xy + r2.xy;
    r3.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r4.xyzw = t1.Sample(s1_s, w1.xy).xyzw;
    r2.z = cb0[16].w * cb0[4].x;
    r2.xy = w1.xy + r2.zw;
    r1.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r1.x = r3.x;
    r1.y = r4.y;
    r1.w = 1; // Weird that this is only done on the first sample
  }
  r2.xy = cb0[4].ww * cb0[4].yx;
  r2.z = 0;
  r2.xw = w1.xy + r2.zx;
  if (enabled) {
    r3.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
  } else {
    r4.x = cb0[16].w * -cb0[4].x;
    r4.yw = float2(0,0);
    r4.xy = r4.xy + r2.xw;
    r5.xyzw = t1.Sample(s1_s, r4.xy).xyzw;
    r6.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
    r4.z = cb0[16].w * cb0[4].x;
    r2.xw = r4.zw + r2.xw;
    r3.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
    r3.x = r5.x;
    r3.y = r6.y;
  }
  r4.xy = -cb0[4].ww * cb0[4].yx;
  r4.z = 0;
  r2.xw = w1.xy + r4.zx;
  if (enabled) {
    r5.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
  } else {
    r6.x = cb0[16].w * -cb0[4].x;
    r6.yw = float2(0,0);
    r4.xw = r6.xy + r2.xw;
    r7.xyzw = t1.Sample(s1_s, r4.xw).xyzw;
    r8.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
    r6.z = cb0[16].w * cb0[4].x;
    r2.xw = r6.zw + r2.xw;
    r5.xyzw = t1.Sample(s1_s, r2.xw).xyzw;
    r5.x = r7.x;
    r5.y = r8.y;
  }
  r2.xy = w1.xy + r2.yz;
  if (enabled) {
    r6.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
  } else {
    r7.x = cb0[16].w * -cb0[4].x;
    r2.z = w1.y;
    r7.yw = float2(0,0);
    r4.xw = r7.xy + r2.xz;
    r8.xyzw = t1.Sample(s1_s, r4.xw).xyzw;
    r9.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r7.z = cb0[16].w * cb0[4].x;
    r2.xy = r7.zw + r2.xz;
    r6.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r6.x = r8.x;
    r6.y = r9.y;
  }
  r2.xy = w1.xy + r4.yz;
  if (enabled) {
    r4.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
  } else {
    r7.x = cb0[16].w * -cb0[4].x;
    r2.z = w1.y;
    r7.yw = float2(0,0);
    r7.xy = r7.xy + r2.xz;
    r8.xyzw = t1.Sample(s1_s, r7.xy).xyzw;
    r9.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r7.z = cb0[16].w * cb0[4].x;
    r2.xy = r7.zw + r2.xz;
    r4.xyzw = t1.Sample(s1_s, r2.xy).xyzw;
    r4.x = r8.x;
    r4.y = r9.y;
  }
  r2.xyz = max(r5.xyz, r3.xyz);
  r3.xyz = max(r6.xyz, r4.xyz);
  r2.xyz = max(r3.xyz, r2.xyz);
  r0.w = r0.y + r0.z;
  r0.w = -0.1 + r0.w;
  r0.w = cmp(r0.w >= r0.x);
  r2.w = max(r1.x, r0.x);
  r0.xyz = r0.www ? r2.www : r0.xyz;
  r3.xy = float2(1,1) + -cb0[5].yx;
  r0.w = r1.w * r3.x + cb0[5].y;
  r1.xyz = r1.xyz * r1.www;
  r1.xyz = r1.xyz * r3.xxx;
  r0.xyz = r0.xyz * cb0[5].yyy + r1.xyz;
  r0.xyz = r0.xyz / r0.www;
  r1.xyz = max(r2.xyz, r0.xyz);
  r0.xyz = r0.xyz * r3.yyy;
  r0.xyz = r1.xyz * cb0[5].xxx + r0.xyz;
  r0.w = 0.0166666675 * cb0[4].z;
  r1.w = cmp(r0.w >= -r0.w);
  r0.w = frac(abs(r0.w));
  r0.w = r1.w ? r0.w : -r0.w;
  r1.w = 60 * r0.w;
  r2.xy = v1.xy / cb0[4].xy;
  r2.yz = sin(r2.xy);
  r3.xy = v1.yx * r2.yz;
  r3.xy = r3.xy / cb0[4].yx;
  r3.xy = r0.ww * float2(60,60) + r3.xy;
  r3.xy = float2(89.4199982,89.4199982) * r3.xy;
  r3.xy = cos(r3.xy);
  r3.xy = float2(343.420013,343.420013) * r3.xy;
  r3.xy = frac(r3.xy);
  r0.w = r2.y * r2.z + r1.w;
  r0.w = 89.4199982 * r0.w;
  r0.w = cos(r0.w);
  r0.w = 343.420013 * r0.w;
  r3.z = frac(r0.w);
  r2.yzw = r3.xyz + r0.xyz;
  r4.xyz = -r3.xyz + r0.xyz;
  r5.xyz = r3.xyz * r0.xyz;
  r6.xyz = r0.xyz / r3.xyz;
  r7.xyzw = (asint(cb0[6].yyyy) == int4(1,2,3,4));
  r8.xyz = max(r3.xyz, r0.xyz);
  r9.xyzw = (asint(cb0[6].ywww) == int4(5,1,2,3));
  r3.yzw = min(r3.xyz, r0.xyz);
  r1.xyz = r9.xxx ? r3.yzw : r1.xyz;
  r1.xyz = r7.www ? r8.xyz : r1.xyz;
  r1.xyz = r7.zzz ? r6.xyz : r1.xyz;
  r1.xyz = r7.yyy ? r5.xyz : r1.xyz;
  r1.xyz = r7.xxx ? r4.xyz : r1.xyz;
  r1.xyz = (cb0[6].yyy ? r1.xyz : r2.yzw); // Luma: removed saturate (it doesn't seem to make a difference)
  r2.yz = float2(1,1) + -cb0[6].zx;
  r0.xyz = r2.yyy * r0.xyz;
  r0.xyz = r1.xyz * cb0[6].zzz + r0.xyz;
  r3.yzw = r0.xyz + r3.xxx;
  r4.xyz = r0.xyz + -r3.xxx;
  r5.xyz = r0.xyz * r3.xxx;
  r6.xyz = r0.xyz / r3.xxx;
  r7.xyz = max(r3.xxx, r0.xyz);
  r2.yw = (asint(cb0[6].ww) == int2(4,5));
  r8.xyz = min(r3.xxx, r0.xyz);
  r1.xyz = r2.www ? r8.xyz : r1.xyz;
  r1.xyz = r2.yyy ? r7.xyz : r1.xyz;
  r1.xyz = r9.www ? r6.xyz : r1.xyz;
  r1.xyz = r9.zzz ? r5.xyz : r1.xyz;
  r1.xyz = r9.yyy ? r4.xyz : r1.xyz;
  r1.xyz = (cb0[6].www ? r1.xyz : r3.yzw); // Luma: removed saturate (it doesn't seem to make a difference)
  r0.w = 1 + -cb0[7].y;
  r0.xyz = r0.xyz * r0.www;
  r0.xyz = r1.xyz * cb0[7].yyy + r0.xyz;
  r0.w = 0.333333343 * r2.x;
  r1.x = cmp(r0.w >= -r0.w);
  r0.w = frac(abs(r0.w));
  r0.w = r1.x ? r0.w : -r0.w;
  r0.w = 3.0 * r0.w;
  r0.w = floor(r0.w);
  r1.xy = cmp(r0.ww == float2(0,1));
  r0.w = cb0[5].z * cb0[5].w;
  r1.z = -cb0[5].z * cb0[5].w + r0.x;
  r0.w = -r0.w * 2 + r0.x;
  r0.w = r1.y ? r1.z : r0.w;
  r0.w = r1.x ? r0.x : r0.w;
  r0.xyz = r0.xyz * r2.zzz;
  r0.xyz = r0.www * cb0[6].xxx + r0.xyz;
  r0.w = cb0[15].w * cb0[4].y;
  r0.w = v1.y / r0.w;
  r1.xy = cb0[16].zx * cb0[4].yz + r0.ww;
  r1.x = cb0[16].x * cb0[4].z + r1.x;
  r1.x = sin(r1.x);
  r0.x = (r1.x * cb0[16].y + r0.x); // Luma: removed saturate
  r1.x = sin(r1.y);
  r0.y = (r1.x * cb0[16].y + r0.y); // Luma: removed saturate
  r0.w = -cb0[16].z + r0.w;
  r0.w = cb0[16].x * cb0[4].z + r0.w;
  r0.w = sin(r0.w);
  r0.z = (r0.w * cb0[16].y + r0.z); // Luma: removed saturate
  r1.xyzw = cb0[9].xyzw * r0.yyyy;
  r1.xyzw = cb0[8].xyzw * r0.xxxx + r1.xyzw;
  r0.xyzw = cb0[10].xyzw * r0.zzzz + r1.xyzw;
  r0.xyzw = cb0[11].xyzw + r0.xyzw;
  r1.xyz = cb0[13].xyz + -cb0[12].xyz;
  r0.xyz = r0.xyz / r1.xyz;
  r0.xyz = cb0[12].xyz + r0.xyz;
#if 0 // Luma: remove min/max clamping
  o0.xyz = r0.xyz;
  
  DICESettings config = DefaultDICESettings();
  config.Type = DICE_TYPE_BY_CHANNEL_PQ; // Do DICE by channel to desaturate highlights and keep the SDR range unotuched
  float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;
  float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
  config.ShoulderStart = paperWhite / peakWhite; // Start tonemapping beyond paper white, so we leave the SDR range untouched (roughly, given that this tonemaps in BT.2020)
  o0.rgb = DICETonemap(o0.rgb * paperWhite, peakWhite, config) / paperWhite;
  
#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
#endif
#else
  o0.xyz = min(cb0[15].xyz, max(cb0[14].xyz, r0.xyz));
#endif
  o0.w = r0.w;
}