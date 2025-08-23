#include "Includes/Common.hlsl"

cbuffer cb2 : register(b2)
{
  float4 cb2[26];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[9];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[4];
}

#define cmp

void main(
  uint4 v0 : POSITION0,
  uint4 v1 : TANGENT0,
  uint4 v2 : NORMAL0,
  float4 v3 : COLOR0,
  float4 v4 : TEXCOORD0,
  float4 v5 : TEXCOORD15,
  out float4 o0 : SV_Position0,
  out float4 o1 : TEXCOORD0,
  out float4 o2 : TEXCOORD1,
  out float4 o3 : TEXCOORD2,
  out float4 o4 : TEXCOORD3,
  out float4 o5 : TEXCOORD4,
  out float4 o6 : TEXCOORD5,
  out float4 o7 : TEXCOORD6,
  out float4 o8 : TEXCOORD7)
{
  // cb2[22].x += DVS10;
  // cb2[22].y += DVS9;
  // cb2[22].z = 0;
  float4 r0,r1,r2,r3;
  r0.xyzw = (uint4)v1.xyzw;
  r1.x = cmp(r0.y >= 128);
  r1.xy = r1.xx ? float2(-128,-1) : float2(-0,1);
  r0.y = r1.x + r0.y;
  r1.xz = float2(1,256) * cb0[0].ww;
  r2.z = dot(r0.xy, r1.xz);
  r3.xyzw = (uint4)v0.xyzw;
  r2.x = dot(r3.xy, r1.xz);
  r2.y = dot(r3.zw, r1.xz);
  r2.xyz = cb0[0].xyz + r2.xyz;
  r2.w = 1;
  r3.x = dot(cb0[1].xyzw, r2.xyzw);
  r3.y = dot(cb0[2].xyzw, r2.xyzw);
  r3.z = dot(cb0[3].xyzw, r2.xyzw);
  o3.yzw = r2.xyz;
  r3.w = 1;
  r2.y = dot(cb2[24].xyzw, r3.xyzw);
  o0.z = r2.y;
  r0.y = dot(cb2[25].xyzw, r3.xyzw);
  o0.w = r0.y;
  r2.x = cb2[1].w * r0.y;
  o0.x = dot(cb2[22].xyzw, r3.xyzw);
  o0.y = dot(cb2[23].xyzw, r3.xyzw);
  o3.x = dot(cb2[2].xy, r2.xy);
  o2.yzw = r3.xyz;
  o1.w = v5.x;
  r2.xyzw = (uint4)v2.xyzw;
  r0.x = r2.w;
  r2.xyzw = r2.zxyz * float4(0.00784313772,0.00784313772,0.00784313772,0.00784313772) + float4(-1,-1,-1,-1);
  r0.xyz = r0.zwx * float3(0.00784313772,0.00784313772,0.00784313772) + float3(-1,-1,-1);
  o1.x = dot(cb0[1].xyz, r0.xyz);
  o1.y = dot(cb0[2].xyz, r0.xyz);
  o1.z = dot(cb0[3].xyz, r0.xyz);
  o2.x = v5.y;
  o4.w = dot(cb0[1].xyz, r2.yzw);
  o4.xyz = r2.yzw;
  r0.w = 7.96875 * v3.x;
  r0.w = floor(r0.w);
  r0.w = (int)r0.w;
  o5.zw = cb1[r0.w+1].xy;
  o6.x = cb1[r0.w+1].z;
  o5.x = dot(cb0[2].xyz, r2.yzw);
  o5.y = dot(cb0[3].xyz, r2.yzw);
  r1.xzw = r2.wyz * r0.yzx;
  r0.xyz = r2.zwy * r0.zxy + -r1.xzw;
  o7.z = r2.x;
  r0.xyz = r0.xyz * r1.yyy;
  o6.y = dot(cb0[1].xyz, r0.xyz);
  o6.z = dot(cb0[2].xyz, r0.xyz);
  o6.w = dot(cb0[3].xyz, r0.xyz);
  r0.x = cb0[1].w;
  r0.y = cb0[2].w;
  r0.xy = cb2[12].xy + r0.xy;
  r1.xyz = float3(1,1,1) / cb1[0].xyz;
  r0.xy = r1.zz * r0.xy;
  r0.xy = trunc(r0.xy);
  r0.xy = v4.xy + r0.xy;
  o7.xy = r0.xy * r1.xy;
  o7.w = v4.x;
  o8.x = v4.y;
  o8.yzw = float3(0,0,0);
}