#include "../Includes/Common.hlsl"

Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

#ifndef ENABLE_LUMA
#define ENABLE_LUMA 1
#endif

#ifndef ENABLE_CHARACTER_LIGHT
#define ENABLE_CHARACTER_LIGHT 1
#endif

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : COLOR0,
  float4 v2 : TEXCOORD0,
  float4 v3 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xyzw = t0.Sample(s0_s, v2.xy).xyzw;
  float minStep = 0.01;
#if ENABLE_LUMA // Luma: fix hero light having a visible step at the edge
  minStep = 0.0;
#endif
  r1.xyzw = r0.wxyz * v1.wxyz + float4(-minStep, -0.5,-0.5,-0.5);
  r0.xyzw = v1.wxyz * r0.wxyz;
  if (r1.x < 0.0) discard;
  r2.xy = v3.xy / v3.w;
  r2.xy += 1.0;
  r2.x = 0.5 * r2.x;
  r2.z = -r2.y * 0.5 + 1.0;
  float2 sceneUV = r2.xz;
  r2.xyzw = t1.Sample(s1_s, sceneUV).xyzw;
  r1.xyz = r1.yzw * 2.0 + r2.xyz;
  r2.xyz = r0.yzw * 2.0 + r2.xyz;
  r2.xyz -= 1.0;
  o0.w = r0.x;
#if 0 // Luma: character light intensity (1 is vanilla)
  o0.w *= LumaData.CustomData3;
#endif
#if !ENABLE_CHARACTER_LIGHT
  o0.w = 0.0;
#endif
  o0.xyz = (0.5 < r0.yzw) ? r1.xyz : r2.xyz;
  
#if ENABLE_LUMA // Luma: fix character light having heavy banding, we found 5 bits to be a good value. It needs to be applied on alpha too for best results.
  //o0.w *= 2.5; // Quick banding test
  ApplyDithering(o0.xyz, sceneUV, true, 1.0, 5, LumaSettings.FrameIndex, true);
  if (o0.w != 0.0)
  {
    float3 outAlpha = o0.w;
    ApplyDithering(outAlpha, sceneUV, true, 1.0, 5, LumaSettings.FrameIndex, true);
    o0.w = outAlpha.x; // Clip unused channels
  }
#endif
}