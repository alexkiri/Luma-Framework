#include "Includes/Common.hlsl"

cbuffer ConstentValue : register(b0)
{
  float4 register0 : packoffset(c0);
  float4 register1 : packoffset(c1);
  float4 register2 : packoffset(c2);
  float4 register3 : packoffset(c3);
  float4 register4 : packoffset(c4);
  float4 register5 : packoffset(c5);
  float4 register6 : packoffset(c6);
  float4 register7 : packoffset(c7);
}

SamplerState sampler0_s : register(s0);
Texture2D<float4> texture0 : register(t0);

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD1,
  float2 v2 : TEXCOORD2,
  float2 w2 : TEXCOORD3,
  float2 v3 : TEXCOORD4,
  float2 w3 : TEXCOORD5,
  float2 v4 : TEXCOORD6,
  float2 w4 : TEXCOORD7,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1;
  r0.xyzw = texture0.Sample(sampler0_s, w1.xy).xyzw;
  r0.xyzw = register1.xyzw * r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, v1.xy).xyzw;
  r0.xyzw = r1.xyzw * register0.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, v2.xy).xyzw;
  r0.xyzw = r1.xyzw * register2.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, w2.xy).xyzw;
  r0.xyzw = r1.xyzw * register3.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, v3.xy).xyzw;
  r0.xyzw = r1.xyzw * register4.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, w3.xy).xyzw;
  r0.xyzw = r1.xyzw * register5.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, v4.xy).xyzw;
  r0.xyzw = r1.xyzw * register6.xyzw + r0.xyzw;
  r1.xyzw = texture0.Sample(sampler0_s, w4.xy).xyzw;
  o0.xyzw = r1.xyzw * register7.xyzw + r0.xyzw;
}