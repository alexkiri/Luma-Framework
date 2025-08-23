Texture2D<float4> t4 : register(t4);
Texture2D<float4> t3 : register(t3);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s2_s : register(s2);
SamplerComparisonState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb2 : register(b2)
{
  float4 cb2[29];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[1];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[25];
}

#define cmp -

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0,
  out float4 o1 : SV_Target1,
  out float4 o2 : SV_Target2)
{
  const float4 icb[] = { { 0, -1.000000, 0, 0},
                              { -1.000000, 0, 0, 0},
                              { 0, 0, 0, 0},
                              { 1.000000, 0, 0, 0},
                              { 0, 1.000000, 0, 0} };
  float4 r0,r1,r2,r3,r4,r5,r6,r7;
  r0.x = cmp(0.000000 != cb2[2].x);
  if (r0.x != 0) {
    r0.x = v1.w;
    r0.y = v2.x;
    r0.x = t3.SampleLevel(s0_s, r0.xy, 0).x;
    r0.xyz = v2.yzw * r0.xxx + cb2[0].xyz;
  } else {
    r1.xy = trunc(v0.xy);
    r2.x = v1.w * 2 + -1;
    r2.y = v2.x * -2 + 1;
    r2.xy = -cb2[6].xy + r2.xy;
    r1.xy = (int2)r1.xy;
    r1.zw = float2(0,0);
    r2.z = t3.Load(r1.xyz).x;
    r2.w = 1;
    r0.x = dot(cb2[26].xyzw, r2.xyzw);
    r0.y = dot(cb2[27].xyzw, r2.xyzw);
    r0.z = dot(cb2[28].xyzw, r2.xyzw);
  }
  r0.w = 1;
  r1.x = dot(cb0[4].xyzw, r0.xyzw);
  r1.y = dot(cb0[5].xyzw, r0.xyzw);
  r1.z = dot(cb0[6].xyzw, r0.xyzw);
  r1.w = dot(cb0[7].xyzw, r0.xyzw);
  r1.xyw = r1.xyz / r1.www;
  r2.xyz = -r0.xyz * cb0[14].zzz + cb0[13].xyz;
  r2.w = dot(r2.xyz, r2.xyz);
  r2.w = sqrt(r2.w);
  r3.x = cmp(cb0[14].w == 3.000000);
  r3.x = r3.x ? 1 : r1.z;
  r3.y = 1 + -cb0[14].z;
  r3.x = r3.x * r3.y;
  r3.x = r2.w * cb0[14].z + r3.x;
  r4.x = dot(cb0[22].xyzw, r0.xyzw);
  r4.y = dot(cb0[23].xyzw, r0.xyzw);
  r4.z = dot(cb0[24].xyzw, r0.xyzw);
  r0.x = cmp(0 < cb0[14].y);
  if (r0.x != 0) {
    r0.x = dot(v0.xy, float2(1.01238,0.654898703));
    r0.x = cb0[1].y * 0.838485122 + r0.x;
    sincos(r0.x, r0.x, r5.x);
    r0.y = (uint)cb0[3].x;
    r0.y = (uint)r0.y >> 1;
    r0.z = cmp(0.5 < cb0[1].x);
    if (r0.z != 0) {
      r0.zw = cb0[1].zw + r1.xy;
      r3.y = v0.y * 2 + v0.x;
      r3.y = cb0[1].y + r3.y;
      r3.y = (uint)r3.y;
      r3.y = (uint)r3.y % 5;
      r0.zw = icb[r3.y+0].xy * cb0[2].xy + r0.zw;
    } else {
      r0.zw = r1.xy;
    }
    r5.y = r0.x;
    r0.x = 0;
    r3.y = 0;
    while (true) {
      r3.z = cmp(asint(r3.y) >= asint(r0.y)); // TODO: crashes? Meant to be asuint but that crashes?
      if (r3.z != 0) break;
      r6.xyzw = cb0[r3.y+8].xyzw * r5.yxxy + r0.zwzw;
      r3.z = t1.SampleCmpLevelZero(s1_s, r6.xy, r1.w).x;
      r3.z = r3.z + r0.x;
      r3.w = t1.SampleCmpLevelZero(s1_s, r6.zw, r1.w).x;
      r0.x = r3.z + r3.w;
      r3.y = asfloat(asint(r3.y) + 1);
    }
    r0.x = r0.x * cb0[3].y + cb0[15].x;
  } else {
    r0.x = 1;
  }
  r0.x = saturate(r0.x);
  r0.y = cmp(r1.z >= 0);
  r0.y = r0.y ? 1.000000 : 0;
  r0.z = cmp(cb0[20].x == 0.000000);
  if (r0.z != 0) {
    r0.z = -r3.x * cb0[12].w + 1;
    r0.z = max(9.99999975e-006, r0.z);
    r0.z = min(1, r0.z);
    r0.z = log2(r0.z);
    r0.z = cb0[20].w * r0.z;
    r0.z = exp2(r0.z);
    r0.w = cmp(cb0[13].w >= r3.x);
    r0.w = r0.w ? 1.000000 : 0;
    r0.z = r0.z * r0.w;
  } else {
    r0.w = r3.x * r3.x;
    r0.w = max(9.99999975e-006, r0.w);
    r0.w = 1 / r0.w;
    r0.w = -cb0[20].z + r0.w;
    r0.w = max(0, r0.w);
    r0.z = min(cb0[20].y, r0.w);
  }
  r3.xyz = cb0[12].xyz * r0.zzz;
  r5.xyz = r4.xyz * cb0[16].xyz + cb0[17].xyz;
  r4.xyz = r4.xyz * cb0[18].xyz + cb0[19].xyz;
  r4.xyz = saturate(min(r5.xyz, r4.xyz));
  r3.xyz = r4.xxx * r3.xyz;
  r3.xyz = r3.xyz * r4.yyy;
  r3.xyz = r3.xyz * r4.zzz;
  r0.yzw = r3.xyz * r0.yyy;
  r1.xyz = t0.Sample(s2_s, r1.xy).xyz;
  r0.yzw = r1.xyz * r0.yzw;
  r0.xyz = r0.yzw * r0.xxx;
  r0.w = dot(r0.xyz, float3(1,1,1));
  r0.w = cmp(r0.w != 0.000000);
  if (r0.w != 0) {
    r1.xy = (int2)v0.xy;
    r1.zw = float2(0,0);
    r3.xyzw = t4.Load(r1.xyw).xyzw;
    r1.xyzw = t2.Load(r1.xyz).xyzw;
    r1.xyz = r1.xyz * float3(2,2,2) + float3(-1,-1,-1);
    r0.w = dot(r1.xyz, r1.xyz);
    r4.x = cmp(r0.w >= 9.99999975e-005);
    r4.y = r4.x ? 1.000000 : 0;
    r0.w = rsqrt(r0.w);
    r1.xyz = r1.xyz * r0.www;
    r0.w = dot(-v2.yzw, -v2.yzw);
    r0.w = rsqrt(r0.w);
    r5.xyz = -v2.yzw * r0.www;
    r6.xyz = r2.xyz / r2.www;
    r2.w = r3.w * 255 + 0.5;
    r2.w = (uint)r2.w;
    if (1 == 0) r4.z = 0; else if (1+5 < 32) {     r4.z = (uint)r2.w << (32-(1 + 5)); r4.z = (uint)r4.z >> (32-1);    } else r4.z = (uint)r2.w >> 5;
    if (1 == 0) r4.w = 0; else if (1+7 < 32) {     r4.w = (uint)r2.w << (32-(1 + 7)); r4.w = (uint)r4.w >> (32-1);    } else r4.w = (uint)r2.w >> 7;
    r3.w = r4.z ? 0 : 1;
    r2.w = (int)r2.w & 7;
    r2.w = (uint)r2.w;
    r2.w = 0.142857149 * r2.w;
    r2.w = r4.w ? 0 : r2.w;
    r4.z = 1.00010002 + -r2.w;
    r4.z = min(1, r4.z);
    r7.xyz = r4.zzz * r3.xyz;
    r4.z = dot(r1.xyz, r6.xyz);
    r4.x = r4.x ? -1 : -0;
    r4.x = r4.z * r4.y + r4.x;
    r4.x = saturate(1 + r4.x);
    r4.x = log2(r4.x);
    r4.x = cb0[21].w * r4.x;
    r4.x = exp2(r4.x);
    r4.x = min(1, r4.x);
    r4.x = max(cb0[14].x, r4.x);
    r4.xzw = r4.xxx * r0.xyz;
    r6.xyz = r7.xyz * r4.xzw;
    o0.xyz = r6.xyz * r3.www;
    r4.x = dot(r4.xzw, float3(0.212500006,0.715399981,0.0720999986));
    r4.x = 9.99999975e-006 + r4.x;
    o1.xyzw = r4.xxxx * r3.wwww;
    r4.x = dot(r5.xyz, r1.xyz);
    r4.z = r4.x + r4.x;
    r5.xyz = r1.xyz * -r4.zzz + r5.xyz;
    r4.z = dot(r2.xyz, -r5.xyz);
    r5.xyz = r4.zzz * -r5.xyz + -r2.xyz;
    r4.z = dot(r5.xyz, r5.xyz);
    r4.z = sqrt(r4.z);
    r4.z = max(9.99999975e-006, r4.z);
    r4.z = saturate(cb0[15].w / r4.z);
    r2.xyz = r5.xyz * r4.zzz + r2.xyz;
    r4.z = dot(r2.xyz, r2.xyz);
    r4.z = sqrt(r4.z);
    r4.z = max(9.99999975e-006, r4.z);
    r2.xyz = r2.xyz / r4.zzz;
    r4.w = dot(r2.xyz, r1.xyz);
    r5.x = cmp(r4.w >= 0);
    r5.x = r5.x ? 1 : -1;
    r5.yzw = -v2.yzw * r0.www + r2.xyz;
    r0.w = dot(r5.yzw, r5.yzw);
    r0.w = rsqrt(r0.w);
    r5.yzw = r5.yzw * r0.www;
    r5.xyz = r5.xxx * r5.yzw;
    r0.w = saturate(dot(r1.xyz, r5.xyz));
    r1.x = saturate(dot(r5.xyz, r2.xyz));
    r1.y = r4.w * r4.w;
    r1.y = min(1, r1.y);
    r1.y = 1 + -r1.y;
    r1.y = sqrt(r1.y);
    r1.z = max(9.99999975e-006, r4.w);
    r1.y = r1.y / r1.z;
    r4.xw = saturate(r4.xw);
    r2.x = -r4.x * r4.x + 1;
    r2.x = sqrt(r2.x);
    r2.y = max(9.99999975e-006, r4.x);
    r2.x = r2.x / r2.y;
    r3.xyz = float3(-0.0399999991,-0.0399999991,-0.0399999991) + r3.xyz;
    r3.xyz = r2.www * r3.xyz + float3(0.0399999991,0.0399999991,0.0399999991);
    r5.xyz = float3(1,1,1) + -r3.xyz;
    r1.x = 1 + -r1.x;
    r2.z = r1.x * r1.x;
    r2.z = r2.z * r2.z;
    r1.xz = r2.zy * r1.xz;
    r3.xyz = r5.xyz * r1.xxx + r3.xyz;
    r1.x = max(0.00999999978, cb1[0].x);
    r1.x = 255 / r1.x;
    r1.x = saturate(r1.x * r1.w);
    r2.z = cb0[21].z * r4.y;
    r1.x = r2.z * r1.x;
    r1.w = 16 * r1.w;
    r1.w = exp2(r1.w);
    r1.w = min(65535, r1.w);
    r2.z = r1.w * 0.5 + 1;
    r2.z = sqrt(r2.z);
    r2.w = 1 / r2.z;
    r4.x = r4.z + r4.z;
    r4.x = cb0[15].w / r4.x;
    r2.w = saturate(r4.x + r2.w);
    r2.w = r2.w * r2.w;
    r2.w = 2 / r2.w;
    r0.w = log2(r0.w);
    r0.w = r1.w * r0.w;
    r0.w = exp2(r0.w);
    r0.w = r2.w * r0.w;
    r0.w = 0.125 * r0.w;
    r1.y = r2.z / r1.y;
    r1.w = r1.y * r1.y;
    r2.x = r2.z / r2.x;
    r2.z = r2.x * r2.x;
    r2.w = cmp(r1.y >= 1.60000002);
    r4.x = 2.18099999 * r1.w;
    r4.x = r1.y * 3.53500009 + r4.x;
    r1.y = r1.y * 2.27600002 + 1;
    r1.y = r1.w * 2.5769999 + r1.y;
    r1.y = r4.x / r1.y;
    r1.y = r2.w ? 1 : r1.y;
    r1.w = cmp(r2.x >= 1.60000002);
    r2.w = 2.18099999 * r2.z;
    r2.w = r2.x * 3.53500009 + r2.w;
    r2.x = r2.x * 2.27600002 + 1;
    r2.x = r2.z * 2.5769999 + r2.x;
    r2.x = r2.w / r2.x;
    r1.w = r1.w ? 1 : r2.x;
    r1.y = r1.y * r1.w;
    r1.y = min(1, r1.y);
    r1.y = r4.w * r1.y;
    r0.w = r1.y * r0.w;
    r0.w = r0.w / r1.z;
    r1.yzw = r0.www * r3.xyz;
    r0.xyz = r1.yzw * r0.xyz;
    r0.xyz = r1.xxx * r0.xyz;
    o2.xyz = r0.xyz * r3.www;
    o0.w = 1;
    o2.w = 1;
  } else {
    o0.xyzw = float4(0,0,0,0);
    o1.xyzw = float4(0,0,0,0);
    o2.xyzw = float4(0,0,0,0);
  }
  return;
}