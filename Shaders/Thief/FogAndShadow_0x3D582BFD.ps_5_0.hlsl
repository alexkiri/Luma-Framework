Texture2D<float4> t5 : register(t5);
Texture2D<float4> t4 : register(t4);
Texture2D<float4> t3 : register(t3);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s5_s : register(s5);
SamplerState s4_s : register(s4);
SamplerState s3_s : register(s3);
SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb2 : register(b2)
{
  float4 cb2[3];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}

// 3Dmigoto declarations
#define cmp -

void main(
  float2 v0 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
#if 0 // Disable
  o0 = t3.Sample(s0_s, v0.xy);
  return;
#endif
  float4 r0,r1,r2,r3,r4;
  r0.xy = v0.xy * cb0[1].xy + float2(-0.5,-0.5);
  r0.zw = round(r0.xy);
  r0.xy = r0.xy + -r0.zw;
  r0.zw = cmp(float2(0,0) < r0.xy);
  r0.xy = cmp(r0.xy < float2(0,0));
  r0.xy = (int2)r0.xy + (int2)-r0.zw;
  r0.xy = (int2)r0.xy;
  r0.zw = r0.xy * cb0[1].zw + v0.xy;
  r1.xy = cb0[1].zw * r0.xy;
  r0.x = t1.Sample(s2_s, r0.zw).x;
  r2.xyzw = t2.Sample(s3_s, r0.zw).xyzw;
  r0.y = 1 + -cb2[2].y;
  r0.x = r0.x + -r0.y;
  r0.x = min(-9.99999996e-013, r0.x);
  r3.w = -cb2[2].x / r0.x;
  r1.z = 0;
  r1.xyzw = v0.xyxy + r1.xzzy;
  r0.x = t1.Sample(s2_s, r1.xy).x;
  r0.x = r0.x + -r0.y;
  r0.x = min(-9.99999996e-013, r0.x);
  r3.y = -cb2[2].x / r0.x;
  r0.x = t1.Sample(s2_s, r1.zw).x;
  r0.x = r0.x + -r0.y;
  r0.x = min(-9.99999996e-013, r0.x);
  r3.z = -cb2[2].x / r0.x;
  r0.x = t1.Sample(s2_s, v0.xy).x;
  r0.x = r0.x + -r0.y;
  r0.x = min(-9.99999996e-013, r0.x);
  r3.x = -cb2[2].x / r0.x;
  r0.x = t0.SampleLevel(s1_s, v0.xy, 0).x;
  r0.x = r0.x + -r0.y;
  r0.x = min(-9.99999996e-013, r0.x);
  r0.x = -cb2[2].x / r0.x;
  r3.xyzw = r3.xyzw + -r0.xxxx;
  r0.x = 0.05 * r0.x;
  r0.xyzw = cmp(abs(r3.xyzw) < r0.xxxx);
  r0.xyzw = r0.xyzw ? float4(0.5625,0.1875,0.1875,0.0625) : float4(9.99999975e-005,9.99999975e-005,9.99999975e-005,9.99999975e-005);
  r3.x = r0.x + r0.y;
  r3.x = r3.x + r0.z;
  r3.x = r3.x + r0.w;
  r0.xyzw = r0.xyzw / r3.xxxx;
  r3.xyzw = t2.Sample(s3_s, r1.xy).xyzw;
  r1.xyzw = t2.Sample(s3_s, r1.zw).xyzw;
  r3.xyzw = r3.xyzw * r0.yyyy;
  r4.xyzw = t2.Sample(s3_s, v0.xy).xyzw;
  r3.xyzw = r0.xxxx * r4.xyzw + r3.xyzw;
  r1.xyzw = r0.zzzz * r1.xyzw + r3.xyzw;
  r0.xyzw = r0.wwww * r2.xyzw + r1.xyzw;
  r1.xyz = t3.Sample(s0_s, v0.xy).xyz;
  r0.xyz = r1.xyz * r0.www + r0.xyz;
  r1.xyz = r1.xyz + -r0.xyz;
  r0.w = dot(abs(r1.xyz), float3(0.333332986,0.333332986,0.333332986));
  o0.w = 1 + -r0.w;
  r1.xy = cb0[2].xy * v0.xy;
  r1.xyz = t4.Sample(s4_s, r1.xy).xyz;
  r1.xyz = r1.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r0.xyz = r1.xyz * float3(5.99999985e-005,5.99999985e-005,5.99999985e-005) + r0.xyz;
  r1.xyzw = t5.Sample(s5_s, v0.xy).xyzw;
  r1.xyz = cb0[2].zzz * r1.xyz;
  r1.xyz = r1.www * -r1.xyz + r1.xyz;
  o0.xyz = r1.xyz + r0.xyz;
}