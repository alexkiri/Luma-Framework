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

cbuffer StreamDeclBuffer : register(b3)
{
  float4 NormalScaleOffset : packoffset(c0);
  float4 TexcoordScales : packoffset(c1);
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
  out float4 o1 : COLOR0,
  out float4 o2 : TEXCOORD0)
{
  float4 r0,r1,r2;
  r0.xyzw = float4(v2.xyz, 1.0);
  r1.xyzw = WorldViewProject._m10_m11_m12_m13 * dot(InstanceParams[1].xyzw /*w is relevant*/, r0.xyzw); // y is relevant
  r1.xyzw = dot(InstanceParams[0].xyzw /*x and w are relevant*/, r0.xyzw) * WorldViewProject._m00_m01_m02_m03 /*x is relevant*/ + r1.xyzw;
  r0.xyzw = dot(SkinMatrices[0]._m00_m01_m02_m03, r0.xyzw) * WorldViewProject._m20_m21_m22_m23 + r1.xyzw; // xy become relevant
  // Offsets from the pivot
  // x is x (horizontal)
  // y is y (vertical)
  // For example, the main menu is already correctly scaled to look of the same size independently of the screen resolution,
  // but in game 2D UI is broken and becomes tiny at 4k.
  //r0.xy *= LumaSettings.DevSetting06;
  //r0.z *= LumaSettings.DevSetting06;
  //r0.w *= LumaSettings.DevSetting03;
  float4 projection = WorldViewProject._m30_m31_m32_m33;
#if 0
  projection.xy += float2(LumaSettings.DevSetting05, LumaSettings.DevSetting06);
  projection = (projection + 1.0) * 0.5;
  projection *= float4(LumaSettings.DevSetting01, LumaSettings.DevSetting02, LumaSettings.DevSetting03, LumaSettings.DevSetting04);
  projection = projection * 2.0 - 1.0;
#endif
  o0.xyzw = projection + r0.xyzw;
  //o0 *= float4(LumaSettings.DevSetting07, LumaSettings.DevSetting08, LumaSettings.DevSetting09, LumaSettings.DevSetting10);

  float2 ndcXY = o0.xy / o0.w;
  bool2 anchoredToEdge = abs(ndcXY) > 0.5;
  //ndcXY += float2(LumaSettings.DevSetting05, LumaSettings.DevSetting06);
  //ndcXY *= anchoredToEdge ? float2(1.f * 0.5f, 1.f * 0.5f) : float2(1.f, 1.f);
  //ndcXY *= anchoredToEdge.y ? 0.5f : 1.f;
  ndcXY -= (anchoredToEdge ? float2(1.f * 0.5f, 1.f * 0.5f) : float2(0.f, 0.f)) * sign(ndcXY);
  //ndcXY *= lerp(1, 0, saturate(abs(ndcXY))); // Bring it back towards the center more and more as it gets further away from the center.
  ndcXY *= lerp(1, 2, LumaSettings.DevSetting07);
  o0.xy = ndcXY * o0.w;

  //o0.w += float2(LumaSettings.DevSetting06, LumaSettings.DevSetting03).x;
  o1.xyzw = v0.xyzw;
  o2.xy = TexcoordScales.x * v1.xy;
  o2.zw = float2(0,0);
  //o0.xyzw *= lerp(1, 2, LumaSettings.DevSetting08);
  //o1.xyzw *= lerp(1, 2, LumaSettings.DevSetting09); // The color
  //o2.xyzw *= lerp(1, 2, LumaSettings.DevSetting10); // The font or sprite UV
}