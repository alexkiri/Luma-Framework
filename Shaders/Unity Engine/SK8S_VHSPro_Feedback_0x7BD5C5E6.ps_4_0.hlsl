Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[34];
}

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  float2 w1 : TEXCOORD1,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2;
  r0.xyzw = t1.Sample(s1_s, v1.xy).xyzw;
  r1.x = 1 / cb0[26].x;
  r1.y = 0;
  r1.zw = v1.xy + r1.xy;
  r1.xy = v1.xy + -r1.xy;
  r2.xyzw = t1.Sample(s1_s, r1.xy).xyzw;
  r1.xyzw = t1.Sample(s1_s, r1.zw).xyzw;
  r1.xyz = float3(0.25,0.25,0.25) * r1.xyz;
  r0.xyz = r0.xyz * float3(0.5,0.5,0.5) + r1.xyz;
  r0.xyz = r2.xyz * float3(0.25,0.25,0.25) + r0.xyz;
  r0.xyz = -r0.xyz * cb0[32].yyy + float3(1,1,1);
  r1.xyzw = t2.Sample(s1_s, v1.xy).xyzw;
  r2.xyzw = t0.Sample(s0_s, v1.xy).xyzw;
  r1.xyz = saturate(r2.xyz + -r1.xyz);
  r0.w = r1.x + r1.y;
  r0.w = r0.w + r1.z;
  r0.w = 0.333333343 * r0.w;
  r1.x = (r0.w < cb0[32].z);
  r0.w = r1.x ? 0 : r0.w;
  r1.xyz = r2.xyz * r0.www;
  r1.xyz = -r1.xyz * cb0[32].xxx + float3(1,1,1);
  r0.xyz = -r1.xyz * r0.xyz + float3(1,1,1);
  o0.xyz = cb0[33].xyz * r0.xyz;
  o0.w = 1;
}