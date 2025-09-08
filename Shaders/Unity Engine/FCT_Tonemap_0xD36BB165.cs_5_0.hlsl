#include "../Includes/Common.hlsl"

Texture2DArray<float4> t0 : register(t0);
Texture2DArray<float4> t1 : register(t1);
Texture2D<float4> t2 : register(t2);
Texture3D<float4> t3 : register(t3);

RWTexture2DArray<float4> u0 : register(u0);

SamplerState s0_s : register(s0);
SamplerState s1_s : register(s1);

cbuffer cb1 : register(b1)
{
  float4 cb1[13];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[44];
}

[numthreads(8, 8, 1)]
void main(uint3 vThreadID: SV_DispatchThreadID)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7;
  r0.xyz = vThreadID.xyz;
  r1.xy = 0.5 + r0.xy;
  r1.xy = cb0[42].zw * r1.xy;
  r1.zw = -cb0[42].zw * 0.5 + 1.0;
  r1.zw = min(r1.xy, r1.zw);
  r0.xy = cb0[43].xy * r1.zw;
  r2.xyz = t0.SampleLevel(s0_s, r0.xyz, 0).xyz;
  if (cb1[7].z != 0)
  {
    r1.zw = cb0[43].xy * r1.xy;
    r1.zw = r1.zw * cb1[11].xy + 0.5;
    r3.xy = floor(r1.zw);
    r1.zw = frac(r1.zw);
    r4.xyzw = -r1.zwzw * float4(0.5,0.5,0.166666672,0.166666672) + 0.5;
    r4.xyzw = r1.zwzw * r4.xyzw + float4(0.5,0.5,-0.5,-0.5);
    r3.zw = r1.zw * 0.5 - 1.0;
    r5.xy = r1.zw * r1.zw;
    r3.zw = r5.xy * r3.zw + 0.666666687;
    r4.xyzw = r1.zwzw * r4.xyzw + 0.166666672;
    r1.zw = 1.0 - r3.zw;
    r1.zw = r1.zw + -r4.xy;
    r1.zw = r1.zw + -r4.zw;
    r4.zw = r4.zw + r3.zw;
    r4.xy = r4.xy + r1.zw;
    r5.xy = rcp(r4.zw);
    r5.zw = r3.zw * r5.xy - 1.0;
    r3.zw = rcp(r4.xy);
    r5.xy = r1.zw * r3.zw + 1.0;
    r6.xyzw = r5.zwxw + r3.xyxy;
    r6.xyzw = -0.5 + r6.xyzw;
    r6.xyzw = cb1[11].zwzw * r6.xyzw;
    r0.xy = min(cb0[43].xy, r6.xy);
    r7.xyz = t1.SampleLevel(s0_s, r0.xyz, 0).xyz;
    r0.xy = min(cb0[43].xy, r6.zw);
    r6.xyz = t1.SampleLevel(s0_s, r0.xyz, 0).xyz;
    r6.xyz = r6.xyz * r4.x;
    r6.xyz = r4.z * r7.xyz + r6.xyz;
    r3.xyzw = r5.zyxy + r3.xyxy;
    r3.xyzw = -0.5 + r3.xyzw;
    r3.xyzw = cb1[11].zwzw * r3.xyzw;
    r0.xy = min(cb0[43].xy, r3.xy);
    r5.xyz = t1.SampleLevel(s0_s, r0.xyz, 0).xyz;
    r0.xy = min(cb0[43].xy, r3.zw);
    r0.xyz = t1.SampleLevel(s0_s, r0.xyz, 0).xyz;
    r0.xyz = r4.x * r0.xyz;
    r0.xyz = r4.z * r5.xyz + r0.xyz;
    r0.xyz = r4.y * r0.xyz;
    r0.xyz = r4.w * r6.xyz + r0.xyz;
    r0.w = max(r2.x, r2.y);
    r0.w = max(r0.w, r2.z);
    r1.zw = -cb1[8].yx + r0.ww;
    r1.z = max(0, r1.z);
    r1.z = min(cb1[8].z, r1.z);
    r1.z = r1.z * r1.z;
    r1.z = cb1[8].w * r1.z;
    r1.z = max(r1.z, r1.w);
    r0.w = max(9.99999975e-05, r0.w);
    r0.w = r1.z / r0.w;
    r3.xyz = -r2.xyz * r0.w + r2.xyz;
    r3.xyz = r0.xyz * cb1[9].xyz + r3.xyz;
    r3.xyz = r3.xyz + -r2.xyz;
    r2.xyz = cb1[7].x * r3.xyz + r2.xyz;
    if (cb1[7].w != 0)
    {
      r1.xy = r1.xy * cb1[10].xy + cb1[10].zw;
      r1.xyz = t2.SampleLevel(s0_s, r1.xy, 0).xyz;
      r0.xyz = r1.xyz * r0.xyz;
      r2.xyz = r0.xyz * cb1[7].yyy + r2.xyz;
    }
  }

  if (cb1[12].x != 0)
  {
    r0.xyz = r2.xyz * float3(5.55555582,5.55555582,5.55555582) + float3(0.0479959995,0.0479959995,0.0479959995);
    r0.xyz = max(float3(0,0,0), r0.xyz);
    r0.xyz = log2(r0.xyz);
    r0.xyz = (r0.xyz * float3(0.0734997839,0.0734997839,0.0734997839) + float3(0.386036009,0.386036009,0.386036009)); // LUMA: removed saturate()
  }
  else
  {
    r1.xyz = cb1[6].z * r2.xyz;
    r1.xyz = r1.xyz * float3(5.55555582,5.55555582,5.55555582) + float3(0.0479959995,0.0479959995,0.0479959995);
    r1.xyz = max(float3(0,0,0), r1.xyz);
    r1.xyz = log2(r1.xyz);
    r1.xyz = saturate(r1.xyz * float3(0.0734997839,0.0734997839,0.0734997839) + float3(0.386036009,0.386036009,0.386036009)); // LUMA: we can keep this saturate() as the range is very large
    r1.xyz = cb1[6].yyy * r1.xyz;
    r0.w = 0.5 * cb1[6].x;
    r1.xyz = r1.xyz * cb1[6].x + r0.w;
    r0.xyz = t3.SampleLevel(s1_s, r1.xyz, 0).xyz;
  }

  u0[vThreadID] = r0.xyzx;
}