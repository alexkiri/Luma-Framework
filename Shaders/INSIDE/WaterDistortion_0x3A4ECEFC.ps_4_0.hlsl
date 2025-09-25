Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

#define cmp

void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  nointerpolation float4 v3 : TEXCOORD2,
  float v4 : TEXCOORD3,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1;
  r0.xy = float2(-1,1) * v3.yx;
  r1.xyzw = t0.Sample(s1_s, v2.zw).xyzw;
  r0.zw = r1.wx * float2(2,2) + float2(-1,-1);
  r0.y = dot(r0.xy, r0.zw);
  r0.x = dot(v3.xy, r0.zw);
  r0.z = saturate(v4.x);
  r0.xy = r0.xy * r0.zz;
  r0.z = v3.z * r0.y;
  r0.xy = v1.xy + r0.xz;
  r0.xy = r0.xy / v1.ww;
  r0.xyzw = t1.Sample(s2_s, r0.xy).xyzw;
  o0.xyz = r0.xyz;
  r0.xyzw = t2.Sample(s0_s, v2.xy).xyzw;
  o0.w = v3.w * r0.w;
  
  // Luma: typical UNORM like clamping
  o0.a = saturate(o0.a);
}