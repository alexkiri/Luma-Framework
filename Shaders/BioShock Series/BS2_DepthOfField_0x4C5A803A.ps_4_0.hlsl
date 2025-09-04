#include "Includes/Common.hlsl"

#ifndef ENABLE_DEPTH_OF_FIELD
#define ENABLE_DEPTH_OF_FIELD 1
#endif // ENABLE_DEPTH_OF_FIELD

cbuffer _Globals : register(b0)
{
  float PostProcessEffectCommon_hlsl_DOF_PSMain00000000000000000000000000000000_0bits : packoffset(c0) = {0};
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
Texture2D<float4> s_sceneDepth : register(t0);
Texture2D<float4> s_framebuffer : register(t1);

#define cmp

void main(
  float2 v0 : TEXCOORD6,
  float2 w0 : TEXCOORD7,
  out float4 o0 : SV_Target0)
{
  const float4 icb[] = { { 0.100000, -1.000000, 0, 0},
                              { 0.800000, -0.200000, 0, 0},
                              { 0.800000, 0.400000, 0, 0},
                              { 0.200000, 0.800000, 0, 0},
                              { -0.800000, 0.400000, 0, 0},
                              { -0.300000, 0.600000, 0, 0},
                              { -0.800000, -0.400000, 0, 0},
                              { -0.400000, 0.600000, 0, 0} };
  float4 r0,r1,r3;
  r0.xyzw = s_sceneDepth.SampleLevel(s_sceneDepth_s, v0.xy, 0).xyzw;
  r0.y = cmp(r0.x >= 0.01);
  r0.y = r0.y ? 1.0 : 0.0;
  r0.z = 1 + -wToZScaleAndBias.z;
  r0.y = r0.y * r0.z + wToZScaleAndBias.z;
  r0.x = r0.x * r0.y + -wToZScaleAndBias.x;
  r0.x = wToZScaleAndBias.y / r0.x;
  r0.y = FocalDepth + -r0.x;
  r0.z = FocalDepth + -MaxBlurNearDepth;
  r0.y = saturate(r0.y / r0.z);
  r0.x = -FocalDepth + r0.x;
  r0.z = MaxBlurFarDepth + -FocalDepth;
  r0.x = saturate(r0.x / r0.z);
  r0.x = r0.y + r0.x;
  r0.y = BlurMultiplier * Alpha;
  r0.x = r0.x * r0.y;
  r1.xyzw = s_framebuffer.Sample(s_framebuffer_s, v0.xy).xyzw;

  float aspectRatio = 1.0;
#if ENABLE_LUMA
  float2 sourceSize;
  s_framebuffer.GetDimensions(sourceSize.x, sourceSize.y);
  aspectRatio = sourceSize.x / sourceSize.y;
#if 1 // Make it "neutral" at 16:9, as it used to be
  aspectRatio /= 16.0 / 9.0;
#endif
#endif

#if ENABLE_DEPTH_OF_FIELD
  int4 r0i;
  r0i.y = 0;
  int iterations = 8; // Can't be changed
  while (true) {
    if (r0i.y >= iterations) break;
    r0.zw = (icb[r0i.y+0].xy * r0.x / aspectRatio) + v0.xy; // LUMA: distortion was heavily stretched in UW (and 16:9, even if theoretically that's reference, or maybe 4:3 but likely not)
    r1.xyzw += s_framebuffer.Sample(s_framebuffer_s, r0.zw).xyzw;
    r0i.y++;
  }
  o0.xyzw = r1.xyzw / float(iterations + 1);
#else
  o0.xyzw = r1.xyzw;
#endif
}