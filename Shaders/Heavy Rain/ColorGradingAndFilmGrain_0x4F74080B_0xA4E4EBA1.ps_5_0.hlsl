#include "../Includes/Common.hlsl"

cbuffer ConstentValue : register(b0)
{
  float4x4 register0 : packoffset(c0);
  float4 register4 : packoffset(c4);
  float4 register5 : packoffset(c5);
  float4 register6 : packoffset(c6);
  float4 register7 : packoffset(c7);
  float4 register8 : packoffset(c8);
}

SamplerState sampler0_s : register(s0);
SamplerState sampler1_s : register(s1);
Texture2D<float4> texture0 : register(t0);
Texture2D<float4> texture1 : register(t1);

#ifndef ENABLE_LUMA
#define ENABLE_LUMA 1
#endif

#ifndef ENABLE_COLOR_GRADING
#define ENABLE_COLOR_GRADING 1
#endif

#ifndef ENABLE_FILM_GRAIN
#define ENABLE_FILM_GRAIN 1
#endif

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD2,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1;

#if _A4E4EBA1 // TODO: improve grain... it's not good and it runs at 24fps or something
  float grainMax = texture1.Sample(sampler1_s, v2.zw).x;
  float grainMin = texture1.Sample(sampler1_s, v2.xy).x;
  float grainRange = grainMax - grainMin;
  float grain = (register4.x * grainRange + grainMin) - register4.y;
#if !ENABLE_FILM_GRAIN
  grain = 0.0;
#endif
#endif
  
  const float4 sceneColor = texture0.Sample(sampler0_s, v1.xy).rgba;
  o0.w = sceneColor.a * register5.x + register5.y;

#if _A4E4EBA1
  const float4 postProcessedColor = float4(sceneColor.rgb + grain * register4.z, 1.0);
#else
  const float4 postProcessedColor = float4(sceneColor.rgb, 1.0);
#endif

#if !ENABLE_COLOR_GRADING // Passthrough
  o0.rgb = postProcessedColor.rgb; return;
#endif
  
  float3 gradedSceneColor;
  float4 filter;
  filter.x = register0._m00;
  filter.y = register0._m01;
  filter.z = register0._m02;
  filter.w = register0._m03;
  gradedSceneColor.r = dot(postProcessedColor, filter.xyzw);
  filter.x = register0._m10;
  filter.y = register0._m11;
  filter.z = register0._m12;
  filter.w = register0._m13;
  gradedSceneColor.g = dot(postProcessedColor, filter.xyzw);
  filter.x = register0._m20;
  filter.y = register0._m21;
  filter.z = register0._m22;
  filter.w = register0._m23;
  gradedSceneColor.b = dot(postProcessedColor, filter.xyzw);

  const float postProcessedColorAverage = dot(postProcessedColor.rgb, 1.0 / 3.0);
  float3 shadowTint = saturate(postProcessedColorAverage * register6.xyz + register7.xyz); // Leave this saturate in as it's just a multiplier

  // This will generate colors beyond Rec.709 in the shadow
#if ENABLE_LUMA
  gradedSceneColor.rgb = (gradedSceneColor.rgb < 1) ? (1.0 - (shadowTint.rgb * (1.0 - gradedSceneColor.rgb))) : gradedSceneColor.rgb;
#else
  gradedSceneColor.rgb = saturate(gradedSceneColor.rgb);
  gradedSceneColor.rgb = 1.0 - (shadowTint.rgb * (1.0 - gradedSceneColor.rgb));
#endif

  // Gamma adjustments (usually neutral)
#if ENABLE_LUMA // Luma: scRGB support
  gradedSceneColor.rgb = pow(abs(gradedSceneColor.rgb), register8.xyz) * sign(gradedSceneColor.rgb);
#else
  gradedSceneColor.rgb = pow(gradedSceneColor.rgb, register8.xyz);
#endif
  o0.xyz = gradedSceneColor.rgb;
}