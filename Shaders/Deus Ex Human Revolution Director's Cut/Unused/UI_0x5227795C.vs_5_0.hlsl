#include "../Includes/Common.hlsl"

cbuffer WorldBuffer : register(b0)
{
  row_major float4x4 WorldViewProject : packoffset(c0);
  row_major float4x4 World : packoffset(c4);
  row_major float4x4 ViewProject : packoffset(c8);
}

cbuffer SkinningBuffer : register(b1)
{
  row_major float4x4 SkinMatrices[42] : packoffset(c0);
}

cbuffer InstanceBuffer : register(b5)
{
  float4 InstanceParams[8] : packoffset(c0);
}

void main(
  float4 v0 : COLOR0,
  float4 v1 : TEXCOORD0,
  float3 v2 : POSITION0,
  out float4 o0 : SV_POSITION0,
  out float4 o1 : TEXCOORD0)
{
  float4 r0,r1,r2;
  r0.xyz = v2.xyz;
  r0.w = 1;
  r1.x = dot(InstanceParams[1].xyzw, r0.xyzw);
  r1.xyzw = WorldViewProject._m10_m11_m12_m13 * r1.x;
  r2.x = dot(InstanceParams[0].xyzw, r0.xyzw);
  r1.xyzw = r2.x * WorldViewProject._m00_m01_m02_m03 + r1.xyzw;
  r2.x = dot(SkinMatrices[0]._m00_m01_m02_m03, r0.xyzw);
  r1.xyzw = r2.x * WorldViewProject._m20_m21_m22_m23 + r1.xyzw;
  o0.xyzw = WorldViewProject._m30_m31_m32_m33 * float4(LumaSettings.DevSetting07, LumaSettings.DevSetting08, LumaSettings.DevSetting09, LumaSettings.DevSetting10) + r1.xyzw;
  o1.x = dot(r0.xyzw, InstanceParams[2].xyzw);
  o1.y = dot(r0.xyzw, InstanceParams[3].xyzw);
  o1.zw = float2(0,0);
  
  float2 ndcXY = o0.xy / o0.w;
  bool2 anchoredToEdge = abs(ndcXY) > 0.5;
  //ndcXY += float2(LumaSettings.DevSetting05, LumaSettings.DevSetting06);
  //ndcXY *= anchoredToEdge ? float2(1.f * 0.5f, 1.f * 0.5f) : float2(1.f, 1.f);
  //ndcXY *= anchoredToEdge.y ? 0.5f : 1.f;
  ndcXY -= (anchoredToEdge ? float2(1.f * 0.5f, 1.f * 0.5f) : float2(0.f, 0.f)) * sign(ndcXY);
  //ndcXY *= lerp(1, 0, saturate(abs(ndcXY))); // Bring it back towards the center more and more as it gets further away from the center.
  ndcXY *= lerp(1, 2, LumaSettings.DevSetting07);
  o0.xy = ndcXY * o0.w;
}