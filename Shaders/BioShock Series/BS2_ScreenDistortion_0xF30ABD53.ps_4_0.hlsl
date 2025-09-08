cbuffer _Globals : register(b0)
{
  float PostProcessEffectCommon_hlsl_DoubleVision_PSMain00000000000000000000000000000000_0bits : packoffset(c0) = {0};
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

// Luma: unchanged
void main(
  float2 v0 : TEXCOORD6,
  float2 w0 : TEXCOORD7,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;
  r0.x = dot(v0.xy, v0.xy);
  r0.x = rsqrt(r0.x);
  r0.xy = v0.xy * r0.xx;
  r0.z = DoubleVisionSpinSpeed * Time;
  sincos(r0.z, r1.x, r2.x);
  r1.y = r2.x;
  r0.z = dot(r1.xy, r1.xy);
  r0.z = rsqrt(r0.z);
  r0.zw = r1.xy * r0.zz;
  r1.z = dot(r0.zzww, r0.xxyy);
  r0.xy = -r1.zz * r0.zw + r0.xy;
  sincos(Time, r2.x, r3.x);
  r0.z = 1 + r2.x;
  r0.w = 1 + r3.x;
  r0.w = -r0.w * 0.5 + 1;
  r0.z = 0.5 * r0.z;
  r1.z = DoubleVisionConstantMagnitude * Alpha;
  r0.z = r0.z * DoubleVisionVariableMagnitude + r1.z;
  r0.xy = r0.xy * r0.zz;
  r1.xy = r1.xy * r0.zz;
  r1.zw = float2(-0.5,-0.5) + w0.xy;
  r1.zw = float2(0.5,0.5) + -abs(r1.zw);
  r2.xy = -r0.xy * r1.zw + v0.xy;
  r0.xy = r0.xy * r1.zw + v0.xy;
  r3.xyzw = s_framebuffer.Sample(s_framebuffer_s, r0.xy).xyzw;
  r2.xyzw = s_framebuffer.Sample(s_framebuffer_s, r2.xy).xyzw;
  r2.xyzw = r2.xyzw - r3.xyzw;
  r2.xyzw = r2.xyzw * 0.5 + r3.xyzw;
  r0.xy = -r1.xy * r1.zw + v0.xy;
  r1.xy = r1.xy * r1.zw + v0.xy;
  r1.xyzw = s_framebuffer.Sample(s_framebuffer_s, r1.xy).xyzw;
  r3.xyzw = s_framebuffer.Sample(s_framebuffer_s, r0.xy).xyzw;
  r3.xyzw = r3.xyzw - r1.xyzw;
  r1.xyzw = r3.xyzw * 0.5 + r1.xyzw;
  r1.xyzw = r1.xyzw - r2.xyzw;
  o0.xyzw = r0.wwww * r1.xyzw + r2.xyzw;
}