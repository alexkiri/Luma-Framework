#include "Includes/Common.hlsl"
#include "../Includes/Reinhard.hlsl"

cbuffer ConstentValue : register(b0)
{
  float4 register0 : packoffset(c0);
  float3 register1 : packoffset(c1);
  float3 register2 : packoffset(c2);
}

SamplerState sampler0_s : register(s0);
SamplerState sampler1_s : register(s1);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1,r2,r3;
  r0.xy = texture1.Sample(sampler1_s, v1.xy).xy - 0.5; // Water ripples
  r0.z = 0.5;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(max(r0.w, FLT_EPSILON)); // Luma: fixed nans
  r1.xyz = r0.xyz * r0.w;
  r0.x = -r0.z * r0.w + 1;
  r0.x = r0.x * 1.5 + 0.8;
  r0.y = dot(r1.xyz, float3(0.577350259,0.577350259,0.577350259));
  r0.y = max(0, r0.y);
  r0.y = pow(r0.y, 9.0);
  r0.y = 0.45 * r0.y;
  r0.zw = register0.xy * r1.xy;
  r0.zw = r0.zw * register0.ww + v1.xy;
  r2.xyz = texture0.Sample(sampler0_s, r0.zw).xyz; // Scene
#if ENABLE_LUMA // Tonemap the background to make the menu more visible. This won't do anything in SDR
#if 1 // Just darken the pause background, it looks much better in SDR or HDR, no need for tonemapping
  r2.xyz *= 0.5;
#else
  if (LumaSettings.DisplayMode == 1) // TODO: skip in SDR as it'd end up compress some range even when not needed, even if that's not intentional ("Reinhard::ReinhardRange()" needs fixing?)
  {
    r2.xyz = gamma_to_linear(r2.xyz, GCT_MIRROR);
    r2.xyz = RestoreLuminance(r2.xyz, Reinhard::ReinhardRange(max(GetLuminance(r2.xyz), 0.0), MidGray, LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits, 1.0).x); // Tonemap by luminance to avoid ugly hue shifts
    r2.xyz = linear_to_gamma(r2.xyz, GCT_MIRROR);
  }
#endif
#endif
  r2.xyz = pow(abs(r2.xyz), register1.xyz) * sign(r2.xyz); // Luma: fixed negative value support
  r0.xyz = r2.xyz * r0.x + r0.y;
  r3.xy = float2(-0.5,-0.5) + v1.xy;
  r3.z = 1;
  r0.w = dot(r3.xyz, r3.xyz);
  r0.w = rsqrt(max(r0.w, FLT_EPSILON));
  r3.xyz = r3.xyz * r0.w;
  r0.w = dot(r3.xyz, r1.xyz);
  r0.w = r0.w + r0.w;
  r1.xyz = r1.xyz * -r0.w + r3.xyz;
  r0.w = dot(r1.xyz, float3(0.0890870839,0.445435405,-0.89087081));
  r0.w = pow(max(0, r0.w), 50.0);
  r1.x = dot(r1.xyz, float3(-0.0890870839,-0.445435405,-0.89087081));
  r1.x = pow(max(0, r1.x), 50.0);
  r0.xyz = r0.w * float3(0.15,0.1,0.1) + r0.xyz;
  r0.xyz = r1.x * float3(0.1,0.1,0.15) + r0.xyz;
  r0.xyz = r0.xyz + -r2.xyz;
  r0.xyz = register0.z * r0.xyz + r2.xyz;
  o0.xyz = pow(abs(r0.xyz), register2.xyz) * sign(r0.xyz); // Luma: fixed nans
  o0.w = 1;
}