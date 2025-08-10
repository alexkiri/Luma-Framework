#include "../Includes/Common.hlsl"

Texture2D<float4> t6 : register(t6);
Texture2D<float4> t5 : register(t5);
Texture2D<float4> t4 : register(t4);
Texture2D<float4> t3 : register(t3);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s6_s : register(s6);
SamplerState s5_s : register(s5);
SamplerState s4_s : register(s4);
SamplerState s3_s : register(s3);
SamplerState s2_s : register(s2);
SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb2 : register(b2)
{
  float4 cb2[2];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[8];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[24];
}

#define cmp -

// Used by characters meat blob at the end of the game, and possibly more
void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float3 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD2,
  float3 v4 : TEXCOORD3,
  float4 v5 : TEXCOORD4,
  float3 v6 : TEXCOORD5,
  float4 v7 : TEXCOORD6,
  float4 v8 : TEXCOORD7,
  float4 v9 : TEXCOORD8,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9;
  r0.xy = v1.xy / v1.w;
  r1.xyzw = t0.SampleLevel(s6_s, r0.xy, 0).xyzw;
  r1.xyz = float3(1,1,1) + -r1.xyz;
  r2.xyz = cb0[3].xyz * r1.xyz;
  r0.zw = r2.xx + r2.yz;
  r0.z = r1.z * cb0[3].z + r0.z;
  r0.w = r2.y * r0.w;
  r0.w = sqrt(r0.w);
  r0.w = dot(cb0[3].ww, r0.ww);
  r2.w = r0.z + r0.w;
  r0.zw = v3.xy + r0.xy;
  r3.xyzw = t1.SampleLevel(s5_s, r0.zw, 0).xyzw;
  r4.xyzw = t2.Sample(s4_s, v2.xy).xyzw;
  r0.zw = cb1[1].xx + v1.xy;
  r3.yz = float2(5.39870024,5.44210005) * r0.zw;
  r3.yz = frac(r3.yz);
  r5.xy = float2(21.5351009,14.3136997) + r3.yz;
  r1.w = dot(r3.zy, r5.xy);
  r3.yz = r3.yz + r1.ww;
  r1.w = r3.y * r3.z;
  r3.yz = float2(95.4307022,97.5901031) * r1.ww;
  r3.yz = frac(r3.yz);
  r3.yz = float2(6.28318548,0.25) * r3.yz;
  sincos(r3.y, r5.x, r6.x);
  r7.x = v8.w * r5.x;
  r7.z = v8.w * r6.x;
  r7.w = -r5.x;
  r7.y = r6.x;
  r5.xyzw = r7.xyzw / v1.w;
  r5.xyzw = float4(0.100000001,0.100000001,0.100000001,0.100000001) * r5.xyzw;
  r1.w = r4.z * 0.5 + 0.5;
  r6.xyzw = r5.xyzw * r1.w;
  r3.yw = r6.xy * float2(0.25,0.25) + r0.xy;
  r3.yw = v3.zw + r3.yw;
  r3.yw = -r3.zz * v3.zw + r3.yw;
  r7.xyzw = t1.SampleLevel(s5_s, r3.yw, 0).xyzw;
  r4.w = cmp(r7.x < v8.x);
#if 1 // Luma: added default initilalization of variable given that depending on the branches below, it have not been assigned
  r8 = float4(0, 0, 0, 1);
  r9 = float4(0, 0, 0, 1);
#endif
  if (r4.w != 0) {
    r4.w = cmp(v8.z < r7.x);
    r4.w = r4.w ? 0.75 : 1;
    r5.x = 0;
  } else {
    r5.y = cmp(r7.x < v8.y);
    if (r5.y != 0) {
      r8.xyzw = t0.SampleLevel(s6_s, r3.yw, 0).xyzw;
      r5.x = cmp(r8.w == 0.333333);
      r8.w = 1;
    } else {
      r5.x = 0;
    }
    r4.w = 1;
  }
#if 1
  r7.xyzw = asfloat(asint(r8) & asint(r5.x));
#else
  r7.xyzw = (int4)r8.xyzw & (int4)r5.xxxx;
#endif
  r3.yw = -r6.xy * float2(0.5,0.5) + r0.xy;
  r3.yw = v3.zw * float2(0.75,0.75) + r3.yw;
  r3.yw = -r3.zz * v3.zw + r3.yw;
  r8.xyzw = t1.SampleLevel(s5_s, r3.yw, 0).xyzw;
  r5.x = cmp(r8.x < v8.x);
  if (r5.x != 0) {
    r5.x = cmp(v8.z < r8.x);
    r5.y = -0.25 + r4.w;
    r4.w = r5.x ? r5.y : r4.w;
    r5.x = 0;
  } else {
    r5.y = cmp(r8.x < v8.y);
    if (r5.y != 0) {
      r9.xyzw = t0.SampleLevel(s6_s, r3.yw, 0).xyzw;
      r5.x = cmp(r9.w == 0.333333);
      r9.w = 1;
    } else {
      r5.x = 0;
    }
  }
