#include "includes/Common.hlsl"

cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}

// 3Dmigoto declarations
#define cmp -

void main(
  float4 v0 : ATTRIBUTE0,
  float2 v1 : ATTRIBUTE1,
  out float4 o0 : TEXCOORD0,
  out float4 o1 : SV_POSITION0)
{
  float4 r0;
  uint4 bitmask, uiDest;
  float4 fDest;
  float resolutionScale;
  if(LumaData.GameData.DrewUpscaling){
    resolutionScale = LumaData.GameData.ResolutionScale.y;
  }else{
    resolutionScale = 1.0f;
  }
  r0.xy = v1.xy * (cb0[1].xy * resolutionScale) + (cb0[1].zw * resolutionScale);
  o0.xy = cb0[2].zw * r0.xy;
  r0.xy = v0.xy * (cb0[0].xy * resolutionScale) + (cb0[0].zw * resolutionScale);
  r0.xy = (cb0[2].xy * 1/resolutionScale) * r0.xy;
  r0.xy = r0.xy * float2(2,2) + float2(-1,-1);
  r0.xy = float2(1,-1) * r0.xy;
  o0.zw = r0.xy;
  o1.xy = r0.xy;
  o1.zw = v0.zw;
  return;
}