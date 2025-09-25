void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float4 v2 : COLOR0,
  out float4 o0 : SV_Target0)
{
  float4 r0;
  r0.x = dot(v1.xy, v1.xy);
  r0.x = sqrt(r0.x);
  r0.x = 1 + -r0.x;
  r0.x = max(0, r0.x);
  o0.xyzw = v2.xyzw * r0.xxxx;
  
  // Luma: typical UNORM like clamping
  o0.rgb = max(o0.rgb, 0.0);
  o0.a = saturate(o0.a);
}