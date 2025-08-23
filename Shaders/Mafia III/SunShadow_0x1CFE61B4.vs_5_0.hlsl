#include "Includes/Common.hlsl"

cbuffer cb0 : register(b0)
{
  float4 cb0[4];
}

// Draws in pre-calculated sun shadow (?)
void main(
  float3 v0 : POSITION0,
  float3 v1 : NORMAL0,
  float2 v2 : TEXCOORD0,
  out float4 o0 : SV_Position0,
  out float2 o1 : TEXCOORD0,
  out float3 o2 : TEXCOORD1,
  out float4 o3 : TEXCOORD2,
  out float4 o4 : TEXCOORD3,
  out float4 o5 : TEXCOORD4,
  out float4 o6 : TEXCOORD5)
{
  o0.xyz = v0.xyz; // TODO: missing jitters. Though by applying them here, they get applied to other sun shadow twice!?
  //o0.x += DVS2; // Test
  o0.w = 1;
  o1.xy = v2.xy;
  o2.xyz = v1.xyz;
  o3.xyzw = cb0[0].xyzw;
  o4.xyzw = cb0[1].xyzw;
  o5.xyzw = cb0[2].xyzw;
  o6.xyzw = cb0[3].xyzw;
}