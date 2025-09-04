#include "Includes/Common.hlsl"

cbuffer _Globals : register(b0)
{
  float PostProcessEffectCommon_hlsl_Desaturate_PSMain00000000000000000000000000000000_0bits : packoffset(c0) = {0};
  float4 fogColor : packoffset(c1);
  float3 fogTransform : packoffset(c2);
  float2 fogLuminance : packoffset(c3);
  row_major float3x4 screenDataToCamera : packoffset(c4);
  float globalScale : packoffset(c7);
  float sceneDepthAlphaMask : packoffset(c7.y);
  float globalOpacity : packoffset(c7.z);
  float distortionBufferScale : packoffset(c7.w);
  float3 wToZScaleAndBias : packoffset(c8);
  float4 screenTransform[2] : packoffset(c9);
  float Alpha : packoffset(c11);
  float Time : packoffset(c11.y);
  float DistanceFromSource : packoffset(c11.z);
  float MaxBlurNearDepth : packoffset(c11.w);
  float MaxBlurFarDepth : packoffset(c12);
  float FocalDepth : packoffset(c12.y);
  float BlurMultiplier : packoffset(c12.z);
  float4 NightVisionColor : packoffset(c13);
  float NightVisionBrightness : packoffset(c14);
  row_major float4x4 NightVisionColorTransform : packoffset(c15);
  float SaturationLevel : packoffset(c19);
  float DepthSaturationLevel : packoffset(c19.y);
  float4 DesaturationColor : packoffset(c20);
  float DesaturationFarDistance : packoffset(c21);
  float ManualToneMapExposure : packoffset(c21.y);
  float DoubleVisionConstantMagnitude : packoffset(c21.z);
  float DoubleVisionVariableMagnitude : packoffset(c21.w);
  float DoubleVisionSpinSpeed : packoffset(c22);
  float Desaturation : packoffset(c22.y);
  float Toning : packoffset(c22.z);
  float4 LightColor : packoffset(c23);
  float4 DarkColor : packoffset(c24);
  float FarDistance : packoffset(c25);
  float4 FogColor : packoffset(c26);
  float Threshold : packoffset(c27);
  float Boost : packoffset(c27.y);
}

SamplerState s_framebuffer_s : register(s0);
Texture2D<float4> s_framebuffer : register(t0);

void main(
  float2 v0 : TEXCOORD6,
  float2 w0 : TEXCOORD7,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xyzw = s_framebuffer.Sample(s_framebuffer_s, v0.xy).xyzw;
  r1.x = GetLuminance(r0.xyz); // Luma: fixed BT.601 luminance
  r1.xyz = r1.xxx + -r0.xyz;
  r1.xyz = SaturationLevel * r1.xyz;
  o0.xyz = r1.xyz * Alpha + r0.xyz;
  o0.w = r0.w;
}