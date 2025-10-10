#include "../Includes/Common.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[35];
}

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  float2 uv = cb0[34].xy * v1.xy;
  uv = floor(uv);
  uv = uv / cb0[34].xy;
  float4 sceneColor = t0.Sample(s0_s, uv).xyzw;
  sceneColor.w = 0.274399996 * sceneColor.y;
  sceneColor.w = sceneColor.x * 0.587000012 - sceneColor.w;
  sceneColor.w = -sceneColor.z * 0.522899985 + sceneColor.w;
#if 0 // Luma: fixed BT.601 luminance // TODO: this seems to break the effect, so likely the other colors here are hardcoded for it
  float luminance = GetLuminance(sceneColor.rgb);
#else
  float luminance = dot(sceneColor.rgb, float3(0.298900008,0.595899999,0.211500004));
#endif
  r1.y = luminance + sceneColor.w;
  r1.zw = float2(0.272000015, 0.647400022) * sceneColor.w;
  r1.xz = luminance * float2(0.95599997, 0.620999992) - r1.zw;

  float4 outColor = sceneColor;
  outColor.y = 0.32159999 * outColor.y;
  outColor.x = outColor.x * 0.114 - outColor.y;
  outColor.x = outColor.z * 0.311399996 + outColor.x;

  o0.x = r1.y + outColor.x;
  o0.y = -outColor.x * 1.10599995 + r1.x;
  o0.z = outColor.x * 1.70459998 + r1.z;

  o0.w = 1;
}