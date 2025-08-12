// ---- Created with 3Dmigoto v1.4.1 on Sat Apr 19 18:50:24 2025
cbuffer cb2 : register(b2)
{
  float4 cb2[3];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[140];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[15];
}




// 3Dmigoto declarations
#define cmp -


void main(
  float4 v0 : ATTRIBUTE0,
  float2 v1 : ATTRIBUTE1,
  out float4 o0 : TEXCOORD0,
  out float4 o1 : TEXCOORD1,
  out float4 o2 : SV_POSITION0)
{
  float4 r0;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xy = v1.xy * cb1[126].xy + cb1[1].zw;
  o0.xy = cb2[2].zw * r0.xy;
  o1.z = cb1[24].x * cb1[126].x;
  o1.w = cb1[126].x;
  r0.xy = v0.xy * cb1[126].xy + cb2[0].zw;
  r0.xy = cb1[126].zw * r0.xy;
  r0.xy = r0.xy * float2(2,2) + float2(-1,-1);
  o1.x = cb1[126].x * r0.x;
  o1.y = cb1[126].y * -r0.y;
  o2.xy = float2(1,-1) * r0.xy;
  o2.zw = v0.zw;
  return;
}