#if 1
  r8.xyzw = asfloat(asint(r9) & asint(r5.x));
#else
  r8.xyzw = (int4)r9.xyzw & (int4)r5.xxxx;
#endif
  r7.xyzw = r8.xyzw + r7.xyzw;
  r3.yw = r6.zw * float2(0.75,0.75) + r0.xy;
  r3.yw = v3.zw * float2(0.5,0.5) + r3.yw;
  r3.yw = -r3.zz * v3.zw + r3.yw;
  r6.xyzw = t1.SampleLevel(s5_s, r3.yw, 0).xyzw;
  r5.x = cmp(r6.x < v8.x);
  if (r5.x != 0) {
    r5.x = cmp(v8.z < r6.x);
    r5.y = -0.25 + r4.w;
    r4.w = r5.x ? r5.y : r4.w;
    r5.x = 0;
  } else {
    r5.y = cmp(r6.x < v8.y);
    if (r5.y != 0) {
      r8.xyzw = t0.SampleLevel(s6_s, r3.yw, 0).xyzw;
      r5.x = cmp(r8.w == 0.333333);
      r8.w = 1;
    } else {
      r5.x = 0;
    }
  }
#if 1
  r6.xyzw = asfloat(asint(r8) & asint(r5.x));
#else
  r6.xyzw = (int4)r8.xyzw & (int4)r5.xxxx;
#endif
  r6.xyzw = r7.xyzw + r6.xyzw;
  r0.xy = -r5.zw * r1.ww + r0.xy;
  r0.xy = v3.zw * float2(0.25,0.25) + r0.xy;
  r0.xy = -r3.zz * v3.zw + r0.xy;
  r5.xyzw = t1.SampleLevel(s5_s, r0.xy, 0).xyzw;
  r1.w = cmp(r5.x < v8.x);
  if (r1.w != 0) {
    r1.w = cmp(v8.z < r5.x);
    r3.y = -0.25 + r4.w;
    r4.w = r1.w ? r3.y : r4.w;
    r1.w = 0;
  } else {
    r3.y = cmp(r5.x < v8.y);
    if (r3.y != 0) {
      r7.xyzw = t0.SampleLevel(s6_s, r0.xy, 0).xyzw;
      r1.w = cmp(r7.w == 0.333333);
      r7.w = 1;
    } else {
      r1.w = 0;
    }
  }
#if 1
  r5.xyzw = asfloat(asint(r7) & asint(r1.w));
#else
  r5.xyzw = (int4)r7.xyzw & (int4)r1.wwww;
#endif
  r5.xyzw = r6.xyzw + r5.xyzw;
  r0.x = cmp(r5.w == 0.000000);
  r3.yzw = r5.xyz / -r5.www;
  r3.yzw = float3(1,1,1) + r3.yzw;
  r3.yzw = log2(r3.yzw);
  r3.yzw = float3(0.75,0.75,0.75) * r3.yzw;
  r3.yzw = exp2(r3.yzw);
  r3.yzw = r0.xxx ? float3(0,0,0) : r3.yzw;
  r5.xyz = cb0[3].xyz * r3.yzw;
  r0.xy = r5.xx + r5.yz;
  r0.x = r3.w * cb0[3].z + r0.x;
  r0.y = r5.y * r0.y;
  r0.y = sqrt(r0.y);
  r0.y = dot(cb0[3].ww, r0.yy);
  r0.x = r0.x + r0.y;
  r0.y = r0.x * 0.5 + 0.5;
  r5.xyz = r0.xxx + -r3.yzw;
  r3.yzw = r0.yyy * r5.xyz + r3.yzw;
  r0.x = r2.w * 0.5 + 0.5;
  r5.xyz = r2.www + -r1.xyz;
  r2.xyz = r0.xxx * r5.xyz + r1.xyz;
  r0.x = dot(v4.xyz, v4.xyz);
  r0.x = rsqrt(r0.x);
  r1.xyz = v4.xyz * r0.xxx;
  r0.x = dot(v5.xyz, v5.xyz);
  r0.x = rsqrt(r0.x);
  r5.xyz = v5.xyz * r0.xxx;
  r0.x = saturate(dot(r5.xyz, r1.xyz));
  r0.x = r0.x * cb0[13].x + 1;
  r0.x = -cb0[13].x + r0.x;
  r5.xyzw = float4(1,1,1,1) + -r2.xyzw;
  r5.xyzw = r0.xxxx * r5.xyzw + r2.xyzw;
  r2.xyzw = r2.xyzw / r5.xyzw;
  r5.xyz = float3(1,1,1) + -r3.yzw;
  r5.xyz = r0.xxx * r5.xyz + r3.yzw;
  r3.yzw = r3.yzw / r5.xyz;
  r0.x = saturate(1 + -cb0[22].x);
  r0.y = r0.x * r0.x;
  r0.x = r0.x * 0.75 + 0.25;
  r5.xyzw = r2.xyzw * r2.xyzw;
  r5.xyzw = r5.xyzw * r2.xyzw;
  r6.xyzw = r2.xyzw * float4(6,6,6,6) + float4(-15,-15,-15,-15);
  r6.xyzw = r2.xyzw * r6.xyzw + float4(10,10,10,10);
  r7.xyzw = r6.xyzw * r5.xyzw;
  r2.xyzw = -r5.xyzw * r6.xyzw + r2.xyzw;
  r2.xyzw = r0.yyyy * r2.xyzw + r7.xyzw;
