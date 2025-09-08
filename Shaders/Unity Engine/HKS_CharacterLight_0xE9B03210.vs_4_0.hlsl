#include "../Includes/Common.hlsl"

cbuffer cb2 : register(b2)
{
  float4 cb2[21];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[4];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}

void main(
  float4 v0 : POSITION0,
  float4 v1 : COLOR0,
  float2 v2 : TEXCOORD0,
  out float4 o0 : SV_POSITION0,
  out float4 o1 : COLOR0,
  out float2 o2 : TEXCOORD0,
  out float4 o3 : TEXCOORD1)
{
  // Luma: scale radius
  if (LumaData.CustomData1 > 0)
  {
    float radiusParam = LumaData.CustomData4;
    float radiusScaling = radiusParam >= 1.0 ? remap(radiusParam, 1.0, 2.0, 1.0, 4.0) : remap(radiusParam, 0.0, 1.0, 0.333, 1.0);
    v0.xy *= radiusScaling;
  }

  float4 r0,r1;
  r0.xyzw = cb1[1].xyzw * v0.yyyy;
  r0.xyzw = cb1[0].xyzw * v0.xxxx + r0.xyzw;
  r0.xyzw = cb1[2].xyzw * v0.zzzz + r0.xyzw;
  r0.xyzw = cb1[3].xyzw + r0.xyzw;
  r1.xyzw = cb2[18].xyzw * r0.yyyy;
  r1.xyzw = cb2[17].xyzw * r0.xxxx + r1.xyzw;
  r1.xyzw = cb2[19].xyzw * r0.zzzz + r1.xyzw;
  r0.xyzw = cb2[20].xyzw * r0.wwww + r1.xyzw;
  o0.xyzw = r0.xyzw;
  o3.xyzw = r0.xyzw;
  o1.xyzw = cb0[2].xyzw * v1.xyzw;
  o2.xy = v2.xy;
}