

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



#define cmp -


void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xyzw = fullColorBiLinear_tex.Sample(fullColorBiLinear_tex_ss_s, v2.xy).xyzw;
  r1.x = r0.w;
  r2.xyzw = fullColorBiLinear_tex.Sample(fullColorBiLinear_tex_ss_s, v2.zy).xyzw;
  r1.y = r2.w;
  r0.xyzw = r2.xyzw + r0.xyzw;
  r2.xyzw = fullColorBiLinear_tex.Sample(fullColorBiLinear_tex_ss_s, v2.xw).xyzw;
  r1.z = r2.w;
  r0.xyzw = r2.xyzw + r0.xyzw;
  r2.xyzw = fullColorBiLinear_tex.Sample(fullColorBiLinear_tex_ss_s, v2.zw).xyzw;
  r1.w = r2.w;
  r0.xyzw = r2.xyzw + r0.xyzw;
  r2.xyzw = fullColor_tex.Sample(fullColor_tex_ss_s, v1.xy).xyzw;
  r1.xyzw = -r2.wwww * float4(0.25,0.25,0.25,0.25) + r1.xyzw;
  r1.xyzw = float4(1.33333337,1.33333337,1.33333337,1.33333337) * r1.xyzw;
  r3.xy = max(r1.xy, r1.zw);
  r3.x = max(r3.x, r3.y);
  r3.yz = min(r1.xy, r1.zw);
  r1.x = dot(r1.xyzw, float4(0.25,0.25,0.25,0.25));
  r1.x = r2.w + -r1.x;
  r1.x = g_MainFilterPS.edgeFilterParams.x * r1.x;
  r1.y = min(r3.y, r3.z);
  r1.y = r3.x + -r1.y;
  r1.y = max(g_MainFilterPS.edgeFilterParams.z, r1.y);
  r1.x = r1.x / r1.y;
  r1.x = r1.x * r1.x;
  r1.x = min(1, r1.x);
  r1.x = r1.x * 10 + -9;
  r1.x = max(0, r1.x);
  r0.xyzw = r0.xyzw * float4(0.25,0.25,0.25,0.25) + -r2.xyzw;
  o0.xyzw = r1.xxxx * r0.xyzw + r2.xyzw;
  return;
}