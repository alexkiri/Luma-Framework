#define LUT_SIZE 16.0
#define LUT_MAX (LUT_SIZE - 1.0)

#include "Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

cbuffer _Globals : register(b0)
{
  float4 SceneShadowsAndDesaturation : packoffset(c0);
  float4 SceneInverseHighLights : packoffset(c1);
  float4 SceneMidTones : packoffset(c2);
  float4 SceneScaledLuminanceWeights : packoffset(c3);
  float4 GammaColorScaleAndInverse : packoffset(c4);
  float4 GammaOverlayColor : packoffset(c5);
  float4 RenderTargetExtent : packoffset(c6);
  float2 DownsampledDepthScale : packoffset(c7);
  float Weights[5] : packoffset(c8);
}

void main(
  float2 v0 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xz = float2(-0.001953125,-0.03125) + v0.xy;
  r1.x = LUT_SIZE * r0.x;
  r0.y = frac(r1.x);
  r0.w = -r0.y / LUT_SIZE + r0.x;
  r0.xyz = Weights[0] * r0.yzw;
  r0.xyz = saturate(r0.xyz * float3(1.06666672,1.06666672,1.06666672) + -SceneShadowsAndDesaturation.xyz);
  r0.xyz = SceneInverseHighLights.xyz * r0.xyz;
  r0.xyz = max(float3(9.99999994e-009,9.99999994e-009,9.99999994e-009), r0.xyz);
  r0.xyz = log2(r0.xyz);
  r0.xyz = SceneMidTones.xyz * r0.xyz;
  r0.xyz = exp2(r0.xyz);
  r0.w = dot(r0.xyz, SceneScaledLuminanceWeights.xyz);
  r0.xyz = r0.xyz * SceneShadowsAndDesaturation.www + r0.www;
  r0.xyz = saturate(r0.xyz * GammaColorScaleAndInverse.xyz + GammaOverlayColor.xyz);
  r0.xyz = max(float3(9.99999994e-009,9.99999994e-009,9.99999994e-009), r0.xyz);
  r0.xyz = log2(r0.xyz);
  r0.w = 2.2 * GammaColorScaleAndInverse.w; // User gamma (1/2.2 by default)
  r0.xyz = r0.www * r0.xyz;
  r0.xyz = exp2(r0.xyz);
  o0.w = GetLuminance(r0.xyz); // Fixed BT.601 luminance
  o0.xyz = r0.xyz;
}