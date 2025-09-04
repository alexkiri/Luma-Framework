#include "Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

cbuffer _Globals : register(b0)
{
  float PostProcessEffectCommon_hlsl_DepthDesaturate_PSMain00000000000000000000000000000000_0bits : packoffset(c0) = {0};
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

SamplerState s_sceneDepth_s : register(s0);
SamplerState s_framebuffer_s : register(s1);
Texture2D<float4> s_framebuffer : register(t0);
Texture2D<float4> s_sceneDepth : register(t1);

void main(
  float2 v0 : TEXCOORD6,
  float2 w0 : TEXCOORD7,
  out float4 o0 : SV_Target0)
{
  float4 r0;
  r0.xyzw = s_sceneDepth.SampleLevel(s_sceneDepth_s, v0.xy, 0).xyzw;
  r0.y = (r0.x >= 0.01);
  r0.y = r0.y ? 1.0 : 0.0;
  r0.z = 1.0 - wToZScaleAndBias.z;
  r0.y = r0.y * r0.z + wToZScaleAndBias.z;
  r0.x = r0.x * r0.y - wToZScaleAndBias.x;
  r0.x = wToZScaleAndBias.y / r0.x;
  float distanceDesaturation = saturate(r0.x / DesaturationFarDistance);
  float4 sceneColor = s_framebuffer.Sample(s_framebuffer_s, v0.xy).xyzw;
  float colorLuminance = GetLuminance(gamma_to_linear(sceneColor.xyz, GCT_MIRROR)); // Luma: fixed BT.601 luminance and it being calculated in gamma space (even if "ENABLE_LUMA" is off yes)
  // Weird desaturation + color filter formula. For now we do this even if "ENABLE_COLOR_GRADING" as it's essential for gameplay feedback.
#if ENABLE_LUMA && 0 // Do it in linear for higher quality (seems broken)
  sceneColor.rgb = gamma_to_linear(sceneColor.rgb, GCT_MIRROR);
  o0.xyz = ((colorLuminance - sceneColor.rgb - gamma_to_linear(DesaturationColor.xyz, GCT_MIRROR)) * DepthSaturationLevel * Alpha * distanceDesaturation) + sceneColor.rgb;
  o0.xyz = linear_to_gamma(o0.xyz, GCT_MIRROR);
#else
  colorLuminance = linear_to_gamma1(max(colorLuminance, 0.0));
  o0.xyz = ((colorLuminance - sceneColor.rgb - DesaturationColor.xyz) * DepthSaturationLevel * Alpha * distanceDesaturation) + sceneColor.rgb;
#endif
#if ENABLE_LUMA
  FixColorGradingLUTNegativeLuminance(o0.rgb); // The formula above generated a ton of invalid (negative) colors and looked awful in HDR, this should at least shift them towards a nicer valid color
#endif
  o0.w = sceneColor.a;
}