#if 0 // Luma: fixed NaNs
  r2 = pow(abs(r2), r0.x) * sign(r2);
#elif 1 // Luma: fixed NaNs (simpler way) (these changes seem to raise blacks in HDR, but in reality it ends up looking like SDR)
  r2 = pow(max(r2, 0.0), r0.x);
#else
  r2 = pow(r2, r0.x);
#endif
  //o0.xyzw = r2; return; // Test
  r5.xyz = r3.yzw * r3.yzw;
  r5.xyz = r5.xyz * r3.yzw;
  r6.xyz = r3.yzw * float3(6,6,6) + float3(-15,-15,-15);
  r6.xyz = r3.yzw * r6.xyz + float3(10,10,10);
  r7.xyz = r6.xyz * r5.xyz;
  r3.yzw = -r5.xyz * r6.xyz + r3.yzw;
  r3.yzw = r0.yyy * r3.yzw + r7.xyz;
  r3.yzw = log2(r3.yzw);
  r3.yzw = r3.yzw * r0.xxx;
  r3.yzw = exp2(r3.yzw);
  r3.yzw = cb0[16].xyz * r3.yzw;
  r3.yzw = max(r3.yzw, r2.xyz);
  r5.xyz = cb0[12].xyz * r3.yzw;
  r0.x = r4.w * r4.x;
  r0.x = r0.x * cb0[15].x + 1;
  r0.x = -cb0[15].x + r0.x;
  r0.x = v5.w * r0.x;
  r6.xyz = cb0[23].xyz * cb0[14].xyz;
  r6.xyz = r6.xyz + r6.xyz;
  r6.xyz = r6.xyz * r0.xxx;
  r3.yzw = -r3.yzw * cb0[12].xyz + float3(1,1,1);
  r3.yzw = r6.xyz * r3.yzw + r5.xyz;
  r5.xyzw = t3.Sample(s2_s, v2.xy).xyzw;
  r6.xyzw = t4.Sample(s3_s, v2.xy).xyzw;
  r0.y = v9.z + -r5.w;
  r0.y = saturate(4 * r0.y);
  r1.w = r0.y * -2 + 3;
  r0.y = r0.y * r0.y;
  r4.x = r1.w * r0.y;
  r4.w = v9.w + -r6.w;
  r4.w = saturate(r4.w + r4.w);
  r5.w = r4.w * -2 + 3;
  r4.w = r4.w * r4.w;
  r6.w = r5.w * r4.w;
  r7.xyzw = t5.Sample(s0_s, v2.xy).xyzw;
  r7.xyz = r7.xyz * r4.zzz + float3(1,1,1);
  r7.xyz = r7.xyz + -r4.zzz;
  r3.yzw = r7.xyz * r3.yzw;
  r5.xyz = r5.xyz * v9.xxx + float3(1,1,1);
  r5.xyz = -v9.xxx + r5.xyz;
  r3.yzw = r5.xyz * r3.yzw;
  r5.xyz = r4.xxx * float3(0.5,0.25,0.300000012) + float3(1,1,1);
  r5.xyz = -r1.www * r0.yyy + r5.xyz;
  r3.yzw = r5.xyz * r3.yzw;
  r5.xyz = r6.xyz * r6.www + float3(1,1,1);
  r4.xzw = -r5.www * r4.www + r5.xyz;
  r0.y = cb1[7].z * r3.x + cb1[7].w;
  r0.y = 1 / r0.y;
  r1.w = -cb0[6].x + r0.y;
  r1.w = r1.w * cb2[1].z + 1;
  r1.w = 1 + -r1.w;
  r1.w = max(0, r1.w);
  r1.w = min(cb2[0].w, r1.w);
  r0.y = -v1.z + r0.y;
  r0.y = saturate(r0.y * 10 + -0.5);
  r3.x = r0.y * r0.y;
  r0.y = r0.y * -2 + 3;
  r0.y = r3.x * r0.y;
  r0.y = r0.y * r0.x;
  r5.xyzw = r0.yyyy * r2.xyzw;
  r5.xyzw = float4(0.25,0.25,0.25,0.100000001) * r5.xyzw;
  r2.xyz = r3.yzw * r4.xzw + r5.xyz;
  r3.x = saturate(v5.y);
  r0.y = r3.x * r0.y;
  r0.y = r0.y * r1.w;
  r2.xyz = r0.yyy * cb2[0].xyz + r2.xyz;
  r3.xyzw = t6.Sample(s1_s, v2.xy).xyzw;
  r3.xy = r3.wx * float2(3,3) + float2(-1.5,-1.5);
  r6.x = dot(v7.xy, r3.xy);
  r6.y = dot(v7.zw, r3.xy);
  r3.xy = v5.xy + r6.xy;
  r0.y = dot(v6.xyz, v6.xyz);
  r0.y = rsqrt(r0.y);
  r4.xzw = v6.xyz * r0.yyy;
  r3.z = v5.z;
  r0.y = dot(r3.xyz, r3.xyz);
  r0.y = rsqrt(r0.y);
  r3.xyz = r3.xyz * r0.yyy;
  r0.y = dot(r4.xzw, r3.xyz);
  r0.y = r0.y + r0.y;
  r3.xyz = r3.xyz * -r0.yyy + r4.xzw;
  r0.y = dot(r3.xyz, r3.xyz);
  r0.y = rsqrt(r0.y);
  r3.xyz = r3.xyz * r0.yyy;
  r0.y = dot(-r3.xyz, r1.xyz);
  r0.y = max(0, r0.y);
  r1.x = cb0[17].x * cb0[17].x;
  r1.x = r1.x * 56 + 8;
  r0.y = log2(r0.y);
  r0.y = r1.x * r0.y;
  r0.y = exp2(r0.y);
  r0.x = r0.y * r0.x;
  r0.x = r0.x * r4.y;
  r0.y = sqrt(cb0[17].x);
  r0.x = r0.x * r0.y;
  r0.y = r0.x * r0.x;
  r0.y = r0.y * r0.x;
  r1.x = r0.x * 6 + -15;
  r0.x = r0.x * r1.x + 10;
  r0.x = r0.y * r0.x;
  r0.x = r0.x * r2.w;
  r0.y = r2.w * -0.5 + 1;
  r1.xyz = r0.xxx * r0.yyy + r2.xyz;
  r0.x = max(0, v2.z);
  r0.x = min(cb2[0].w, r0.x);
  r2.xyz = cb2[0].xyz + -r1.xyz;
  r5.xyz = r0.xxx * r2.xyz + r1.xyz;
  r0.xy = float2(0.513499975,0.513499975) + r0.zw;
  r0.xy = float2(5.39870024,5.44210005) * r0.xy;
  r0.xy = frac(r0.xy);
  r0.zw = float2(21.5351009,14.3136997) + r0.xy;
  r0.z = dot(r0.yx, r0.zw);
  r0.xy = r0.xy + r0.zz;
  r0.x = r0.x * r0.y;
  r0.xyzw = float4(95.4307022,97.5901031,93.8368988,91.6931) * r0.xxxx;
  r0.xyzw = frac(r0.xyzw);
  o0.xyzw = -r0.xyzw * float4(0.000977517106,0.000977517106,0.000977517106,0.000977517106) + r5.xyzw;
#if 1 // Fix NaNs at the end, as in SDR they would have been turned to 0 after blending, so we pre-turn them to zero. If we actually fix the NaNs generation in this shader (sqrt/log/divisions), we end up raising the shadow. Note that now we also filter them in the TAA pass.
  if (IsNaN_Strict(o0.x))
    o0.x = 0.0;
  if (IsNaN_Strict(o0.y))
    o0.y = 0.0;
  if (IsNaN_Strict(o0.z))
    o0.z = 0.0;
  if (IsNaN_Strict(o0.w))
    o0.w = 0.0;
#endif
}