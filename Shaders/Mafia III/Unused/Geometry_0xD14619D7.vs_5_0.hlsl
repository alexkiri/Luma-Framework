#include "Includes/Common.hlsl"

cbuffer cb1 : register(b1)
{
  float4 cb1[26];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[4];
}

#define cmp -

void main(
  uint4 v0 : POSITION0,
  uint4 v1 : TANGENT0,
  out float4 o0 : SV_Position0)
{
  float4 r0,r1,r2;
  r0.xy = (uint2)v1.xy;
  r0.w = cmp(r0.y >= 128);
  r0.w = r0.w ? -128 : -0;
  r0.z = r0.y + r0.w;
  r0.yw = float2(1, 256) * cb0[0].w;
  r1.z = dot(r0.xz, r0.yw);
  r2.xyzw = (uint4)v0.xyzw;
  r1.x = dot(r2.xy, r0.yw);
  r1.y = dot(r2.zw, r0.yw);
  r0.xyz = cb0[0].xyz + r1.xyz;
  r0.w = 1;
  //cb1[22].w += DVS9 / 5.0;
  //cb1[23].w += DVS10 / 5.0;
  r1.x = dot(cb0[1].xyzw, r0.xyzw);
  r1.y = dot(cb0[2].xyzw, r0.xyzw);
  r1.z = dot(cb0[3].xyzw, r0.xyzw);
  r1.w = 1;
  o0.x = dot(cb1[22].xyzw, r1.xyzw);
  o0.y = dot(cb1[23].xyzw, r1.xyzw);
  o0.z = dot(cb1[24].xyzw, r1.xyzw);
  o0.w = dot(cb1[25].xyzw, r1.xyzw);

  //o0.x += DVS9 / 5.0;
  //o0.y += DVS10 / 5.0;
}