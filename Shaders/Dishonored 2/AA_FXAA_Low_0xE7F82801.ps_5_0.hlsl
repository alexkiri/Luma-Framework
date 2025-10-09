#include "../Includes/Common.hlsl"

cbuffer PerInstanceCB : register(b2)
{
  float4 cb_positiontoviewtexture : packoffset(c0);
}

SamplerState smp_linearclamp_s : register(s0);
Texture2D<float4> ro_viewcolormap : register(t0);

// Runs after tonemapping
void main(
  float4 v0 : INTERP0,
  out float4 o0 : SV_TARGET0)
{
  float4 r0,r1,r2,r3;

  r0.xyz = ro_viewcolormap.SampleLevel(smp_linearclamp_s, v0.zw, 0, int2(1, 0)).xyz;
  r0.x = GetLuminance(r0.xyz); // Luma: fixed wrong luminance formula (BT.601) for better results (it's be even better to calculate luminance in linear space, but the game has better AA settings)
  r0.yzw = ro_viewcolormap.SampleLevel(smp_linearclamp_s, v0.zw, 0, int2(1, 1)).xyz;
  r0.y = GetLuminance(r0.yzw);
  r0.z = r0.x + r0.y;
  r1.xyz = ro_viewcolormap.SampleLevel(smp_linearclamp_s, v0.zw, 0).xyz;
  r0.w = GetLuminance(r1.xyz);
  r1.xyz = ro_viewcolormap.SampleLevel(smp_linearclamp_s, v0.zw, 0, int2(0, 1)).xyz;
  r1.x = GetLuminance(r1.xyz);
  r1.y = r1.x + r0.w;
  r0.z = -r1.y + r0.z;
  r1.y = r0.w + r0.x;
  r1.z = r1.x + r0.y;
  r2.xz = r1.zz + -r1.yy;
  r1.y = r1.y + r1.x;
  r1.y = r1.y + r0.y;
  r1.y = 0.03125 * r1.y;
  r1.y = max(0.0078125, r1.y);
  r1.z = min(abs(r2.z), abs(r0.z));
  r2.yw = -r0.zz;
  r0.z = r1.z + r1.y;
  r0.z = 1 / r0.z;
  r2.xyzw = r2.xyzw * r0.zzzz;
  r2.xyzw = max(float4(-8,-8,-8,-8), r2.xyzw);
  r2.xyzw = min(float4(8,8,8,8), r2.xyzw);
  r2.xyzw = cb_positiontoviewtexture.zwzw * r2.xyzw;
  r3.xyzw = r2.xyzw * float4(-0.5,-0.5,0.5,0.5) + v0.xyxy;
  r2.xyzw = r2.zwzw * float4(-0.166666672,-0.166666672,0.166666672,0.166666672) + v0.xyxy;
  r1.yzw = ro_viewcolormap.SampleLevel(smp_linearclamp_s, r3.xy, 0).xyz;
  r3.xyz = ro_viewcolormap.SampleLevel(smp_linearclamp_s, r3.zw, 0).xyz;
  r1.yzw = r3.xyz + r1.yzw;
  r1.yzw = float3(0.25,0.25,0.25) * r1.yzw;
  r3.xyz = ro_viewcolormap.SampleLevel(smp_linearclamp_s, r2.xy, 0).xyz;
  r2.xyz = ro_viewcolormap.SampleLevel(smp_linearclamp_s, r2.zw, 0).xyz;
  r2.xyz = r3.xyz + r2.xyz;
  r1.yzw = r2.xyz * float3(0.25,0.25,0.25) + r1.yzw;
  r2.xyz = float3(0.5,0.5,0.5) * r2.xyz;
  r0.z = GetLuminance(r1.yzw);
  r2.w = min(r0.w, r0.x);
  r0.x = max(r0.w, r0.x);
  r0.w = min(r1.x, r0.y);
  r0.y = max(r1.x, r0.y);
  r0.x = max(r0.x, r0.y);
  r0.y = min(r2.w, r0.w);
  r3.xyz = ro_viewcolormap.SampleLevel(smp_linearclamp_s, v0.xy, 0).xyz;
  r0.w = GetLuminance(r3.xyz);
  r0.y = min(r0.w, r0.y);
  r0.x = max(r0.w, r0.x);

  r0.y = r0.z >= r0.y; // In hlsl this theoretically already returns 0 or 1, though in asm the "ge" instruction would return either 0 or 0xFFFFFFFF
  r0.x = -(r0.z >= r0.x);

  r0.x = r0.y + r0.x;
  r0.yzw = r0.xxx * r1.yzw;
  r0.x = 1 + -r0.x;
  o0.xyz = r0.xxx * r2.xyz + r0.yzw;
  o0.w = 1;
}