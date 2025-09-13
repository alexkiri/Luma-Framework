#include "Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

cbuffer ConstentValue : register(b0)
{
  float4 windowSize : packoffset(c0);
}

SamplerState g_sampler_s : register(s0);
Texture2D<float4> imtex : register(t0);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1,r2,r3,r4;
  r0.xyz = imtex.SampleLevel(g_sampler_s, v1.zw, 0, int2(1, 0)).xyz;
  r0.x = GetLuminance(r0.xyz); // Luma: fixed wrong luminance formula (BT.601) for better results
  r0.yzw = imtex.SampleLevel(g_sampler_s, v1.zw, 0, int2(1, 1)).xyz;
  r0.y = GetLuminance(r0.yzw);
  r0.z = r0.x + r0.y;
  r1.xyz = imtex.SampleLevel(g_sampler_s, v1.zw, 0).xyz;
  r0.w = GetLuminance(r1.xyz);
  r1.xyz = imtex.SampleLevel(g_sampler_s, v1.zw, 0, int2(0, 1)).xyz;
  r1.x = GetLuminance(r1.xyz);
  r1.y = r1.x + r0.w;
  r0.z = -r1.y + r0.z;
  r1.y = r0.w + r0.x;
  r1.z = r1.x + r0.y;
  r2.xz = r1.zz + -r1.yy;
  r1.y = r1.y + r1.x;
  r1.y = r1.y + r0.y;
  r1.y = 0.03125 * r1.y;
  r1.y = max(0.0078125, r1.y);
  r1.z = min(abs(r2.z), abs(r0.z));
  r2.yw = -r0.zz;
  r0.z = r1.z + r1.y;
  r0.z = 1 / r0.z;
  r2.xyzw = r2.xyzw * r0.zzzz;
  r2.xyzw = max(float4(-8,-8,-8,-8), r2.xyzw);
  r2.xyzw = min(float4(8,8,8,8), r2.xyzw);
  r3.xyzw = float4(1,1,1,1) / windowSize.xyxy;
  r2.xyzw = r3.xyzw * r2.xyzw;
  r3.xyzw = r2.xyzw * float4(-0.5,-0.5,0.5,0.5) + v1.xyxy;
  r2.xyzw = r2.zwzw * float4(-0.166666672,-0.166666672,0.166666672,0.166666672) + v1.xyxy;
  r4.xyzw = imtex.SampleLevel(g_sampler_s, r3.xy, 0).xyzw;
  r3.xyzw = imtex.SampleLevel(g_sampler_s, r3.zw, 0).xyzw;
  r3.xyzw = r4.xyzw + r3.xyzw;
  r3.xyzw = float4(0.25,0.25,0.25,0.25) * r3.xyzw;
  r4.xyzw = imtex.SampleLevel(g_sampler_s, r2.xy, 0).xyzw;
  r2.xyzw = imtex.SampleLevel(g_sampler_s, r2.zw, 0).xyzw;
  r2.xyzw = r4.xyzw + r2.xyzw;
  r3.xyzw = r2.xyzw * float4(0.25,0.25,0.25,0.25) + r3.xyzw;
  r2.xyzw = float4(0.5,0.5,0.5,0.5) * r2.xyzw;
  r0.z = GetLuminance(r3.xyz);
  r1.y = min(r0.w, r0.x);
  r0.x = max(r0.w, r0.x);
  r0.w = min(r1.x, r0.y);
  r0.y = max(r1.x, r0.y);
  r0.x = max(r0.x, r0.y);
  r0.y = min(r1.y, r0.w);
  r1.xyz = imtex.SampleLevel(g_sampler_s, v1.xy, 0).xyz;
  r0.w = GetLuminance(r1.xyz);
  r0.y = min(r0.w, r0.y);
  r0.x = max(r0.w, r0.x);
  r0.xy = (r0.zz >= r0.xy);
  r0.y = r0.y ? 1.0 : 0;
  r0.x = r0.x ? -1 : -0;
  r0.x = r0.y + r0.x;
  r1.xyzw = r0.x * r3.xyzw;
  r0.x = 1 + -r0.x;
  o0.xyzw = r0.x * r2.xyzw + r1.xyzw;

  // The game has some minor nans and invalid colors (due to subtractive blending).
  // AA is the first fullscreen pass where we can fix them.
  o0.xyz = IsNaN_Strict(o0.xyz) ? 0.0 : o0.xyz;
  FixColorGradingLUTNegativeLuminance(o0.xyz);
}