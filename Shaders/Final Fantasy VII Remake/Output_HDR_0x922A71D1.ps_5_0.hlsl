#include "includes/common.hlsl"
#include "../Includes/Color.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

#define GameWhiteLevelNits 203.f

Texture3D<float4> t0 : register(t0);
Texture2D<float4> t1 : register(t1);
Texture3D<float4> t2 : register(t2);
Texture3D<float4> t3 : register(t3);
Texture2D<float4> t4 : register(t4);

SamplerState s0_s : register(s0);
SamplerState s1_s : register(s1);
SamplerState s2_s : register(s2);

cbuffer cb0 : register(b0) {
  float4 cb0[39];
}

cbuffer cb1 : register(b1) {
  float4 cb1[140];
}

// 3Dmigoto declarations
#define cmp -

void main(
    float4 v0: SV_POSITION0,
    out float4 o0: SV_Target0) {
  float4 r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
  uint4 bitmask, uiDest;
  uint levels;
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
    r1.xy = r1.xy * cb0[35].zw + float2(-0.5, -0.5);
    r2.xy = float2(0.5625, 1.77777779) * r2.xy;
    r2.xy = min(float2(1, 1), r2.xy);
    r1.xy = r1.xy * r2.xy + float2(0.5, 0.5);
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
    r1.z = (int)r0.w & 0x41f80000;
    r1.z = r0.w ? 31 : 0;
    r3.xy = r0.ww ? float2(0.03125,0.015625) : float2(1,0.5);
    r0.w = r3.x * r1.z;
    r3.xyz = r4.xyz * r0.www + r3.yyy;
    r3.xyz = t2.SampleLevel(s1_s, r3.xyz, 0).xyz;
    r2.xyz = saturate(r2.xyz);
    r2.xyz = log2(r2.xyz);
    r2.xyz = float3(0.454545438, 0.454545438, 0.454545438) * r2.xyz;
    r2.xyz = exp2(r2.xyz);
    // Gamma 2.2
    // Custom piecewise shadow control?
    r4.xyz = cmp(r2.xyz < float3(0.100000001, 0.100000001, 0.100000001));
    r5.xyz = float3(0.699999988, 0.699999988, 0.699999988) * r2.xyz;
    r6.xyz = cmp(r2.xyz < float3(0.200000003, 0.200000003, 0.200000003));
    r7.xyz = r2.xyz * float3(0.899999976, 0.899999976, 0.899999976) + float3(-0.0199999996, -0.0199999996, -0.0199999996);
    r8.xyz = cmp(r2.xyz < float3(0.300000012, 0.300000012, 0.300000012));
    r9.xyz = r2.xyz * float3(1.10000002, 1.10000002, 1.10000002) + float3(-0.0599999987, -0.0599999987, -0.0599999987);
    r10.xyz = cmp(r2.xyz < float3(0.5, 0.5, 0.5));
    r11.xyz = r2.xyz * float3(1.14999998, 1.14999998, 1.14999998) + float3(-0.075000003, -0.075000003, -0.075000003);
    r2.xyz = r10.xyz ? r11.xyz : r2.xyz;
    r2.xyz = r8.xyz ? r9.xyz : r2.xyz;
    r2.xyz = r6.xyz ? r7.xyz : r2.xyz;
    r2.xyz = r4.xyz ? r5.xyz : r2.xyz;
    r0.w = cmp(0 < cb0[38].x);
    r2.xyz = r0.www ? r2.xyz : r3.xyz;

    t3.GetDimensions(w, h, d);
    r0.w = (w == 32 && h == 32 && d == 32) ? 32 : 0;
    r1.z = r0.w ? 31.000000 : 0;
    r3.xy = r0.ww ? float2(0.03125,0.015625) : float2(1,0.5);
    r0.w = r3.x * r1.z;
    r3.xyz = r2.xyz * r0.www + r3.yyy;
    r3.xyz = t3.SampleLevel(s1_s, r3.xyz, 0).xyz;
    r3.xyz = saturate(r3.xyz);
    r3.xyz = log2(r3.xyz);
    r3.xyz = float3(0.0126833133,0.0126833133,0.0126833133) * r3.xyz;
    r3.xyz = exp2(r3.xyz);
    r4.xyz = float3(-0.8359375,-0.8359375,-0.8359375) + r3.xyz;
    r3.xyz = -r3.xyz * float3(18.6875,18.6875,18.6875) + float3(18.8515625,18.8515625,18.8515625);
    r3.xyz = rcp(r3.xyz);
    r3.xyz = r4.xyz * r3.xyz;
    r3.xyz = max(float3(0,0,0), r3.xyz);
    r3.xyz = log2(r3.xyz);
    r3.xyz = float3(6.27739477,6.27739477,6.27739477) * r3.xyz;
    r3.xyz = exp2(r3.xyz);
    r3.xyz = float3(10000,10000,10000) * r3.xyz;
    r2.xyz = saturate(r2.xyz);
    r2.xyz = log2(r2.xyz);
    r2.xyz = float3(0.0126833133,0.0126833133,0.0126833133) * r2.xyz;
    r2.xyz = exp2(r2.xyz);
    r4.xyz = float3(-0.8359375,-0.8359375,-0.8359375) + r2.xyz;
    r2.xyz = -r2.xyz * float3(18.6875,18.6875,18.6875) + float3(18.8515625,18.8515625,18.8515625);
    r2.xyz = rcp(r2.xyz);
    r2.xyz = r4.xyz * r2.xyz;
    r2.xyz = max(float3(0,0,0), r2.xyz);
    r2.xyz = log2(r2.xyz);
    r2.xyz = float3(6.27739477,6.27739477,6.27739477) * r2.xyz;
    r2.xyz = exp2(r2.xyz);
    r2.xyz = r2.xyz * float3(10000,10000,10000) + -r3.xyz;
    r2.xyz = cb0[26].zzz * r2.xyz + r3.xyz;
    r1.xyzw = t4.SampleLevel(s2_s, r1.xy, 0).xyzw;
    r0.w = dot(r2.xyz, float3(0.262699991,0.677999973,0.0593000017));
    r2.xyz = r2.xyz + -r0.www;
    r2.xyz = cb0[25].xxx * r2.xyz + r0.www;
    r3.xyz = cb0[26].www * r2.xyz;
    r3.xyz = cmp(float3(0,0,0) < r3.xyz);
    r3.xyz = r3.xyz ? cb0[26].xxx : 0;
    r2.xyz = r2.xyz * cb0[26].www + r3.xyz;
    r0.w = cb0[25].y * r1.w;
    r1.w = rcp(cb0[26].y);
    r3.xyz = r2.xyz * r1.www + float3(1,1,1);
    r3.xyz = rcp(r3.xyz);
    r1.w = r0.w * r0.w;
    r4.xyz = float3(1,1,1) + -r3.xyz;
    r3.xyz = r1.www * r4.xyz + r3.xyz;
    r2.xyz = r3.xyz * r2.xyz;
    r3.xyz = cmp(r1.xyz < float3(0.00313080009,0.00313080009,0.00313080009));
    r4.xyz = float3(12.9200001,12.9200001,12.9200001) * r1.xyz;
    r1.xyz = log2(r1.xyz);
    r1.xyz = float3(0.416666657,0.416666657,0.416666657) * r1.xyz;
    r1.xyz = exp2(r1.xyz);
    r1.xyz = r1.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
    r1.xyz = r3.xyz ? r4.xyz : r1.xyz;
    r1.xyz = log2(r1.xyz);
    r1.xyz = float3(2.20000005,2.20000005,2.20000005) * r1.xyz;
    r1.xyz = exp2(r1.xyz);
    r3.x = dot(float3(0.627403915,0.329282999,0.0433131009), r1.xyz);
    r3.y = dot(float3(0.0690973029,0.919540584,0.0113623003), r1.xyz);
    r3.z = dot(float3(0.0163914002,0.0880132988,0.895595312), r1.xyz);
    r1.xyz = cb0[26].yyy * r3.xyz;                 // Adapt * overlay basis (absolute nits-ish working space)
    r1.xyz = r2.xyz * r0.www + r1.xyz;             // Add scene (absolute) * overlay alpha -> mixed working space


    r1.xyz = float3(9.99999975e-05,9.99999975e-05,9.99999975e-05) * r1.xyz;
    r1.xyz = max(float3(0,0,0), r1.xyz);
    r1.xyz = log2(r1.xyz);
    r1.xyz = float3(0.159301758,0.159301758,0.159301758) * r1.xyz;
    r1.xyz = exp2(r1.xyz);
    r2.xyzw = r1.xxyy * float4(18.8515625,18.6875,18.8515625,18.6875) + float4(0.8359375,1,0.8359375,1);
    r1.xy = rcp(r2.yw);
    r1.xy = r2.xz * r1.xy;
    r1.xy = log2(r1.xy);
    r1.xy = float2(78.84375,78.84375) * r1.xy;
    r1.xy = exp2(r1.xy);
    r1.xy = min(float2(1,1), r1.xy);
    r1.zw = r1.zz * float2(18.8515625,18.6875) + float2(0.8359375,1);

    r0.w = rcp(r1.w);
    r0.w = r1.z * r0.w;
    r0.w = log2(r0.w);
    r0.w = 78.84375 * r0.w;
    r0.w = exp2(r0.w);
    r0.w = min(1, r0.w);
    r0.z = asuint(cb1[139].z) << 3;
    r2.xyz = (int3)r0.xyz & int3(63,63,63);
    r2.w = 0;
    r0.x = t0.Load(r2.xyzw).x;
    r0.x = r0.x * 2 + -1;
    r0.y = cmp(0 < r0.x);
    r0.z = cmp(r0.x < 0);
    r0.y = (int)-r0.y + (int)r0.z;
    r0.y = (int)r0.y;
    r0.x = 1 + -abs(r0.x);
    r0.x = sqrt(r0.x);
    r0.x = 1 + -r0.x;
    r0.x = r0.y * r0.x;
    r0.yz = r1.xy * float2(2,2) + float2(-1,-1);
    r0.yz = float2(-0.998044968,-0.998044968) + abs(r0.yz);
    r0.yz = cmp(r0.yz < float2(0,0));
    r1.zw = r0.xx * float2(0.000977517106,0.000977517106) + r1.xy;
  #if 1 //SCRGB OUTPUT
  // pq->linear nits scaled bt2020->bt709
    float3 color;
    color.xy = saturate(r0.yz ? r1.zw : r1.xy);
    r0.y = r0.w * 2 + -1;
    r0.y = -0.998044968 + abs(r0.y);
    r0.y = cmp(r0.y < 0);
    r0.x = r0.x * 0.000977517106 + r0.w;
    color.z = saturate(r0.y ? r0.x : r0.w);
    color = PQ_to_Linear(color, GCT_MIRROR);
    color *= HDR10_MaxWhiteNits/sRGB_WhiteLevelNits;
    float scaling = ( LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits ) / ( GameWhiteLevelNits / sRGB_WhiteLevelNits );
    scaling *= cb0[26].w;
    color *= scaling;
    color = BT2020_To_BT709(color);
    o0 = float4(color, 1);
    return;

  #endif
    o0.xy = saturate(r0.yz ? r1.zw : r1.xy);
    r0.y = r0.w * 2 + -1;
    r0.y = -0.998044968 + abs(r0.y);
    r0.y = cmp(r0.y < 0);
    r0.x = r0.x * 0.000977517106 + r0.w;
    o0.z = saturate(r0.y ? r0.x : r0.w);
    o0.w = 1;
  } else {
    o0.xyzw = float4(0,0,0,0);
  }
  return;
}