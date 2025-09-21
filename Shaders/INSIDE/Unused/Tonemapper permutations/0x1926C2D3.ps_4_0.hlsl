// ---- Created with 3Dmigoto v1.3.16 on Fri Sep 19 02:15:01 2025
Texture2D<float4> t3 : register(t3);

Texture2D<float4> t2 : register(t2);

Texture2D<float4> t1 : register(t1);

Texture2D<float4> t0 : register(t0);

SamplerState s3_s : register(s3);

SamplerState s2_s : register(s2);

SamplerState s1_s : register(s1);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[12];
}




// 3Dmigoto declarations
#define cmp -


void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  nointerpolation float4 v2 : TEXCOORD1,
  nointerpolation float2 v3 : TEXCOORD2,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xyzw = t0.SampleLevel(s3_s, v1.xy, 0).xyzw;
  r0.xy = r0.xy * float2(0.0235294122,0.0235294122) + v1.xy;
  r1.xyzw = r0.zwzw * float4(0.0117647061,0.0117647061,0.0117647061,0.0117647061) + float4(-0.00588235306,-0.00588235306,-0.00588235306,-0.00588235306);
  r0.xy = float2(-0.0117647061,-0.0117647061) + r0.xy;
  r0.xy = r1.xy * float2(0.166666672,0.166666672) + r0.xy;
  r0.zw = r1.zw * float2(0.666666687,0.666666687) + r0.xy;
  r1.xy = r0.xy + r0.zw;
  r1.xy = float2(0.5,0.5) * r1.xy;
  r2.xyzw = t2.Sample(s0_s, r1.xy).xyzw;
  r1.xyzw = t3.Sample(s1_s, r1.xy).xyzw;
  r1.w = 0.629960537 + r2.w;
  r1.xyzw = r1.xyzw * r1.xyzw;
  r1.w = r1.w * r1.w + 0.842509866;
  r2.xyz = r2.xyz * r1.www;
  r3.xyzw = t2.Sample(s0_s, r0.xy).xyzw;
  r4.xyzw = t3.Sample(s1_s, r0.xy).xyzw;
  r4.xyz = r4.xyz * r4.xyz;
  r0.x = 0.629960537 + r3.w;
  r0.x = r0.x * r0.x;
  r0.x = r0.x * r0.x + 0.842509866;
  r3.xyz = r3.xyz * r0.xxx;
  r0.x = 1 + -cb0[6].z;
  r2.xz = r0.xx * r2.xz;
  r3.yz = r0.xx * r3.yz;
  r2.xyz = r3.xyz + r2.xyz;
  r3.xyzw = t2.Sample(s0_s, r0.zw).xyzw;
  r5.xyzw = t3.Sample(s1_s, r0.zw).xyzw;
  r0.yzw = r5.xyz * r5.xyz;
  r1.w = 0.629960537 + r3.w;
  r1.w = r1.w * r1.w;
  r1.w = r1.w * r1.w + 0.842509866;
  r3.xyz = r3.xyz * r1.www;
  r3.xy = r3.xy * r0.xx;
  r2.xyz = r3.xyz + r2.xyz;
  r3.xy = -cb0[6].zz + r0.xx;
  r3.z = r0.x + r0.x;
  r3.xyz = float3(2,2,1) + r3.xyz;
  r5.xyz = (int3)-r3.yyz + int3(0x7ef311c3,0x7ef311c3,0x7ef311c3);
  r3.xyz = -r5.yyz * r3.xyz + float3(2,2,2);
  r3.xyz = r5.xyz * r3.xyz;
  r2.xyz = saturate(r3.xyz * r2.xyz);
  r2.xyz = float3(1,1,1) + -r2.xyz;
  r1.xz = r0.xx * r1.xz;
  r4.yz = r0.xx * r4.yz;
  r0.yz = r0.xx * r0.yz;
  r1.xyz = r4.xyz + r1.xyz;
  r0.xyz = r1.xyz + r0.yzw;
  r0.xyz = saturate(r0.xyz * r3.xyz);
  r0.xyz = float3(1,1,1) + -r0.xyz;
  r0.xyz = -r0.xyz * r2.xyz + float3(1,1,1);
  r0.xyz = max(cb0[10].xxx, r0.xyz);
  r0.xyz = -cb0[10].xxx + r0.xyz;
  r0.w = cb0[10].y + -cb0[10].x;
  r0.xyz = r0.xyz / r0.www;
  r0.xyz = log2(r0.xyz);
  r0.xyz = cb0[10].zzz * r0.xyz;
  r0.xyz = exp2(r0.xyz);
  r0.w = 1 + -cb0[11].x;
  r0.xyz = r0.xyz * r0.www + cb0[11].xxx;
  r1.xyz = float3(1,1,1) + -r0.xyz;
  r0.w = 0.200000003 * cb0[10].w;
  r2.xyz = r1.xyz * r1.xyz + r0.www;
  r3.xyz = float3(0.5,0.5,0.5) * r2.xyz;
  r4.xyz = (uint3)r2.xyz >> 1;
  r4.xyz = (int3)-r4.xyz + int3(0x5f375a86,0x5f375a86,0x5f375a86);
  r5.xyz = r4.xyz * r4.xyz;
  r3.xyz = -r3.xyz * r5.xyz + float3(1.5,1.5,1.5);
  r3.xyz = r4.xyz * r3.xyz;
  r1.xyz = -r2.xyz * r3.xyz + r1.xyz;
  r0.xyz = r1.xyz * float3(0.5,0.5,0.5) + r0.xyz;
  r0.xyz = saturate(r0.xyz * v3.yyy + v3.xxx);
  r1.xyz = r0.xyz * v2.xxx + v2.yyy;
  r1.xyz = r0.xyz * r1.xyz + v2.zzz;
  r0.xyz = r0.xyz * r1.xyz + v2.www;
  r1.xy = cb0[9].yz + v0.xy;
  r1.xy = cb0[8].xy * r1.xy;
  r1.xyzw = t1.SampleLevel(s2_s, r1.xy, 0).xyzw;
  r1.xyz = r1.xyz * float3(5,5,5) + float3(-2,-2,-2);
  o0.xyz = r1.xyz * float3(0.00456620986,0.00456620986,0.00456620986) + r0.xyz;
  o0.w = 1;
  return;
}