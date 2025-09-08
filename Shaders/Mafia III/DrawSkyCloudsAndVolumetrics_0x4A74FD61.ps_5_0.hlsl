Texture2D<float4> t6 : register(t6); // Depth?
Texture2D<float4> t5 : register(t5);
Texture2D<float4> t4 : register(t4);
Texture2D<float4> t3 : register(t3); // Depth Mip
Texture2D<float4> t2 : register(t2); // Volumetrics
Texture2D<float4> t1 : register(t1); // Scene
Texture2D<float4> t0 : register(t0); // Depth

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb2 : register(b2)
{
  float4 cb2[6];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[3];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[1];
}

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD2,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9;
  if (cb1[2].x != 0.0f) {
    r0.x = t0.SampleLevel(s0_s, v1.xy, 0).x;
  } else {
    r0.x = 1;
  }
  r1.x = v2.w;
  r1.y = v3.x;
  r1.xyzw = t1.Sample(s0_s, r1.xy).xyzw;
  r0.y = t3.SampleLevel(s1_s, v1.zw, 0).x;
  r0.z = cb2[4].x * cb1[1].w;
  r0.z = max(9.99999975e-006, r0.z);
  r0.w = min(r0.x, r0.y);
  r0.w = r0.w / r0.z;
  r0.w = rsqrt(r0.w);
  r0.w = 1 / r0.w;
  r0.w = min(1, r0.w);
  r0.w = r0.w * cb2[5].x + -1;
  r2.x = cb2[5].x + -1;
  r2.y = max(0, r0.w);
  r2.y = min(r2.y, r2.x);
  r2.y = floor(r2.y);
  r2.z = v1.z + r2.y;
  r3.x = cb2[5].y * r2.z;
  r3.y = v1.w;
  r4.xyz = t2.SampleLevel(s1_s, r3.xy, 0).xyz;
  r3.xyz = t5.SampleLevel(s1_s, r3.xy, 0).xyz;
  r5.xyz = float3(1,1,1) + -r3.xyz;
  if (r0.x > r0.z) {
    r6.xyz = t4.SampleLevel(s1_s, v1.zw, 0).xyz;
    r7.xyz = t6.SampleLevel(s1_s, v1.zw, 0).xyz;
    r8.xyz = float3(1,1,1) + -r7.xyz;
    r2.zw = r0.xy + -r0.zz;
    r2.w = min(r2.w, r0.z);
    r2.w = max(9.99999975e-006, r2.w);
    r2.z = saturate(r2.z / r2.w);
    r0.z = r0.x / r0.z;
    r9.xyz = log2(r5.xyz);
    r9.xyz = r9.xyz * r0.zzz;
    r5.xyz = exp2(r9.xyz);
    r9.xyz = float3(-1,-1,-1) + r5.xyz;
    r9.xyz = r9.xyz * r4.xyz;
    r3.xyz = min(float3(-9.99999975e-006,-9.99999975e-006,-9.99999975e-006), -r3.xyz);
    r3.xyz = r9.xyz / r3.xyz;
    r0.y = max(9.99999975e-006, r0.y);
    r0.x = r0.x / r0.y;
    r8.xyz = log2(r8.xyz);
    r0.xyz = r8.xyz * r0.xxx;
    r0.xyz = exp2(r0.xyz);
    r8.xyz = float3(-1,-1,-1) + r0.xyz;
    r6.xyz = r8.xyz * r6.xyz;
    r7.xyz = min(float3(-9.99999975e-006,-9.99999975e-006,-9.99999975e-006), -r7.xyz);
    r6.xyz = r6.xyz / r7.xyz;
    r6.xyz = r6.xyz + -r3.xyz;
    r3.xyz = r2.zzz * r6.xyz + r3.xyz;
  } else {
    r2.w = 1 + r2.y;
    r2.x = min(r2.w, r2.x);
    r2.x = v1.z + r2.x;
    r6.x = cb2[5].y * r2.x;
    r6.y = v1.w;
    r7.xyz = t2.SampleLevel(s1_s, r6.xy, 0).xyz;
    r6.xyz = t5.SampleLevel(s1_s, r6.xy, 0).xyz;
    r0.xyz = float3(1,1,1) + -r6.xyz;
    r2.z = -r2.y + r0.w;
    r0.w = saturate(r2.z);
    r2.xyw = r7.xyz + -r4.xyz;
    r3.xyz = r0.www * r2.xyw + r4.xyz;
  }
  r2.z = saturate(r2.z);
  r0.xyz = r0.xyz + -r5.xyz;
  r0.xyz = r2.zzz * r0.xyz + r5.xyz;
  r2.xyz = cb0[0].xxx * r3.xyz;
  o0.xyz = r1.xyz * r0.xyz + r2.xyz;
  o0.w = r1.w;
}