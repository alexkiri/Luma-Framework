cbuffer cb0 : register(b0)
{
  float4 cb0[15];
}

// These have no depth test
void main(
  float4 v0 : SV_POSITION0,
  float3 v1 : TEXCOORD0,
  float3 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  o0.xyz = float3(0,0,0);
  o0.w = cb0[14].x;
  
  // Luma: typical UNORM like clamping (unlikely to be needed here)
  o0.a = saturate(o0.a);
}