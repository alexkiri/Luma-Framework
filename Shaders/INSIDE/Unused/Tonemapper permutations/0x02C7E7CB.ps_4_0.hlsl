// ---- Created with 3Dmigoto v1.3.16 on Fri Sep 19 02:14:39 2025
Texture2D<float4> t4 : register(t4);

Texture2D<float4> t3 : register(t3);

Texture2D<float4> t2 : register(t2);

Texture2D<float4> t1 : register(t1);

Texture2D<float4> t0 : register(t0);

SamplerState s4_s : register(s4);

SamplerState s3_s : register(s3);

SamplerState s2_s : register(s2);

SamplerState s1_s : register(s1);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[14];
}




// 3Dmigoto declarations
#define cmp -


void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  nointerpolation float4 v2 : TEXCOORD1,
  nointerpolation float3 v3 : TEXCOORD2,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xyzw = t0.SampleLevel(s4_s, v1.xy, 0).xyzw;
  r0.xy = r0.xy * float2(0.0235294122,0.0235294122) + v1.xy;
  r0.zw = r0.zw * float2(0.0117647061,0.0117647061) + float2(-0.00588235306,-0.00588235306);
  r0.xy = float2(-0.0117647061,-0.0117647061) + r0.xy;
  r1.xy = cb0[9].yz + v0.xy;
  r1.xy = cb0[8].xy * r1.xy;
  r1.xyzw = t1.SampleLevel(s3_s, r1.xy, 0).xyzw;
  r2.x = 0.333332986 * r1.w;
  r0.xy = r2.xx * r0.zw + r0.xy;
  r0.zw = r0.zw * float2(0.666666687,0.666666687) + r0.xy;
  r3.xyzw = t3.Sample(s0_s, r0.xy).xyzw;
  r2.z = 0.629960537 + r3.w;
  r2.z = r2.z * r2.z;
  r2.z = r2.z * r2.z + 0.842509866;
  r3.xyz = r3.xyz * r2.zzz;
  r2.zw = r0.xy + r0.zw;
  r4.xyzw = t4.Sample(s2_s, r0.xy).xyzw;
  r4.xyz = r4.xyz * r4.xyz;
  r0.xy = float2(0.5,0.5) * r2.zw;
  r5.xyzw = t3.Sample(s0_s, r0.xy).xyzw;
  r6.xyzw = t4.Sample(s2_s, r0.xy).xyzw;
  r6.xyz = r6.xyz * r6.xyz;
  r0.x = 0.629960537 + r5.w;
  r0.x = r0.x * r0.x;
  r0.x = r0.x * r0.x + 0.842509866;
  r5.xyz = r5.xyz * r0.xxx;
  r7.xy = r1.ww * float2(0.333332986,0.333332986) + float2(0.333330005,0.666670024);
  r1.xyz = r1.xyz * float3(5,5,5) + float3(-2,-2,-2);
  r1.xyz = float3(0.00456620986,0.00456620986,0.00456620986) * r1.xyz;
  r7.z = 0.5;
  r8.xyzw = t2.SampleLevel(s1_s, r7.xz, 0).xyzw;
  r7.xyzw = t2.SampleLevel(s1_s, r7.yz, 0).xyzw;
  r0.x = 1 + -cb0[6].z;
  r8.xyz = cb0[6].zzz * r8.xyz + r0.xxx;
  r5.xyz = r8.xyz * r5.xyz;
  r2.y = 0.5;
  r2.xyzw = t2.SampleLevel(s1_s, r2.xy, 0).xyzw;
  r2.xyz = cb0[6].zzz * r2.xyz + r0.xxx;
  r7.xyz = cb0[6].zzz * r7.xyz + r0.xxx;
  r3.xyz = r2.xyz * r3.xyz + r5.xyz;
  r5.xyzw = t3.Sample(s0_s, r0.zw).xyzw;
  r0.xyzw = t4.Sample(s2_s, r0.zw).xyzw;
  r0.w = 0.629960537 + r5.w;
  r0.xyzw = r0.xyzw * r0.xyzw;
  r0.w = r0.w * r0.w + 0.842509866;
  r5.xyz = r5.xyz * r0.www;
  r3.xyz = r7.xyz * r5.xyz + r3.xyz;
  r5.xyz = r2.xyz + r8.xyz;
  r6.xyz = r8.xyz * r6.xyz;
  r2.xyz = r2.xyz * r4.xyz + r6.xyz;
  r0.xyz = r7.xyz * r0.xyz + r2.xyz;
  r2.xyz = r5.xyz + r7.xyz;
  r4.xyz = (int3)-r2.xyz + int3(0x7ef311c3,0x7ef311c3,0x7ef311c3);
  r2.xyz = -r4.xyz * r2.xyz + float3(2,2,2);
  r2.xyz = r4.xyz * r2.xyz;
  r3.xyz = saturate(r3.xyz * r2.xyz);
  r0.xyz = saturate(r2.xyz * r0.xyz);
  r0.xyz = float3(1,1,1) + -r0.xyz;
  r2.xyz = float3(1,1,1) + -r3.xyz;
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
  r2.xyz = float3(1,1,1) + -r0.xyz;
  r0.w = 0.200000003 * cb0[10].w;
  r3.xyz = r2.xyz * r2.xyz + r0.www;
  r4.xyz = float3(0.5,0.5,0.5) * r3.xyz;
  r5.xyz = (uint3)r3.xyz >> 1;
  r5.xyz = (int3)-r5.xyz + int3(0x5f375a86,0x5f375a86,0x5f375a86);
  r6.xyz = r5.xyz * r5.xyz;
  r4.xyz = -r4.xyz * r6.xyz + float3(1.5,1.5,1.5);
  r4.xyz = r5.xyz * r4.xyz;
  r2.xyz = -r3.xyz * r4.xyz + r2.xyz;
  r0.xyz = r2.xyz * float3(0.5,0.5,0.5) + r0.xyz;
  r0.xyz = saturate(r0.xyz * v3.yyy + v3.xxx);
  r2.xyz = cb0[3].xyz * r0.xyz;
  r2.xz = r2.xx + r2.yz;
  r0.w = r2.y * r2.z;
  r1.w = r0.z * cb0[3].z + r2.x;
  r0.w = sqrt(r0.w);
  r0.w = r0.w + r0.w;
  r0.w = r0.w * cb0[3].w + r1.w;
  r0.xyz = r0.xyz + -r0.www;
  r0.xyz = cb0[13].xxx * r0.xyz + r0.www;
  r2.xyz = r0.xyz * v2.xxx + v2.yyy;
  r2.xyz = r0.xyz * r2.xyz + v2.zzz;
  r0.xyz = r0.xyz * r2.xyz + v2.www;
  r0.xyz = v3.zzz * r0.xyz;
  o0.xyz = r0.xyz * cb0[12].xxx + r1.xyz;
  o0.w = 1;
  return;
}