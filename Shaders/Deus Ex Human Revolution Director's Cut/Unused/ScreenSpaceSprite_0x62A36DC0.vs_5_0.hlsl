#include "Includes/Common.hlsl"

cbuffer WorldBuffer : register(b0)
{
  row_major float4x4 WorldViewProject : packoffset(c0);
  row_major float4x4 World : packoffset(c4);
  row_major float4x4 ViewProject : packoffset(c8);
}

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
}

cbuffer StreamDeclBuffer : register(b3)
{
  float4 NormalScaleOffset : packoffset(c0);
  float4 TexcoordScales : packoffset(c1);
}

void main(
  float4 v0 : COLOR0,
  float4 v1 : TEXCOORD0,
  float3 v2 : POSITION0,
  out float4 o0 : SV_POSITION0,
  out float4 o1 : COLOR0,
  out float4 o2 : TEXCOORD0)
{
  float scale = DVS3*2;
  v2.x = (v2.x - 0.5) * scale + 0.5; 
  float4 r0,r1;
  r0.xyzw = World._m10_m11_m12_m13 * v2.yyyy;
  r0.xyzw = v2.xxxx * World._m00_m01_m02_m03 + r0.xyzw;
  r0.xyzw = v2.zzzz * World._m20_m21_m22_m23 + r0.xyzw;
  r0.xyzw = World._m30_m31_m32_m33 + r0.xyzw;
  r0.x = (r0.x - 0.5) * (DVS4*2) + 0.5; 

  r1.xyzw = ScreenMatrix._m10_m11_m12_m13 * r0.yyyy;
  r1.xyzw = r0.xxxx * ScreenMatrix._m00_m01_m02_m03 + r1.xyzw;
  r1.xyzw = r0.zzzz * ScreenMatrix._m20_m21_m22_m23 + r1.xyzw;
  r0.xyzw = r0.wwww * ScreenMatrix._m30_m31_m32_m33 + r1.xyzw;
  o0.xy = r0.xy * r0.ww;
  o0.zw = r0.zw;
  o0.x = (o0.x - 0.5) * (DVS1*2) + 0.5;
  o1.xyzw = v0.zyxw;
  v1.x = (v1.x - 0.5) * (DVS7*2) + 0.5; // NOTE: this is the one to scale for UW, but it doesn't work well...
  o2.xy = TexcoordScales.xx * v1.xy;
  o2.x = (o2.x - 0.5) * (DVS6*2) + 0.5;
  o2.zw = float2(0,0);
  // if (o2.x < 0.0 || o2.x > 1)
  //   o0.w = -1.0;
}