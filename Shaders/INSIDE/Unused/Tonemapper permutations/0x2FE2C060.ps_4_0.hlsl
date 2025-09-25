// ---- Created with 3Dmigoto v1.3.16 on Fri Sep 19 02:15:44 2025
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
  float4 cb0[12];
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
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = 1 + -cb0[6].z;
  r1.xyzw = t0.SampleLevel(s4_s, v1.xy, 0).xyzw;
  r0.yz = r1.xy * float2(0.0235294122,0.0235294122) + v1.xy;
  r1.xyzw = r1.zwzw * float4(0.0117647061,0.0117647061,0.0117647061,0.0117647061) + float4(-0.00588235306,-0.00588235306,-0.00588235306,-0.00588235306);
  r0.yz = float2(-0.0117647061,-0.0117647061) + r0.yz;
  r2.xy = cb0[9].yz + v0.xy;
  r2.xy = cb0[8].xy * r2.xy;
  r2.xyzw = t1.SampleLevel(s3_s, r2.xy, 0).xyzw;
  r0.yz = r1.zw * float2(0.0625,0.0625) + r0.yz;
  r3.xyzw = t2.SampleLevel(s1_s, float2(0.0625,0.5), 0).xyzw;
  r3.xyz = cb0[6].zzz * r3.xyz + r0.xxx;
  r4.xyzw = t3.Sample(s0_s, r0.yz).xyzw;
  r0.w = 0.629960537 + r4.w;
  r0.w = r0.w * r0.w;
  r0.w = r0.w * r0.w + 0.842509866;
  r4.xyz = r4.xyz * r0.www;
  r4.xyz = r4.xyz * r3.xyz;
  r5.xyzw = t4.Sample(s2_s, r0.yz).xyzw;
  r5.xyz = r5.xyz * r5.xyz;
  r5.xyz = r5.xyz * r3.xyz;
  r6.y = 0.5;
  r7.xyz = r4.xyz;
  r8.xyz = r5.xyz;
  r9.xyz = r3.xyz;
  r1.zw = r0.yz;
  r6.x = 0.0625;
  r0.w = 1;
  while (true) {
    r2.w = cmp((int)r0.w >= 8);
    if (r2.w != 0) break;
    r6.x = 0.125 + r6.x;
    r1.zw = r1.xy * float2(0.125,0.125) + r1.zw;
    r10.xyzw = t2.SampleLevel(s1_s, r6.xy, 0).xyzw;
    r10.xyz = cb0[6].zzz * r10.xyz + r0.xxx;
    r9.xyz = r10.xyz + r9.xyz;
    r11.xyzw = t3.Sample(s0_s, r1.zw).xyzw;
    r2.w = 0.629960537 + r11.w;
    r2.w = r2.w * r2.w;
    r2.w = r2.w * r2.w + 0.842509866;
    r11.xyz = r11.xyz * r2.www;
    r7.xyz = r10.xyz * r11.xyz + r7.xyz;
    r11.xyzw = t4.Sample(s2_s, r1.zw).xyzw;
    r11.xyz = r11.xyz * r11.xyz;
    r8.xyz = r10.xyz * r11.xyz + r8.xyz;
    r0.w = (int)r0.w + 1;
  }
  r0.xyz = (int3)-r9.xyz + int3(0x7ef311c3,0x7ef311c3,0x7ef311c3);
  r1.xyz = -r0.xyz * r9.xyz + float3(2,2,2);
  r0.xyz = r1.xyz * r0.xyz;
  r1.xyz = saturate(r7.xyz * r0.xyz);
  r0.xyz = saturate(r8.xyz * r0.xyz);
  r0.xyz = float3(1,1,1) + -r0.xyz;
  r1.xyz = float3(1,1,1) + -r1.xyz;
  r0.xyz = -r0.xyz * r1.xyz + float3(1,1,1);
  r0.xyz = max(cb0[10].xxx, r0.xyz);
  r0.xyz = -cb0[10].xxx + r0.xyz;
  r0.w = cb0[10].y + -cb0[10].x;
  r0.xyz = r0.xyz / r0.www;
  r0.xyz = log2(r0.xyz);
  r0.xyz = cb0[10].zzz * r0.xyz;
  r0.xyz = exp2(r0.xyz);
  r0.w = 1 + -cb0[11].x;
  r0.xyz = r0.xyz * r0.www + cb0[11].xxx;
  r0.w = 0.200000003 * cb0[10].w;
  r1.xyz = float3(1,1,1) + -r0.xyz;
  r3.xyz = r1.xyz * r1.xyz + r0.www;
  r4.xyz = float3(0.5,0.5,0.5) * r3.xyz;
  r5.xyz = (uint3)r3.xyz >> 1;
  r5.xyz = (int3)-r5.xyz + int3(0x5f375a86,0x5f375a86,0x5f375a86);
  r6.xyz = r5.xyz * r5.xyz;
  r4.xyz = -r4.xyz * r6.xyz + float3(1.5,1.5,1.5);
  r4.xyz = r5.xyz * r4.xyz;
  r1.xyz = -r3.xyz * r4.xyz + r1.xyz;
  r0.xyz = r1.xyz * float3(0.5,0.5,0.5) + r0.xyz;
  r0.xyz = saturate(r0.xyz * v3.yyy + v3.xxx);
  r1.xyz = r0.xyz * v2.xxx + v2.yyy;
  r1.xyz = r0.xyz * r1.xyz + v2.zzz;
  r0.xyz = r0.xyz * r1.xyz + v2.www;
  r1.xyz = r2.xyz * float3(5,5,5) + float3(-2,-2,-2);
  r1.xyz = float3(0.00456620986,0.00456620986,0.00456620986) * r1.xyz;
  o0.xyz = r0.xyz * v3.zzz + r1.xyz;
  o0.w = 1;
  return;
}