#include "Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

cbuffer ConstentValue : register(b0)
{
  float4 windowSize : packoffset(c0);
}

SamplerState LinearSampler_s : register(s0);
Texture2D<float4> texColor : register(t0);
Texture2D<float4> texBlend : register(t1);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1,r2;
  r0.x = texBlend.Sample(LinearSampler_s, v2.xy).w;
  r0.y = texBlend.Sample(LinearSampler_s, v2.zw).y;
  r0.zw = texBlend.Sample(LinearSampler_s, v1.xy).zx;
  r1.x = dot(r0.xyzw, float4(1,1,1,1));
  r1.x = (r1.x < 9.99999975e-006);
  if (r1.x != 0) {
    o0.xyzw = texColor.SampleLevel(LinearSampler_s, v1.xy, 0).xyzw;
  } else {
    r1.xy = max(r0.xy, r0.zw);
    r1.x = (r1.y < r1.x);
    r2.xz = r1.xx ? r0.xz : 0;
    r2.yw = r1.xx ? float2(0,0) : r0.yw;
    r0.x = r1.x ? r0.x : r0.y;
    r0.y = r1.x ? r0.z : r0.w;
    r0.z = dot(r0.xy, float2(1,1));
    r0.xy = r0.xy / r0.zz;
    r1.xy = float2(1,1) / windowSize.xy;
    r1.zw = -r1.xy;
    r1.xyzw = r2.xyzw * r1.xyzw + v1.xyxy;
    r2.xyzw = texColor.SampleLevel(LinearSampler_s, r1.xy, 0).xyzw;
    r1.xyzw = texColor.SampleLevel(LinearSampler_s, r1.zw, 0).xyzw;
    r1.xyzw = r1.xyzw * r0.yyyy;
    o0.xyzw = r0.xxxx * r2.xyzw + r1.xyzw;
  }
  
#if LUMA_ENABLED
  // The game has some minor nans and invalid colors (due to subtractive blending).
  // AA is the first fullscreen pass where we can fix them.
  o0.xyz = IsNaN_Strict(o0.xyz) ? 0.0 : o0.xyz;

  o0.rgb = gamma_to_linear(o0.rgb, GCT_MIRROR);
  FixColorGradingLUTNegativeLuminance(o0.rgb);
  o0.rgb = linear_to_gamma(o0.rgb, GCT_MIRROR);
#endif
}