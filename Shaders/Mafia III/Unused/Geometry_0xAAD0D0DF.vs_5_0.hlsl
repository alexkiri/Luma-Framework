#include "Includes/Common.hlsl"

cbuffer cb1 : register(b1)
{
  float4 cb1[26];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[7];
}

void main(
  uint4 v0 : POSITION0,
  uint4 v1 : TANGENT0,
  uint4 v2 : NORMAL0,
  float4 v3 : TEXCOORD0,
  out float4 o0 : SV_Position0,
  out float4 o1 : TEXCOORD0,
  out float4 o2 : TEXCOORD1,
  out float4 o3 : TEXCOORD2,
  out float4 o4 : TEXCOORD3,
  out float4 o5 : TEXCOORD4,
  out float4 o6 : TEXCOORD5,
  out float4 o7 : TEXCOORD6)
{
  float4 r0,r1,r2,r3,r4;
  r0.xyzw = (uint4)v1.xyzw;
  r1.x = (r0.y >= 128);
  r1.xy = r1.xx ? float2(-128,-1) : float2(-0,1);
  r0.y = r1.x + r0.y;
  //cb0[0].wz += DVS10;
  // cb1[1].y is 3000 always?
  // Jitters: cb1[22].xy (depth on z...)
  // Render res (render target?): cb1[10].xy
  // Inv Render res (render target?): cb1[10].zw
  // Size: 2048
  // cb1[22].x += cb1[22].z;
  // cb1[22].y += cb1[22].z;
  // cb1[22].x += DVS10;
  // cb1[22].y += DVS9;
  // cb1[22].z = 0;
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
  r4.y = dot(cb1[24].xyzw, r3.xyzw);
  o0.z = r4.y;
  r0.y = dot(cb1[25].xyzw, r3.xyzw);
  o0.w = r0.y;
  r4.x = cb1[1].w * r0.y;
  o3.y = dot(cb1[2].xy, r4.xy);
  o0.x = dot(cb1[22].xyzw, r3.xyzw);
  o0.y = dot(cb1[23].xyzw, r3.xyzw);
  // Testing jitter  offsets (these are the ones that matter for TAA)
  //o0.x += DVS9 / 5.0;
  //o0.y += DVS10 / 5.0;
  r4.x = dot(cb0[4].xyzw, r2.xyzw);
  r4.y = dot(cb0[5].xyzw, r2.xyzw);
  r4.z = dot(cb0[6].xyzw, r2.xyzw);
  r1.xzw = -r4.xyz + r3.xyz;
  o2.zw = r3.xy;
  o3.x = r3.z;
  o1.w = r1.x;
  o2.xy = r1.zw;
  r3.xyzw = (uint4)v2.xyzw;
  r0.x = r3.w;
  r3.xyzw = r3.zxyz * float4(0.00784313772,0.00784313772,0.00784313772,0.00784313772) + float4(-1,-1,-1,-1);
  r0.xyz = r0.zwx * float3(0.00784313772,0.00784313772,0.00784313772) + float3(-1,-1,-1);
  o1.x = dot(cb0[1].xyz, r0.xyz);
  o1.y = dot(cb0[2].xyz, r0.xyz);
  o1.z = dot(cb0[3].xyz, r0.xyz);
  o3.zw = r2.xy;
  o4.x = r2.z;
  o4.yzw = r3.yzw;
  r1.xzw = r3.wyz * r0.yzx;
  r0.xyz = r3.zwy * r0.zxy + -r1.xzw;
  r0.xyz = r0.xyz * r1.yyy;
  o5.w = dot(cb0[1].xyz, r0.xyz);
  o5.x = dot(cb0[1].xyz, r3.yzw);
  o5.y = dot(cb0[2].xyz, r3.yzw);
  o5.z = dot(cb0[3].xyz, r3.yzw);
  o6.z = r3.x;
  o6.x = dot(cb0[2].xyz, r0.xyz);
  o6.y = dot(cb0[3].xyz, r0.xyz);
  o6.w = v3.x;
  o7.x = v3.y;
  o7.yzw = float3(0,0,0);
}