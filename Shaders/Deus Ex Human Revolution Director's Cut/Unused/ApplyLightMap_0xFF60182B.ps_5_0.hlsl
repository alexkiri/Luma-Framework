#include "Includes/Common.hlsl"

cbuffer SceneBuffer : register(b2)
{
  row_major float4x4 View : packoffset(c0);
  row_major float4x4 ScreenMatrix : packoffset(c4);
  float2 DepthExportScale : packoffset(c8);
  float2 FogScaleOffset : packoffset(c9);
  float3 CameraPosition : packoffset(c10);
  float3 CameraDirection : packoffset(c11);
  float3 DepthFactors : packoffset(c12);
  float2 ShadowDepthBias : packoffset(c13);
  float4 SubframeViewport : packoffset(c14);
  row_major float3x4 DepthToWorld : packoffset(c15);
  float4 DepthToView : packoffset(c18);
  float4 OneOverDepthToView : packoffset(c19);
  float4 DepthToW : packoffset(c20);
  float4 ClipPlane : packoffset(c21);
  float2 ViewportDepthScaleOffset : packoffset(c22);
  float2 ColorDOFDepthScaleOffset : packoffset(c23);
  float2 TimeVector : packoffset(c24);
  float3 HeightFogParams : packoffset(c25);
  float3 GlobalAmbient : packoffset(c26);
  float4 GlobalParams[16] : packoffset(c27);
  float DX3_SSAOScale : packoffset(c43);
  float4 ScreenExtents : packoffset(c44);
  float2 ScreenResolution : packoffset(c45);
  float4 PSSMToMap1Lin : packoffset(c46);
  float4 PSSMToMap1Const : packoffset(c47);
  float4 PSSMToMap2Lin : packoffset(c48);
  float4 PSSMToMap2Const : packoffset(c49);
  float4 PSSMToMap3Lin : packoffset(c50);
  float4 PSSMToMap3Const : packoffset(c51);
  float4 PSSMDistances : packoffset(c52);
  row_major float4x4 WorldToPSSM0 : packoffset(c53);
  float StereoOffset : packoffset(c25.w);
}

cbuffer LightBuffer : register(b4)
{
  struct
  {
    float4 position;
    float3 direction;
    float4 attParams;
    float4 spotParams;
    float4 diffuseColor;
    float4 shadowFadeParams;
  } ShadowLights[3] : packoffset(c0);

  struct
  {
    float4 position;
    float3 direction;
    float4 attParams;
    float4 spotParams;
    float4 diffuseColor;
    float4 shadowFadeParams;
  } NonShadowLights[3] : packoffset(c18);

  struct
  {
    float4 position;
    float3 direction;
    float4 attParams;
    float4 spotParams;
    float4 diffuseColor;
    float4 shadowFadeParams;
  } SunLight : packoffset(c36);

  row_major float4x4 WorldToShadowMap[3] : packoffset(c42);
  row_major float3x4 WorldToModulationMapSpot[2] : packoffset(c54);
  row_major float2x4 WorldToModulationMapSun : packoffset(c60);
  bool ShadowLightEnabled[3] : packoffset(c62);
  bool NonShadowLightEnabled[3] : packoffset(c65);
  bool SunLightEnabled : packoffset(c68);
}

SamplerState DepthSampler_s : register(s1);
SamplerComparisonState ShadowMapSampler_sampler_s : register(s14);
Texture2D<float4> DepthTexture : register(t1);
Texture2D<float4> ShadowMapSampler_texture : register(t14);

#define cmp -

