#include "Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

SamplerState PointSampler_s : register(s1);
Texture2D<float4> texColor : register(t0);

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD2,
  float4 v4 : TEXCOORD3,
  out float2 o0 : SV_TARGET0)
{
  float4 r0,r1,r2,r3,r4;
  r0.xyz = texColor.Sample(PointSampler_s, v1.xy).xyz;
  r1.xyz = texColor.Sample(PointSampler_s, v2.xy).xyz;

  // The game has some minor nans and invalid colors (due to subtractive blending).
  // AA is the first fullscreen pass where we can fix them.
  r0.xyz = IsNaN_Strict(r0.xyz) ? 0.0 : r0.xyz;
  FixColorGradingLUTNegativeLuminance(r0.xyz);
  r1.xyz = IsNaN_Strict(r1.xyz) ? 0.0 : r1.xyz;
  FixColorGradingLUTNegativeLuminance(r1.xyz);

  r1.xyz = -r1.xyz + r0.xyz;
  r0.w = max(abs(r1.x), abs(r1.y));
  r1.x = max(r0.w, abs(r1.z));
  r2.xyz = texColor.Sample(PointSampler_s, v2.zw).xyz;
  r2.xyz = IsNaN_Strict(r2.xyz) ? 0.0 : r2.xyz;
  FixColorGradingLUTNegativeLuminance(r2.xyz);
  r2.xyz = -r2.xyz + r0.xyz;
  r0.w = max(abs(r2.x), abs(r2.y));
  r1.y = max(r0.w, abs(r2.z));
  r1.zw = (r1.xy >= float2(0.100000001,0.100000001));
  r1.zw = r1.zw ? float2(1,1) : 0;
  r0.w = dot(r1.zw, float2(1,1));
  r0.w = (r0.w == 0.000000);
  if (r0.w != 0) discard;
  r2.xyz = texColor.Sample(PointSampler_s, v3.xy).xyz;
  r2.xyz = IsNaN_Strict(r2.xyz) ? 0.0 : r2.xyz;
  FixColorGradingLUTNegativeLuminance(r2.xyz);
  r2.xyz = -r2.xyz + r0.xyz;
  r0.w = max(abs(r2.x), abs(r2.y));
  r2.x = max(r0.w, abs(r2.z));
  r3.xyz = texColor.Sample(PointSampler_s, v3.zw).xyz;
  r3.xyz = IsNaN_Strict(r3.xyz) ? 0.0 : r3.xyz;
  FixColorGradingLUTNegativeLuminance(r3.xyz);
  r3.xyz = -r3.xyz + r0.xyz;
  r0.w = max(abs(r3.x), abs(r3.y));
  r2.y = max(r0.w, abs(r3.z));
  r2.xy = max(r2.xy, r1.xy);
  r3.xyz = texColor.Sample(PointSampler_s, v4.xy).xyz;
  r3.xyz = IsNaN_Strict(r3.xyz) ? 0.0 : r3.xyz;
  FixColorGradingLUTNegativeLuminance(r3.xyz);
  r3.xyz = -r3.xyz + r0.xyz;
  r0.w = max(abs(r3.x), abs(r3.y));
  r3.x = max(r0.w, abs(r3.z));
  r4.xyz = texColor.Sample(PointSampler_s, v4.zw).xyz;
  r4.xyz = IsNaN_Strict(r4.xyz) ? 0.0 : r4.xyz;
  FixColorGradingLUTNegativeLuminance(r4.xyz);
  r0.xyz = -r4.xyz + r0.xyz;
  r0.x = max(abs(r0.x), abs(r0.y));
  r3.y = max(r0.x, abs(r0.z));
  r0.xy = max(r3.xy, r2.xy);
  r0.x = max(r0.x, r0.y);
  r0.yz = r1.xy + r1.xy;
  r0.xy = (r0.yz >= r0.xx);
  r0.xy = r0.xy ? float2(1,1) : 0;
  o0.xy = r1.zw * r0.xy;
}