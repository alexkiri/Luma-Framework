#include "../Includes/Common.hlsl"

cbuffer g_FilterGamma_CB : register(b0)
{
  struct
  {
    float4 gamma;
  } g_FilterGamma : packoffset(c0);
}

SamplerState texture0_ss_s : register(s0);
Texture2D<float4> texture0 : register(t0);

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  o0.rgba = texture0.Sample(texture0_ss_s, v1.xy).rgba;
  o0.rgba = max(o0.rgba, -FLT_MAX); // Luma: nans protection
  // Usuer brightness calibration values. Usually neutral.
  o0.rgb += g_FilterGamma.gamma.y; // Luma: remove saturate()
  o0.xyz = pow(abs(o0.rgb), g_FilterGamma.gamma.x) * sign(o0.rgb); // Luma: fix negative values support
}