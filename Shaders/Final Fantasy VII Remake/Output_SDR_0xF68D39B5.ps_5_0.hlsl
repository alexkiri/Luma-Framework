#include "includes/common.hlsl"
#include "../Includes/Color.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

Texture2D<float4> t4 : register(t4);

Texture3D<float4> t3 : register(t3);

Texture3D<float4> t2 : register(t2);

Texture2D<float4> t1 : register(t1);

Texture3D<float4> t0 : register(t0);

SamplerState s2_s : register(s2);

SamplerState s1_s : register(s1);

SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[140];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[39];
}




// 3Dmigoto declarations
#define cmp -


void main(
  float4 v0 : SV_POSITION0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xy = cmp(cb0[34].xy < v0.xy);
  r0.zw = cmp(v0.xy < cb0[34].zw);
  r0.xy = r0.zw ? r0.xy : 0;
  r0.x = r0.y ? r0.x : 0;
  if ((cb0[34].x < v0.x && v0.x < cb0[34].z)
      && (cb0[34].y < v0.y && v0.y < cb0[34].w)) {
    int2 v0xy = asint(v0.xy);
    int2 cb034xy = asint(cb0[34].xy);
    r0.xy = (int2)v0.xy;
    r1.xy = asint(cb0[34].xy);
    // r1.xy = (int2)(r0.xy) + -r1.xy;
    // r1.xy = (int2)r1.xy;
    r1.xy = float2(0.5, 0.5) + int2(v0.xy - cb034xy);
    r1.zw = cb0[35].zw * r1.xy;
    r2.xy = cb0[35].xy * cb0[35].wz;
    r1.xy = r1.xy * cb0[35].zw + float2(-0.5,-0.5);
    r2.xy = float2(0.5625,1.77777779) * r2.xy;
    r2.xy = min(float2(1,1), r2.xy);
    r1.xy = r1.xy * r2.xy + float2(0.5,0.5);
    r1.zw = r1.zw * cb0[31].xy + cb0[30].xy;
    r1.zw = cb0[0].zw * r1.zw;
    r2.xyz = t1.SampleLevel(s0_s, r1.zw, 0).xyz;
    r3.xyz = float3(0.00999999978,0.00999999978,0.00999999978) * r2.xyz;
    r3.xyz = max(float3(0,0,0), r3.xyz);
    r3.xyz = log2(r3.xyz);
    r3.xyz = float3(0.159301758,0.159301758,0.159301758) * r3.xyz;
    r3.xyz = exp2(r3.xyz);
    r4.xyzw = r3.xxyy * float4(18.8515625,18.6875,18.8515625,18.6875) + float4(0.8359375,1,0.8359375,1);
    r1.zw = rcp(r4.yw);
    r1.zw = r4.xz * r1.zw;
    r1.zw = log2(r1.zw);
    r1.zw = float2(78.84375,78.84375) * r1.zw;
    r1.zw = exp2(r1.zw);
    r4.xy = min(float2(1,1), r1.zw);
    r1.zw = r3.zz * float2(18.8515625,18.6875) + float2(0.8359375,1);
    r0.w = rcp(r1.w);
    r0.w = r1.z * r0.w;
    r0.w = log2(r0.w);
    r0.w = 78.84375 * r0.w;
    r0.w = exp2(r0.w);
    r4.z = min(1, r0.w);
    uint w, h, d;
    t2.GetDimensions(w, h, d);
    r0.w = (w == 32 && h == 32 && d == 32) ? 32 : 0;
    r1.z = r0.w ? 31.000000 : 0;
    r3.xy = r0.ww ? float2(0.03125,0.015625) : float2(1,0.5);
    r0.w = r3.x * r1.z;
    r3.xyz = r4.xyz * r0.www + r3.yyy;
    r3.xyz = t2.SampleLevel(s1_s, r3.xyz, 0).xyz;
    t3.GetDimensions(w, h, d);
    r0.w = (w == 32 && h == 32 && d == 32) ? 32 : 0;
    r1.z = r0.w ? 31.000000 : 0;
    r4.xy = r0.ww ? float2(0.03125,0.015625) : float2(1,0.5);
    r0.w = r4.x * r1.z;
    r3.xyz = r3.xyz * r0.www + r4.yyy;
    r3.xyz = t3.SampleLevel(s1_s, r3.xyz, 0).xyz;
    r2.xyz = saturate(r2.xyz);
    r2.xyz = log2(r2.xyz);
    r2.xyz = float3(0.454545438,0.454545438,0.454545438) * r2.xyz;
    r2.xyz = exp2(r2.xyz);
    r4.xyz = cmp(r2.xyz < float3(0.100000001,0.100000001,0.100000001));
    r5.xyz = float3(0.699999988,0.699999988,0.699999988) * r2.xyz;
    r6.xyz = cmp(r2.xyz < float3(0.200000003,0.200000003,0.200000003));
    r7.xyz = r2.xyz * float3(0.899999976,0.899999976,0.899999976) + float3(-0.0199999996,-0.0199999996,-0.0199999996);
    r8.xyz = cmp(r2.xyz < float3(0.300000012,0.300000012,0.300000012));
    r9.xyz = r2.xyz * float3(1.10000002,1.10000002,1.10000002) + float3(-0.0599999987,-0.0599999987,-0.0599999987);
    r10.xyz = cmp(r2.xyz < float3(0.5,0.5,0.5));
    r11.xyz = r2.xyz * float3(1.14999998,1.14999998,1.14999998) + float3(-0.075000003,-0.075000003,-0.075000003);
    r2.xyz = r10.xyz ? r11.xyz : r2.xyz;
    r2.xyz = r8.xyz ? r9.xyz : r2.xyz;
    r2.xyz = r6.xyz ? r7.xyz : r2.xyz;
    r2.xyz = r4.xyz ? r5.xyz : r2.xyz;
    r0.w = cmp(0 < cb0[38].x);
    r2.xyz = r0.www ? r2.xyz : r3.xyz;
    r3.xyz = cmp(r2.xyz < float3(0.0404499993,0.0404499993,0.0404499993));
    r4.xyz = float3(0.0773993805,0.0773993805,0.0773993805) * r2.xyz;
    r2.xyz = float3(0.0549999997,0.0549999997,0.0549999997) + r2.xyz;
    r2.xyz = float3(0.947867334,0.947867334,0.947867334) * r2.xyz;
    r2.xyz = log2(r2.xyz);
    r2.xyz = float3(2.4000001,2.4000001,2.4000001) * r2.xyz;
    r2.xyz = exp2(r2.xyz);
    r2.xyz = r3.xyz ? r4.xyz : r2.xyz;
    r2.xyz = log2(abs(r2.xyz));
    r2.xyz = cb0[27].xxx * r2.xyz;
    r2.xyz = exp2(r2.xyz);
    r1.xyzw = t4.SampleLevel(s2_s, r1.xy, 0).xyzw;
    r0.w = dot(r2.xyz, float3(0.212599993,0.715200007,0.0722000003));
    r2.xyz = r2.xyz + -r0.www;
    r2.xyz = cb0[25].xxx * r2.xyz + r0.www;
    r0.w = cb0[25].y * r1.w;
    r1.xyz = saturate(r2.xyz * r0.www + r1.xyz);

    r2.xyz = cmp(r1.xyz < float3(0.00313080009,0.00313080009,0.00313080009));
    r3.xyz = float3(12.9200001,12.9200001,12.9200001) * r1.xyz;
    r1.xyz = log2(r1.xyz);
    r1.xyz = float3(0.416666657,0.416666657,0.416666657) * r1.xyz;
    r1.xyz = exp2(r1.xyz);
    r1.xyz = r1.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
    r1.xyz = r2.xyz ? r3.xyz : r1.xyz;

    r0.z = asuint(cb1[139].z) << 3;
    r0.xyz = (int3)r0.xyz & int3(63,63,63);
    r0.w = 0;
    r0.x = t0.Load(r0.xyzw).x;
    r0.x = r0.x * 2 + -1;
    r0.y = cmp(0 < r0.x);
    r0.z = cmp(r0.x < 0);
    r0.y = (int)-r0.y + (int)r0.z;
    r0.y = (int)r0.y;
    r0.x = 1 + -abs(r0.x);
    r0.x = sqrt(r0.x);
    r0.x = 1 + -r0.x;
    r0.x = r0.y * r0.x;
    r0.yzw = r1.xyz * float3(2,2,2) + float3(-1,-1,-1);
    r0.yzw = float3(-0.992156863,-0.992156863,-0.992156863) + abs(r0.yzw);
    r0.yzw = cmp(r0.yzw < float3(0,0,0));
    r2.xyz = r0.xxx * float3(0.00392156886,0.00392156886,0.00392156886) + r1.xyz;
    float3 color;
    color.xyz = saturate(r0.yzw ? r2.xyz : r1.xyz);
    color.xyz = gamma_to_linear(color.xyz);
    o0.xyz = color.xyz;
    o0.w = 1;
  } else {
    o0.xyzw = float4(0,0,0,0);
  }
  return;
}