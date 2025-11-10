#include "../Includes/Common.hlsl"

cbuffer g_MainFilterPS_CB : register(b0)
{
  struct
  {
    float4 mainFilterToneMapping;
    float4 mainFilterDof;
    float4 edgeFilterParams;
    float4 pixel_size;
  } g_MainFilterPS : packoffset(c0);
}

SamplerState fullColor_tex_ss_s : register(s0);
SamplerState fullColorBiLinear_tex_ss_s : register(s1);
Texture2D<float4> fullColor_tex : register(t0);
Texture2D<float4> fullColorBiLinear_tex : register(t1);

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xyzw = fullColorBiLinear_tex.Sample(fullColorBiLinear_tex_ss_s, v2.xy).xyzw;
  r1.xyzw = fullColorBiLinear_tex.Sample(fullColorBiLinear_tex_ss_s, v2.zy).xyzw;
  r0.xyzw = r1.xyzw + r0.xyzw;
  r1.xyzw = fullColorBiLinear_tex.Sample(fullColorBiLinear_tex_ss_s, v2.xw).xyzw;
  r0.xyzw = r1.xyzw + r0.xyzw;
  r1.xyzw = fullColorBiLinear_tex.Sample(fullColorBiLinear_tex_ss_s, v2.zw).xyzw;
  r0.xyzw = r1.xyzw + r0.xyzw;
  r1.xyzw = fullColor_tex.Sample(fullColor_tex_ss_s, v1.xy).xyzw;
  r2.xyz = -r1.xyz + r0.xyz;
  r0.xyzw = r0.xyzw * float4(0.25,0.25,0.25,0.25) + -r1.xyzw;
  r2.xyz = -r2.xyz * float3(0.333332986,0.333332986,0.333332986) + r1.xyz;
  r2.xyz = saturate(g_MainFilterPS.edgeFilterParams.xxx * abs(r2.xyz));
  r2.xyz = r2.xyz * r2.xyz;
  r2.x = GetLuminance(r2.xyz); // Luma: fixed bad luminance
  r2.y = (r2.x >= g_MainFilterPS.edgeFilterParams.z);
  r2.x = r2.x * r2.y;
  o0.xyzw = r2.x * r0.xyzw + r1.xyzw;
}