void main(
  float4 v0 : SV_POSITION0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11;
  r0.xy = v0.xy * ScreenExtents.zw + ScreenExtents.xy;
  r0.z = DepthTexture.SampleLevel(DepthSampler_s, r0.xy, 0).x;
  r0.z = r0.z * DepthToW.x + DepthToW.y;
  r0.z = max(9.99999997e-007, r0.z);
  r1.z = 1 / r0.z;
  r1.xy = r1.zz * r0.xy;
  r1.w = 1;
  r0.x = dot(DepthToWorld._m00_m01_m02_m03, r1.xyzw);
  r0.y = dot(DepthToWorld._m10_m11_m12_m13, r1.xyzw);
  r0.z = dot(DepthToWorld._m20_m21_m22_m23, r1.xyzw);
  if (SunLightEnabled != 0) {
    r1.xyzw = WorldToPSSM0._m10_m11_m12_m13 * r0.yyyy;
    r1.xyzw = r0.xxxx * WorldToPSSM0._m00_m01_m02_m03 + r1.xyzw;
    r1.xyzw = r0.zzzz * WorldToPSSM0._m20_m21_m22_m23 + r1.xyzw;
    r1.xyzw = WorldToPSSM0._m30_m31_m32_m33 + r1.xyzw;
    r2.xyzw = cmp(r1.wwww < PSSMDistances.yzwx);
    r3.xyz = r2.xxx ? PSSMToMap1Lin.xyz : float3(1,1,1);
    r4.xyz = r2.xxx ? PSSMToMap1Const.xyz : 0;
    r3.xyz = r2.yyy ? PSSMToMap2Lin.xyz : r3.xyz;
    r4.xyz = r2.yyy ? PSSMToMap2Const.xyz : r4.xyz;
    r3.xyz = r2.zzz ? PSSMToMap3Lin.xyz : r3.xyz;
    r2.xyz = r2.zzz ? PSSMToMap3Const.xyz : r4.xyz;
    r1.xyz = r1.xyz * r3.xyz + r2.xyz;
    r3.xyzw = r1.yxxx * float4(3072,4096,4096,4096) + float4(0.5,0.5,0.5,0.5);
    r1.xy = floor(r3.wx);
    r3.xyzw = -r1.yxxx + r3.xyzw;
    r1.xy = float2(0.000244140625,0.000325520843) * r1.xy;
    r4.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(-2,-2)).xyzw;
    r5.xyzw = float4(1,1,2,9) + -r3.xyzw;
    r6.xyzw = r5.yzyz * r4.wzxy;
    r2.xy = r6.xz + r6.yw;
    r6.x = r2.x * r5.x;
    r6.y = r2.y * r3.x;
    r0.w = dot(r6.xy, float2(1,1));
    r6.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(0,-2)).xyzw;
    r7.xyzw = r6.wzxy + r6.wzxy;
    r2.xy = r7.xz + r7.yw;
    r7.x = r2.x * r5.x;
    r7.y = r2.y * r3.x;
    r1.w = dot(r7.xy, float2(1,1));
    r0.w = r1.w + r0.w;
    r7.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(2,-2)).xyzw;
    r2.xyz = float3(1,8,7) + r3.www;
    r3.yz = r7.zy * r3.ww;
    r3.yz = r7.wx * r2.xx + r3.yz;
    r8.x = r3.y * r5.x;
    r8.y = r3.z * r3.x;
    r1.w = dot(r8.xy, float2(1,1));
    r0.w = r1.w + r0.w;
    r8.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(-2,0)).xyzw;
    r9.xyzw = r3.wwww * float4(-2,-6,-5,6) + float4(2,8,7,2);
    r10.xyzw = r9.xyxy * r8.wzxy;
    r3.yz = r10.xz + r10.yw;
    r11.x = r3.y * r5.x;
    r11.y = r3.z * r3.x;
    r1.w = dot(r11.xy, float2(1,1));
    r0.w = r1.w + r0.w;
    r3.yz = r9.xz * r4.xy;
    r1.w = r3.y + r3.z;
    r4.x = r1.w * r5.x;
    r3.yz = r8.zy * r9.zz + r10.xz;
    r4.y = r3.y * r3.x;
    r8.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(0,0)).xyzw;
    r10.xyzw = r8.zyzy * r2.yyzz;
    r6.zw = r8.wx * r5.ww + r10.xy;
    r4.z = r6.z * r5.x;
    r4.w = r6.w * r3.x;
    r1.w = dot(r4.xyzw, float4(1,1,1,1));
    r0.w = r1.w + r0.w;
    r1.w = 8 + -r3.w;
    r2.y = r2.z * r6.y;
    r2.y = r6.x * r1.w + r2.y;
    r4.x = r2.y * r5.x;
    r6.xy = r8.wx * r1.ww + r10.zw;
    r4.y = r6.x * r3.x;
    r8.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(2,0)).xyzw;
    r2.y = r3.w + r3.w;
    r6.xz = r2.yy * r8.zy;
    r7.zw = r8.wx * r9.ww + r6.xz;
    r4.z = r7.z * r5.x;
    r4.w = r7.w * r3.x;
    r3.y = dot(r4.xyzw, float4(1,1,1,1));
    r0.w = r3.y + r0.w;
    r3.y = r3.w * 5 + 2;
    r4.x = r2.y * r7.y;
    r4.x = r7.x * r3.y + r4.x;
    r4.x = r4.x * r5.x;
    r4.zw = r8.wx * r3.yy + r6.xz;
    r4.y = r4.z * r3.x;
    r4.x = dot(r4.xy, float2(1,1));
    r0.w = r4.x + r0.w;
    r7.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(-2,2)).xyzw;
    r8.xyzw = r7.wzxy * r5.yzyz;
    r4.xy = r8.xz + r8.yw;
    r7.x = r4.x * r5.x;
    r7.y = r4.y * r3.x;
    r4.x = dot(r7.xy, float2(1,1));
    r0.w = r4.x + r0.w;
    r8.x = r3.z * r5.x;
    r4.xy = r7.wz * r9.xz;
    r3.z = r4.x + r4.y;
    r8.y = r3.z * r3.x;
    r7.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(0,2)).xyzw;
    r9.xyzw = r7.wzxy + r7.wzxy;
    r4.xy = r9.xz + r9.yw;
    r8.z = r4.x * r5.x;
    r8.w = r4.y * r3.x;
    r3.z = dot(r8.xyzw, float4(1,1,1,1));
    r0.w = r3.z + r0.w;
    r6.x = r6.y * r5.x;
    r2.z = r7.z * r2.z;
    r1.w = r7.w * r1.w + r2.z;
    r6.y = r1.w * r3.x;
    r1.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(2,2)).xyzw;
    r3.zw = r1.zy * r3.ww;
    r1.xy = r1.wx * r2.xx + r3.zw;
    r6.z = r1.x * r5.x;
    r6.w = r1.y * r3.x;
    r1.x = dot(r6.xyzw, float4(1,1,1,1));
    r0.w = r1.x + r0.w;
    r1.x = r4.w * r5.x;
    r1.z = r1.z * r2.y;
    r1.z = r1.w * r3.y + r1.z;
    r1.y = r1.z * r3.x;
    r1.x = dot(r1.xy, float2(1,1));
    r0.w = r1.x + r0.w;
    r0.w = 0.010309278 * r0.w;
    r0.w = r2.w ? r0.w : 0;
  } else {
    r1.xyzw = WorldToShadowMap[0]._m10_m11_m12_m13 * r0.yyyy;
    r1.xyzw = r0.xxxx * WorldToShadowMap[0]._m00_m01_m02_m03 + r1.xyzw;
    r1.xyzw = r0.zzzz * WorldToShadowMap[0]._m20_m21_m22_m23 + r1.xyzw;
    r1.xyzw = WorldToShadowMap[0]._m30_m31_m32_m33 + r1.xyzw;
    r0.xyz = -CameraPosition.xyz + r0.xyz;
    r0.x = dot(r0.xyz, CameraDirection.xyz);
    r0.xy = saturate(r0.xx * ShadowLights[0].shadowFadeParams.xy + ShadowLights[0].shadowFadeParams.zw);
    r2.xyzw = r1.yxxx / r1.wwww;
    r2.xyzw = r2.xyzw * float4(3072,4096,4096,4096) + float4(0.5,0.5,0.5,0.5);
    r1.xy = floor(r2.wx);
    r2.xyzw = -r1.yxxx + r2.xyzw;
    r1.xy = float2(0.000244140625,0.000325520843) * r1.xy;
    r3.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(-2,-2)).xyzw;
    r4.xyzw = float4(1,1,2,9) + -r2.xyzw;
    r5.xyzw = r4.yzyz * r3.wzxy;
    r2.yz = r5.xz + r5.yw;
    r5.x = r2.y * r4.x;
    r5.y = r2.z * r2.x;
    r0.z = dot(r5.xy, float2(1,1));
    r5.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(0,-2)).xyzw;
    r6.xyzw = r5.wzxy + r5.wzxy;
    r2.yz = r6.xz + r6.yw;
    r6.x = r2.y * r4.x;
    r6.y = r2.z * r2.x;
    r1.w = dot(r6.xy, float2(1,1));
    r0.z = r1.w + r0.z;
    r6.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(2,-2)).xyzw;
    r7.xyz = float3(1,8,7) + r2.www;
    r2.yz = r6.zy * r2.ww;
    r2.yz = r6.wx * r7.xx + r2.yz;
    r8.x = r2.y * r4.x;
    r8.y = r2.z * r2.x;
    r1.w = dot(r8.xy, float2(1,1));
    r0.z = r1.w + r0.z;
    r8.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(-2,0)).xyzw;
    r9.xyzw = r2.wwww * float4(-2,-6,-5,6) + float4(2,8,7,2);
    r10.xyzw = r9.xyxy * r8.wzxy;
    r2.yz = r10.xz + r10.yw;
    r11.x = r2.y * r4.x;
    r11.y = r2.z * r2.x;
    r1.w = dot(r11.xy, float2(1,1));
    r0.z = r1.w + r0.z;
    r2.yz = r9.xz * r3.xy;
    r1.w = r2.y + r2.z;
    r3.x = r1.w * r4.x;
    r2.yz = r8.zy * r9.zz + r10.xz;
    r3.y = r2.y * r2.x;
    r8.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(0,0)).xyzw;
    r10.xyzw = r8.zyzy * r7.yyzz;
    r5.zw = r8.wx * r4.ww + r10.xy;
    r3.z = r5.z * r4.x;
    r3.w = r5.w * r2.x;
    r1.w = dot(r3.xyzw, float4(1,1,1,1));
    r0.z = r1.w + r0.z;
    r1.w = 8 + -r2.w;
    r2.y = r7.z * r5.y;
    r2.y = r5.x * r1.w + r2.y;
    r3.x = r2.y * r4.x;
    r5.xy = r8.wx * r1.ww + r10.zw;
    r3.y = r5.x * r2.x;
    r8.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(2,0)).xyzw;
    r2.y = r2.w + r2.w;
    r5.xz = r2.yy * r8.zy;
    r6.zw = r8.wx * r9.ww + r5.xz;
    r3.z = r6.z * r4.x;
    r3.w = r6.w * r2.x;
    r3.x = dot(r3.xyzw, float4(1,1,1,1));
    r0.z = r3.x + r0.z;
    r3.x = r2.w * 5 + 2;
    r3.y = r2.y * r6.y;
    r3.y = r6.x * r3.x + r3.y;
    r6.x = r3.y * r4.x;
    r3.yz = r8.wx * r3.xx + r5.xz;
    r6.y = r3.y * r2.x;
    r3.y = dot(r6.xy, float2(1,1));
    r0.z = r3.y + r0.z;
    r6.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(-2,2)).xyzw;
    r8.xyzw = r6.wzxy * r4.yzyz;
    r3.yw = r8.xz + r8.yw;
    r6.x = r3.y * r4.x;
    r6.y = r3.w * r2.x;
    r3.y = dot(r6.xy, float2(1,1));
    r0.z = r3.y + r0.z;
    r8.x = r2.z * r4.x;
    r3.yw = r6.wz * r9.xz;
    r2.z = r3.y + r3.w;
    r8.y = r2.z * r2.x;
    r6.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(0,2)).xyzw;
    r9.xyzw = r6.wzxy + r6.wzxy;
    r3.yw = r9.xz + r9.yw;
    r8.z = r3.y * r4.x;
    r8.w = r3.w * r2.x;
    r2.z = dot(r8.xyzw, float4(1,1,1,1));
    r0.z = r2.z + r0.z;
    r5.x = r5.y * r4.x;
    r2.z = r6.z * r7.z;
    r1.w = r6.w * r1.w + r2.z;
    r5.y = r1.w * r2.x;
    r1.xyzw = ShadowMapSampler_texture.GatherCmp(ShadowMapSampler_sampler_s, r1.xy, r1.z, int2(2,2)).xyzw;
    r2.zw = r1.zy * r2.ww;
    r1.xy = r1.wx * r7.xx + r2.zw;
    r5.z = r1.x * r4.x;
    r5.w = r1.y * r2.x;
    r1.x = dot(r5.xyzw, float4(1,1,1,1));
    r0.z = r1.x + r0.z;
    r1.x = r3.z * r4.x;
    r1.z = r1.z * r2.y;
    r1.z = r1.w * r3.x + r1.z;
    r1.y = r1.z * r2.x;
    r1.x = dot(r1.xy, float2(1,1));
    r0.z = r1.x + r0.z;
    r0.x = r0.z * r0.x;
    r0.w = r0.x * 0.010309278 + r0.y;
  }
#if 0 // TEST: boost intensity
  r0.w = sqrt(r0.w) * 2;
#endif
  o0.xyzw = r0.w;
#if 0 // Disable light (all shadow)
  o0.xyzw = 0.0;
#endif
#if 0 // Full light (no shadow)
  o0.xyzw = 1.0; // It seems like only x actually matters
#endif
}