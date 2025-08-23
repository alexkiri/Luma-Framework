#include "Includes/Common.hlsl"

cbuffer cb2 : register(b2)
{
  float4 cb2[26];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[8];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[7];
}

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
  out float4 o8 : TEXCOORD7,
  out float4 o9 : TEXCOORD8)
{
  float4 r0,r1,r2,r3,r4;
  r0.xyzw = (uint4)v1.xyzw;
  r1.x = (r0.y >= 128);
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
  r3.w = 1;
  r4.y = dot(cb2[24].xyzw, r3.xyzw);

// float res = 7680;
// cb2[22].w += DVS1 * 2.0 / res;
//cb2[23].w +=;

  o0.z = r4.y;
  r0.y = dot(cb2[25].xyzw, r3.xyzw);
  o0.w = r0.y;
  r4.x = cb2[1].w * r0.y;
  o3.w = dot(cb2[2].xy, r4.xy);
  o0.x = dot(cb2[22].xyzw, r3.xyzw);
  o0.y = dot(cb2[23].xyzw, r3.xyzw);
  r4.x = dot(cb0[4].xyzw, r2.xyzw);
  r4.y = dot(cb0[5].xyzw, r2.xyzw);
  r4.z = dot(cb0[6].xyzw, r2.xyzw);
  o4.xyz = r2.xyz;
  r1.xzw = -r4.xyz + r3.xyz;
  o3.xyz = r3.xyz;
  o1.w = r1.x;
  o2.xy = r1.zw;
  r2.xyzw = (uint4)v2.xyzw;
  r0.x = r2.w;
  r0.xyz = r0.zwx * float3(0.00784313772,0.00784313772,0.00784313772) + float3(-1,-1,-1);
  o1.x = dot(cb0[1].xyz, r0.xyz);
  o1.y = dot(cb0[2].xyz, r0.xyz);
  o1.z = dot(cb0[3].xyz, r0.xyz);
  o2.zw = v5.xy;
  o4.w = v3.x;
  o5.xyz = v3.yzw;
  r1.xzw = r2.xyz * float3(0.00784313772,0.00784313772,0.00784313772) + float3(-1,-1,-1);
  o8.w = r2.z * 0.00784313772 + -1;
  o5.w = r1.x;
  o6.z = dot(cb0[1].xyz, r1.xzw);
  o6.w = dot(cb0[2].xyz, r1.xzw);
  o6.xy = r1.zw;
  r0.w = 7.96875 * v3.x;
  r0.w = floor(r0.w);
  r0.w = (int)r0.w;
  o7.yzw = cb1[r0.w+0].xyz;
  o7.x = dot(cb0[3].xyz, r1.xzw);
  r2.xyz = r1.wxz * r0.yzx;
  r0.xyz = r1.zwx * r0.zxy + -r2.xyz;
  r0.xyz = r0.xyz * r1.yyy;
  o8.x = dot(cb0[1].xyz, r0.xyz);
  o8.y = dot(cb0[2].xyz, r0.xyz);
  o8.z = dot(cb0[3].xyz, r0.xyz);
  o9.xy = v4.xy;
  o9.zw = float2(0,0);
}