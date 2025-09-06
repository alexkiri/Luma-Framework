#include "../Includes/Common.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[5];
}

#ifndef ENABLE_LUMA
#define ENABLE_LUMA 1
#endif

// Quick branch to enable/disable Luma changes
float4 OptionalSaturate(float4 x)
{
#if ENABLE_LUMA
  return float4(x.rgb, saturate(x.a));
#else // !ENABLE_LUMA
  return saturate(x);
#endif // ENABLE_LUMA
}

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD1,
  float2 v2 : TEXCOORD2,
  float2 w2 : TEXCOORD3,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xyzw = cb0[3].xyxy * float4(0.440510005,0.108919993,0.472079962,0.494199961) + v1.xyxy;
  // LUMA: pre-clip bloom if luma is disabled, because in the vanilla game, rendering was all 8bit UNORM, however in float HDR rendering stuff goes above 1 and if we clip at the end the result would be different
  r1.xyzw = OptionalSaturate(t0.Sample(s0_s, r0.xy).xyzw);
  r0.xyzw = OptionalSaturate(t0.Sample(s0_s, r0.zw).xyzw);
  r0.xyzw = r1.xyzw + r0.xyzw;
  r1.xyzw = cb0[3].xyxy * float4(0.0894600004,-0.139719993,-0.375760019,-0.387800008) + v1.xyxy;
  r2.xyzw = OptionalSaturate(t0.Sample(s0_s, r1.xy).xyzw);
  r1.xyzw = OptionalSaturate(t0.Sample(s0_s, r1.zw).xyzw);
  r0.xyzw = r2.xyzw + r0.xyzw;
  r0.xyzw = r0.xyzw + r1.xyzw;
  r1.xyzw = cb0[3].xyxy * float4(-0.109269999,0.521640003,-0.533469975,-0.173179999) + v1.xyxy;
  r2.xyzw = OptionalSaturate(t0.Sample(s0_s, r1.xy).xyzw);
  r1.xyzw = OptionalSaturate(t0.Sample(s0_s, r1.zw).xyzw);
  r0.xyzw = r2.xyzw + r0.xyzw;
  r0.xyzw = r0.xyzw + r1.xyzw;
  r1.xyzw = cb0[3].xyxy * float4(0.456049979,-0.41069001,0.161559999,0.632239997) + v1.xyxy;
  r2.xyzw = OptionalSaturate(t0.Sample(s0_s, r1.xy).xyzw);
  r1.xyzw = OptionalSaturate(t0.Sample(s0_s, r1.zw).xyzw);
  r0.xyzw = r2.xyzw + r0.xyzw;
  r0.xyzw = r0.xyzw + r1.xyzw;
  r0.xyzw = r0.xyzw * 0.125 + -cb0[4].z;
  r0.xyzw = max(float4(0,0,0,0), r0.xyzw);
  o0.xyzw = cb0[4].w * r0.xyzw;
}