

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

SamplerState fullColorBiLinear_tex_ss_s : register(s1);
SamplerState mipColor1_tex_ss_s : register(s4);
Texture2D<float4> fullColorBiLinear_tex : register(t1);
Texture2D<float4> mipColor1_tex : register(t4);



#define cmp -


void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD3,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, v2.zy, 0).w;
  r0.x = 0.00260416674 + r0.x;
  r0.y = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, v2.xw, 0).w;
  r0.z = -r0.x + r0.y;
  r0.w = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, v2.xy, 0).w;
  r1.x = r0.z + -r0.w;
  r0.z = r0.z + r0.w;
  r1.y = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, v2.zw, 0).w;
  r2.x = r1.x + r1.y;
  r2.y = -r1.y + r0.z;
  r0.z = dot(r2.xy, r2.xy);
  r0.z = rsqrt(r0.z);
  r1.xz = r2.xy * r0.zz;
  r0.z = min(abs(r1.x), abs(r1.z));
  r0.z = 8 * r0.z;
  r2.xy = r1.xz / r0.zz;
  r2.xy = max(float2(-2,-2), r2.xy);
  r2.xy = min(float2(2,2), r2.xy);
  r3.xyzw = float4(2,2,0.5,0.5) * g_MainFilterPS.pixel_size.xyxy;
  r2.zw = -r2.xy * r3.xy + v1.xy;
  r2.xy = r2.xy * r3.xy + v1.xy;
  r4.xyzw = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r2.xy, 0).xyzw;
  r2.xyzw = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r2.zw, 0).xyzw;
  r2.xyzw = r2.xyzw + r4.xyzw;
  r3.xy = -r1.xz * r3.zw + v1.xy;
  r1.xz = r1.xz * r3.zw + v1.xy;
  r4.xyzw = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r1.xz, 0).xyzw;
  r3.xyzw = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r3.xy, 0).xyzw;
  r3.xyzw = r3.xyzw + r4.xyzw;
  r3.xyzw = float4(0.5,0.5,0.5,0.5) * r3.xyzw;
  r2.xyzw = r2.xyzw * float4(0.5,0.5,0.5,0.5) + r3.xyzw;
  r2.xyzw = float4(0.5,0.5,0.5,0.5) * r2.xyzw;
  r0.z = min(r1.y, r0.x);
  r0.x = max(r1.y, r0.x);
  r1.x = min(r0.w, r0.y);
  r0.y = max(r0.w, r0.y);
  r0.x = max(r0.y, r0.x);
  r0.y = min(r1.x, r0.z);
  r0.z = cmp(r2.w < r0.y);
  r0.w = cmp(r0.x < r2.w);
  r0.z = (int)r0.w | (int)r0.z;
  r1.xyz = r0.zzz ? r3.xyz : r2.xyz;
  r2.xyzw = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, v1.xy, 0).xyzw;
  r0.y = min(r2.w, r0.y);
  r0.z = max(r2.w, r0.x);
  r0.x = 0.125 * r0.x;
  r0.x = max(0.100000001, r0.x);
  r0.y = r0.z + -r0.y;
  r0.x = cmp(r0.y >= r0.x);
  o0.xyz = r0.xxx ? r1.xyz : r2.xyz;
  r0.x = mipColor1_tex.Sample(mipColor1_tex_ss_s, v1.xy).w;
  r0.x = max(0, r0.x);
  r0.x = r0.x * g_MainFilterPS.mainFilterDof.x + g_MainFilterPS.mainFilterDof.y;
  o0.w = saturate(r0.x + r0.x);
  return;
}