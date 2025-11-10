#include "../Includes/Common.hlsl"

SamplerState texture0_ss_s : register(s0);
Texture2D<float4> texture0 : register(t0);

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD3,
  out float4 o0 : SV_Target0)
{
  o0.rgb = texture0.Sample(texture0_ss_s, v1.xy).rgb;
  o0.a = GetLuminance(o0.rgb); // Luma: fixed bad luminance calculations
  o0.a = max(o0.a, 0.0); // Luma: added for safety
}