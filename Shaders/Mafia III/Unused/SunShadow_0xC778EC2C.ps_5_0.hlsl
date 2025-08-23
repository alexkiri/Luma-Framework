Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);

SamplerComparisonState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[10];
}

#define cmp

void main(
  float4 v0 : SV_Position0,
  float2 v1 : TEXCOORD0,
  float3 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD2,
  float4 v4 : TEXCOORD3,
  float4 v5 : TEXCOORD4,
  float4 v6 : TEXCOORD5,
  out float4 o0 : SV_Target0)
{
  const float4 icb[] = { { 0, -1.000000, 0, 0},
                              { -1.000000, 0, 0, 0},
                              { 0, 0, 0, 0},
                              { 1.000000, 0, 0, 0},
                              { 0, 1.000000, 0, 0} };
  float4 r0,r1,r2,r3;
  r0.x = t1.Sample(s1_s, v1.xy).x;
  r0.yzw = v2.xyz * r0.xxx;
  r1.xyz = v2.xyz * r0.xxx + cb0[0].xyz;
  r2.xyz = v4.xyz * r1.yyy;
  r1.xyw = r1.xxx * v3.xyz + r2.xyz;
  r1.xyz = r1.zzz * v5.xyz + r1.xyw;
  r1.xyz = v6.xyz + r1.xyz;
  r0.x = dot(r0.yzw, r0.yzw);
  r0.x = saturate(r0.x * cb0[1].x + cb0[1].y);
  r0.x = r0.x * cb0[1].z + cb0[1].w;
  r0.y = dot(v0.xy, float2(1.01238,0.654898703));
  r0.y = cb0[8].y * 0.838485122 + r0.y;
  sincos(r0.y, r2.x, r3.x);
  uint r0yu = (uint)cb0[3].x;
  r0yu = r0yu >> 1;
  r0.z = cmp(0.5 < cb0[8].x);
  if (r0.z != 0) {
    r0.zw = cb0[8].zw + r1.xy;
    r1.w = v0.y * 2 + v0.x;
    r1.w += cb0[8].y;
    uint r1wu = (uint)r1.w;
    r1wu = r1wu % 5;
    r1.xy = icb[r1wu+0].xy * cb0[9].xy + r0.zw;
  }
  r3.y = r2.x;
  r0.zw = float2(0,0);
  int r0wi = 0;
  while (true) {
    bool stop = cmp((uint)r0wi >= r0yu);
    if (stop) break;
    r2.xyzw = cb0[r0wi+4].xyzw * r3.yxxy + r1.xyxy;
    r1.w = t0.SampleCmpLevelZero(s0_s, r2.xy, r1.z).x;
    r1.w += r0.z;
    r2.x = t0.SampleCmpLevelZero(s0_s, r2.zw, r1.z).x;
    r0.z = r2.x + r1.w;
    r0wi++;
  }
  o0.xyzw = r0.zz* cb0[3].y + r0.x;
}