

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
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, v1.xy, 0, int2(-1, 1)).w;
  r0.yzw = fullColorBiLinear_tex.Gather(fullColorBiLinear_tex_ss_s, v1.xy).xyz;
  r1.x = r0.x + r0.z;
  r1.x = r0.y * -2 + r1.x;
  r1.y = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, v1.xy, 0, int2(1, -1)).w;
  r2.xyz = fullColorBiLinear_tex.Gather(fullColorBiLinear_tex_ss_s, v1.xy, int2(-1, -1)).xzw;
  r1.z = r2.z + r1.y;
  r0.z = r1.y + r0.z;
  r1.y = r2.y * -2 + r1.z;
  r1.zw = r2.yx + r0.yw;
  r3.xyzw = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, v1.xy, 0).xyzw;
  r4.xy = r3.ww * float2(-2,-2) + r1.zw;
  r1.z = r1.z + r1.w;
  r1.y = abs(r4.y) * 2 + abs(r1.y);
  r1.x = abs(r1.x) + r1.y;
  r0.x = r2.z + r0.x;
  r1.y = r2.x * -2 + r0.x;
  r0.x = r0.x + r0.z;
  r0.z = r0.w * -2 + r0.z;
  r0.z = abs(r4.x) * 2 + abs(r0.z);
  r0.z = abs(r1.y) + r0.z;
  r0.z = cmp(r0.z >= r1.x);
  r0.x = r1.z * 2 + r0.x;
  r0.x = r0.x * 0.0833333358 + -r3.w;
  r1.x = r0.z ? r2.y : r2.x;
  r1.y = r1.x + -r3.w;
  r1.z = r0.z ? r0.y : r0.w;
  r1.w = r1.z + -r3.w;
  r1.xz = r1.xz + r3.ww;
  r2.z = max(abs(r1.y), abs(r1.w));
  r1.y = cmp(abs(r1.y) >= abs(r1.w));
  r1.w = 0.25 * r2.z;
  r1.x = r1.y ? r1.x : r1.z;
  r1.z = r0.z ? g_MainFilterPS.pixel_size.y : g_MainFilterPS.pixel_size.x;
  r1.y = r1.y ? -r1.z : r1.z;
  r2.zw = r1.yy * float2(0.5,0.5) + v1.xy;
  r1.z = r0.z ? v1.x : r2.z;
  r2.z = r0.z ? r2.w : v1.y;
  r2.w = r0.z ? g_MainFilterPS.pixel_size.x : 0;
  r4.x = -r2.w + r1.z;
  r5.x = r2.w + r1.z;
  r1.z = -r2.w * 1.5 + r4.x;
  r4.z = r0.z ? 0 : g_MainFilterPS.pixel_size.y;
  r4.y = -r4.z + r2.z;
  r5.y = r4.z + r2.z;
  r2.z = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r4.xy, 0).w;
  r6.x = -r1.x * 0.5 + r2.z;
  r2.z = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r5.xy, 0).w;
  r6.y = -r1.x * 0.5 + r2.z;
  r5.zw = cmp(abs(r6.xy) >= r1.ww);
  r7.x = r5.z ? r4.x : r1.z;
  r1.z = -r4.z * 1.5 + r4.y;
  r7.y = r5.z ? r4.y : r1.z;
  r1.z = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r7.xy, 0).w;
  r1.z = r5.z ? r6.x : r1.z;
  r1.z = -r1.x * 0.5 + r1.z;
  r4.x = r5.z ? r6.x : r1.z;
  r1.z = r2.w * 1.5 + r5.x;
  r7.z = r5.w ? r5.x : r1.z;
  r1.z = r4.z * 1.5 + r5.y;
  r7.w = r5.w ? r5.y : r1.z;
  r1.z = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r7.zw, 0).w;
  r1.z = r5.w ? r6.y : r1.z;
  r1.z = -r1.x * 0.5 + r1.z;
  r4.y = r5.w ? r6.y : r1.z;
  r5.xy = ~(int2)r5.zw;
  r1.z = (int)r5.y | (int)r5.x;
  r5.xy = cmp(abs(r4.xy) >= r1.ww);
  r2.z = -r2.w * 2 + r7.x;
  r8.x = r5.x ? r7.x : r2.z;
  r2.z = -r4.z * 2 + r7.y;
  r8.y = r5.x ? r7.y : r2.z;
  r2.z = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r8.xy, 0).w;
  r2.z = r5.x ? r4.x : r2.z;
  r2.z = -r1.x * 0.5 + r2.z;
  r9.x = r5.x ? r4.x : r2.z;
  r2.z = r2.w * 2 + r7.z;
  r8.z = r5.y ? r7.z : r2.z;
  r2.z = r4.z * 2 + r7.w;
  r8.w = r5.y ? r7.w : r2.z;
  r2.z = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r8.zw, 0).w;
  r2.z = r5.y ? r4.y : r2.z;
  r2.z = -r1.x * 0.5 + r2.z;
  r9.y = r5.y ? r4.y : r2.z;
  r5.xy = ~(int2)r5.xy;
  r2.z = (int)r5.y | (int)r5.x;
  r5.xy = cmp(abs(r9.xy) >= r1.ww);
  r4.w = -r2.w * 2 + r8.x;
  r10.x = r5.x ? r8.x : r4.w;
  r4.w = -r4.z * 2 + r8.y;
  r10.y = r5.x ? r8.y : r4.w;
  r4.w = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r10.xy, 0).w;
  r4.w = r5.x ? r9.x : r4.w;
  r4.w = -r1.x * 0.5 + r4.w;
  r11.x = r5.x ? r9.x : r4.w;
  r4.w = r2.w * 2 + r8.z;
  r10.z = r5.y ? r8.z : r4.w;
  r4.w = r4.z * 2 + r8.w;
  r10.w = r5.y ? r8.w : r4.w;
  r4.w = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r10.zw, 0).w;
  r4.w = r5.y ? r9.y : r4.w;
  r4.w = -r1.x * 0.5 + r4.w;
  r11.y = r5.y ? r9.y : r4.w;
  r5.xy = ~(int2)r5.xy;
  r4.w = (int)r5.y | (int)r5.x;
  r5.xy = cmp(abs(r11.xy) >= r1.ww);
  r5.z = -r2.w * 4 + r10.x;
  r12.x = r5.x ? r10.x : r5.z;
  r5.z = -r4.z * 4 + r10.y;
  r12.y = r5.x ? r10.y : r5.z;
  r5.z = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r12.xy, 0).w;
  r5.z = r5.x ? r11.x : r5.z;
  r5.z = -r1.x * 0.5 + r5.z;
  r13.x = r5.x ? r11.x : r5.z;
  r5.z = r2.w * 4 + r10.z;
  r12.z = r5.y ? r10.z : r5.z;
  r5.z = r4.z * 4 + r10.w;
  r12.w = r5.y ? r10.w : r5.z;
  r5.z = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r12.zw, 0).w;
  r5.z = r5.y ? r11.y : r5.z;
  r5.z = -r1.x * 0.5 + r5.z;
  r1.x = -r1.x * 0.5 + r3.w;
  r1.x = cmp(r1.x < 0);
  r13.y = r5.y ? r11.y : r5.z;
  r5.xy = ~(int2)r5.xy;
  r5.x = (int)r5.y | (int)r5.x;
  r5.yz = cmp(abs(r13.xy) >= r1.ww);
  r6.zw = r5.xx ? r13.xy : r11.xy;
  r6.zw = r4.ww ? r6.zw : r9.xy;
  r4.xy = r2.zz ? r6.zw : r4.xy;
  r4.xy = r1.zz ? r4.xy : r6.xy;
  r4.xy = cmp(r4.xy < float2(0,0));
  r1.xw = cmp((int2)r4.xy != (int2)r1.xx);
  r4.x = -r2.w * 2 + r12.x;
  r2.w = r2.w * 2 + r12.z;
  r6.z = r5.z ? r12.z : r2.w;
  r6.x = r5.y ? r12.x : r4.x;
  r2.w = -r4.z * 2 + r12.y;
  r4.x = r4.z * 2 + r12.w;
  r6.w = r5.z ? r12.w : r4.x;
  r6.y = r5.y ? r12.y : r2.w;
  r5.xyzw = r5.xxxx ? r6.xyzw : r12.xyzw;
  r4.xyzw = r4.wwww ? r5.xyzw : r10.xyzw;
  r4.xyzw = r2.zzzz ? r4.xyzw : r8.xyzw;
  r4.xyzw = r1.zzzz ? r4.xyzw : r7.xyzw;
  r2.zw = v1.xy + -r4.xy;
  r4.xy = -v1.xy + r4.zw;
  r1.z = r0.z ? r4.x : r4.y;
  r2.z = r0.z ? r2.z : r2.w;
  r2.w = cmp(r2.z < r1.z);
  r1.x = r2.w ? r1.x : r1.w;
  r1.w = r2.z + r1.z;
  r1.z = min(r2.z, r1.z);
  r1.w = 1 / r1.w;
  r1.z = r1.z * -r1.w + 0.5;
  r1.x = (int)r1.z & (int)r1.x;
  r1.z = min(r2.y, r2.x);
  r1.w = max(r2.y, r2.x);
  r2.x = min(r3.w, r0.y);
  r2.x = min(r2.x, r0.w);
  r1.z = min(r2.x, r1.z);
  r0.y = max(r3.w, r0.y);
  r0.y = max(r0.w, r0.y);
  r0.y = max(r1.w, r0.y);
  r0.w = r0.y + -r1.z;
  r0.y = 0.166666672 * r0.y;
  r0.y = max(0.0833333358, r0.y);
  r0.y = cmp(r0.w >= r0.y);
  r0.w = 1 / r0.w;
  r0.x = saturate(abs(r0.x) * r0.w);
  r0.w = r0.x * -2 + 3;
  r0.x = r0.x * r0.x;
  r0.x = r0.w * r0.x;
  r0.x = r0.x * r0.x;
  r0.x = 0.75 * r0.x;
  r0.x = max(r1.x, r0.x);
  r0.xw = r0.xx * r1.yy + v1.xy;
  r1.x = r0.z ? v1.x : r0.x;
  r1.y = r0.z ? r0.w : v1.y;
  r0.xzw = fullColorBiLinear_tex.SampleLevel(fullColorBiLinear_tex_ss_s, r1.xy, 0).xyz;
  o0.xyz = r0.yyy ? r0.xzw : r3.xyz;
  r0.x = mipColor1_tex.Sample(mipColor1_tex_ss_s, v1.xy).w;
  r0.x = max(0, r0.x);
  r0.x = r0.x * g_MainFilterPS.mainFilterDof.x + g_MainFilterPS.mainFilterDof.y;
  o0.w = saturate(r0.x + r0.x);
  return;
}