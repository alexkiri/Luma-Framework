#include "includes/Common.hlsl"

Texture2D<float4> t2 : register(t2);

Texture2D<float4> t1 : register(t1);

Texture2D<float4> t0 : register(t0);

cbuffer cb1 : register(b1)
{
  float4 cb1[123];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[19];
}

// 3Dmigoto declarations
#define cmp -

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : SV_Position0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10;
  uint4 bitmask, uiDest;
  float4 fDest;
  float4 resolution;
  if (LumaData.GameData.DrewUpscaling){
    resolution = LumaData.GameData.OutputResolution;
  } else {
    resolution = cb1[122];
  }

  r0.xyzw = floor(v1.xyxy);
  r1.xy = (int2)r0.zw;
  r2.x = dot(r0.zw, float2(0.0671105608,0.00583714992));
  r2.x = frac(r2.x);
  r2.x = 52.9829178 * r2.x;
  r2.xz = frac(r2.xx);
  r0.xyzw = float4(32.6650009,11.8149996,0.5,0.5) + r0.xyzw;
  r0.x = dot(r0.xy, float2(0.0671105608,0.00583714992));
  r0.x = frac(r0.x);
  r0.x = 52.9829178 * r0.x;
  r2.yw = frac(r0.xx);
  r0.xy = r2.zw * float2(0.5,0.5) + float2(-0.25,-0.25);
  r3.xy = -cb1[121].xy + r0.zw;
  r0.xy = r3.xy * float2(0.0625,0.0625) + r0.xy;
  r0.xy = floor(r0.xy);
  r0.xy = (int2)r0.xy;
  r3.xy = float2(15,15) + resolution.xy;
  r3.xy = float2(0.0625,0.0625) * r3.xy;
  r3.xy = (int2)r3.xy;
  r0.xy = max(int2(0,0), (int2)r0.xy);
  r3.xy = min((int2)r0.xy, (int2)r3.xy);
  r3.zw = float2(0,0);
  r3.xyzw = t2.Load(r3.xyz).xyzw;
  r4.xyzw = cb0[18].yyyy * r3.zwzw;
  r0.x = dot(r4.zw, r4.zw);
  r1.zw = float2(0,0);
  r5.xyz = t0.Load(r1.xyw).xyz;
  r0.y = cmp(r0.x < 0.25);
  if (r0.y == 0) {
    r3.xy = cb0[18].yy * r3.xy;
    r0.y = dot(r3.xy, r3.xy);
    r3.xy = resolution.xy + cb1[121].xy;
    r3.xy = float2(-1,-1) + r3.xy;
    r3.zw = (int2)cb1[121].xy;
    r3.xy = (int2)r3.xy;
    r5.w = 0.5 * r0.x;
    r0.y = cmp(r5.w < r0.y);
    if (r0.y != 0) {
      r6.xyzw = float4(1,1,2,2) + -r2.zwzw;
      r6.xyzw = float4(0.0250000004,0.0250000004,0.0250000004,0.0250000004) * r6.xyzw;
      r7.xy = r6.xx * r4.zw + r0.zw;
      r7.xy = floor(r7.xy);
      r7.xy = (int2)r7.xy;
      r7.xy = max((int2)r7.xy, (int2)r3.zw);
      r7.xy = min((int2)r7.xy, (int2)r3.xy);
      r6.xy = -r6.yy * r4.zw + r0.zw;
      r6.xy = floor(r6.xy);
      r6.xy = (int2)r6.xy;
      r6.xy = max((int2)r6.xy, (int2)r3.zw);
      r8.xy = min((int2)r6.xy, (int2)r3.xy);
      r7.zw = float2(0,0);
      r7.xyz = t0.Load(r7.xyz).xyz;
      r8.zw = float2(0,0);
      r8.xyz = t0.Load(r8.xyz).xyz;
      r7.xyz = r8.xyz + r7.xyz;
      r6.xy = r6.zz * r4.zw + r0.zw;
      r6.xy = floor(r6.xy);
      r6.xy = (int2)r6.xy;
      r6.xy = max((int2)r6.xy, (int2)r3.zw);
      r8.xy = min((int2)r6.xy, (int2)r3.xy);
      r6.xy = -r6.ww * r4.zw + r0.zw;
      r6.xy = floor(r6.xy);
      r6.xy = (int2)r6.xy;
      r6.xy = max((int2)r6.xy, (int2)r3.zw);
      r6.xy = min((int2)r6.xy, (int2)r3.xy);
      r8.zw = float2(0,0);
      r8.xyz = t0.Load(r8.xyz).xyz;
      r7.xyz = r8.xyz + r7.xyz;
      r6.zw = float2(0,0);
      r6.xyz = t0.Load(r6.xyz).xyz;
      r6.xyz = r7.xyz + r6.xyz;
      r7.xyzw = float4(3,3,4,4) + -r2.zwzw;
      r7.xyzw = float4(0.0250000004,0.0250000004,0.0250000004,0.0250000004) * r7.xyzw;
      r8.xy = r7.xx * r4.zw + r0.zw;
      r8.xy = floor(r8.xy);
      r8.xy = (int2)r8.xy;
      r8.xy = max((int2)r8.xy, (int2)r3.zw);
      r8.xy = min((int2)r8.xy, (int2)r3.xy);
      r7.xy = -r7.yy * r4.zw + r0.zw;
      r7.xy = floor(r7.xy);
      r7.xy = (int2)r7.xy;
      r7.xy = max((int2)r7.xy, (int2)r3.zw);
      r9.xy = min((int2)r7.xy, (int2)r3.xy);
      r8.zw = float2(0,0);
      r8.xyz = t0.Load(r8.xyz).xyz;
      r6.xyz = r8.xyz + r6.xyz;
      r9.zw = float2(0,0);
      r8.xyz = t0.Load(r9.xyz).xyz;
      r6.xyz = r8.xyz + r6.xyz;
      r7.xy = r7.zz * r4.zw + r0.zw;
      r7.xy = floor(r7.xy);
      r7.xy = (int2)r7.xy;
      r7.xy = max((int2)r7.xy, (int2)r3.zw);
      r8.xy = min((int2)r7.xy, (int2)r3.xy);
      r7.xy = -r7.ww * r4.zw + r0.zw;
      r7.xy = floor(r7.xy);
      r7.xy = (int2)r7.xy;
      r7.xy = max((int2)r7.xy, (int2)r3.zw);
      r7.xy = min((int2)r7.xy, (int2)r3.xy);
      r8.zw = float2(0,0);
      r8.xyz = t0.Load(r8.xyz).xyz;
      r6.xyz = r8.xyz + r6.xyz;
      r7.zw = float2(0,0);
      r7.xyz = t0.Load(r7.xyz).xyz;
      r6.xyz = r7.xyz + r6.xyz;
      r5.xyz = float3(0.125,0.125,0.125) * r6.xyz;
    } else {
      r0.x = rsqrt(r0.x);
      r0.x = 4 * r0.x;
      r1.xy = t1.Load(r1.xyz).xy;
      r0.y = cb0[18].y * r1.x;
      r6.y = min(cb0[18].w, r0.y);
      r7.xyzw = float4(1,1,2,2) + -r2.zwzw;
      r8.xyzw = float4(0.0250000004,0.0250000004,0.0250000004,0.0250000004) * r7.xyzw;
      r1.xz = r8.xx * r4.zw + r0.zw;
      r1.xz = floor(r1.xz);
      r1.xz = (int2)r1.xz;
      r1.xz = max((int2)r1.xz, (int2)r3.zw);
      r9.xy = min((int2)r1.xz, (int2)r3.xy);
      r1.xz = -r8.yy * r4.zw + r0.zw;
      r1.xz = floor(r1.xz);
      r1.xz = (int2)r1.xz;
      r1.xz = max((int2)r1.xz, (int2)r3.zw);
      r10.xy = min((int2)r1.xz, (int2)r3.xy);
      r9.zw = float2(0,0);
      r1.xz = t1.Load(r9.xyw).xy;
      r9.xyz = t0.Load(r9.xyz).xyz;
      r0.y = cb0[18].y * r1.x;
      r6.x = min(cb0[18].w, r0.y);
      r0.y = r1.z + -r1.y;
      r1.xw = saturate(r0.yy * float2(1,-1) + float2(0.5,0.5));
      r7.yw = saturate(r6.yx * r0.xx);
      r0.y = dot(r1.xw, r7.yw);
      r10.zw = float2(0,0);
      r1.xw = t1.Load(r10.xyw).xy;
      r10.xyz = t0.Load(r10.xyz).xyz;
      r1.x = cb0[18].y * r1.x;
      r6.z = min(cb0[18].w, r1.x);
      r1.x = r1.w + -r1.y;
      r7.yw = saturate(r1.xx * float2(1,-1) + float2(0.5,0.5));
      r8.xy = saturate(r6.yz * r0.xx);
      r1.x = dot(r7.yw, r8.xy);
      r1.z = cmp(r1.w < r1.z);
      r1.w = cmp(r6.x < r6.z);
      r5.w = r1.w ? r1.z : 0;
      r5.w = r5.w ? r1.x : r0.y;
      r1.z = (int)r1.w | (int)r1.z;
      r0.y = r1.z ? r1.x : r0.y;
      r1.xzw = r0.yyy * r10.xyz;
      r1.xzw = r5.www * r9.xyz + r1.xzw;
      r0.y = r5.w + r0.y;
      r7.yw = r8.zz * r4.zw + r0.zw;
      r7.yw = floor(r7.yw);
      r7.yw = (int2)r7.yw;
      r7.yw = max((int2)r7.yw, (int2)r3.zw);
      r9.xy = min((int2)r7.yw, (int2)r3.xy);
      r7.yw = -r8.ww * r4.zw + r0.zw;
      r7.yw = floor(r7.yw);
      r7.yw = (int2)r7.yw;
      r7.yw = max((int2)r7.yw, (int2)r3.zw);
      r8.xy = min((int2)r7.yw, (int2)r3.xy);
      r9.zw = float2(0,0);
      r7.yw = t1.Load(r9.xyw).xy;
      r9.xyz = t0.Load(r9.xyz).xyz;
      r5.w = cb0[18].y * r7.y;
      r6.w = min(cb0[18].w, r5.w);
      r5.w = r7.w + -r1.y;
      r10.xy = saturate(r5.ww * float2(1,-1) + float2(0.5,0.5));
      r10.zw = saturate(r0.xx * r6.yw + -r7.xx);
      r5.w = dot(r10.xy, r10.zw);
      r8.zw = float2(0,0);
      r10.xy = t1.Load(r8.xyw).xy;
      r8.xyz = t0.Load(r8.xyz).xyz;
      r7.y = cb0[18].y * r10.x;
      r6.x = min(cb0[18].w, r7.y);
      r7.y = r10.y + -r1.y;
      r10.xz = saturate(r7.yy * float2(1,-1) + float2(0.5,0.5));
      r7.xy = saturate(r0.xx * r6.yx + -r7.xx);
      r7.x = dot(r10.xz, r7.xy);
      r7.y = cmp(r10.y < r7.w);
      r7.w = cmp(r6.w < r6.x);
      r8.w = r7.w ? r7.y : 0;
      r8.w = r8.w ? r7.x : r5.w;
      r7.y = (int)r7.w | (int)r7.y;
      r5.w = r7.y ? r7.x : r5.w;
      r1.xzw = r8.www * r9.xyz + r1.xzw;
      r1.xzw = r5.www * r8.xyz + r1.xzw;
      r0.y = r8.w + r0.y;
      r0.y = r0.y + r5.w;
      r2.xyzw = float4(3,3,4,4) + -r2.xyzw;
      r8.xyzw = float4(0.0250000004,0.0250000004,0.0250000004,0.0250000004) * r2.xyzw;
      r2.yz = r8.xx * r4.zw + r0.zw;
      r2.yz = floor(r2.yz);
      r2.yz = (int2)r2.yz;
      r2.yz = max((int2)r2.yz, (int2)r3.zw);
      r9.xy = min((int2)r2.yz, (int2)r3.xy);
      r2.yz = -r8.yy * r4.zw + r0.zw;
      r2.yz = floor(r2.yz);
      r2.yz = (int2)r2.yz;
      r2.yz = max((int2)r2.yz, (int2)r3.zw);
      r10.xy = min((int2)r2.yz, (int2)r3.xy);
      r9.zw = float2(0,0);
      r2.yz = t1.Load(r9.xyw).xy;
      r7.xyw = t0.Load(r9.xyz).xyz;
      r2.y = cb0[18].y * r2.y;
      r6.z = min(cb0[18].w, r2.y);
      r2.y = r2.z + -r1.y;
      r2.yw = saturate(r2.yy * float2(1,-1) + float2(0.5,0.5));
      r8.xy = saturate(r0.xx * r6.yz + -r7.zz);
      r2.y = dot(r2.yw, r8.xy);
      r10.zw = float2(0,0);
      r8.xy = t1.Load(r10.xyw).xy;
      r9.xyz = t0.Load(r10.xyz).xyz;
      r2.w = cb0[18].y * r8.x;
      r6.w = min(cb0[18].w, r2.w);
      r2.w = r8.y + -r1.y;
      r10.xy = saturate(r2.ww * float2(1,-1) + float2(0.5,0.5));
      r10.zw = saturate(r0.xx * r6.yw + -r7.zz);
      r2.w = dot(r10.xy, r10.zw);
      r2.z = cmp(r8.y < r2.z);
      r5.w = cmp(r6.z < r6.w);
      r6.w = r2.z ? r5.w : 0;
      r6.w = r6.w ? r2.w : r2.y;
      r2.z = (int)r2.z | (int)r5.w;
      r2.y = r2.z ? r2.w : r2.y;
      r1.xzw = r6.www * r7.xyw + r1.xzw;
      r1.xzw = r2.yyy * r9.xyz + r1.xzw;
      r0.y = r6.w + r0.y;
      r0.y = r0.y + r2.y;
      r2.yz = r8.zz * r4.xy + r0.zw;
      r2.yz = floor(r2.yz);
      r2.yz = (int2)r2.yz;
      r2.yz = max((int2)r2.yz, (int2)r3.zw);
      r7.xy = min((int2)r2.yz, (int2)r3.xy);
      r0.zw = -r8.ww * r4.zw + r0.zw;
      r0.zw = floor(r0.zw);
      r0.zw = (int2)r0.zw;
      r0.zw = max((int2)r0.zw, (int2)r3.zw);
      r3.xy = min((int2)r0.zw, (int2)r3.xy);
      r7.zw = float2(0,0);
      r0.zw = t1.Load(r7.xyw).xy;
      r2.yzw = t0.Load(r7.xyz).xyz;
      r0.z = cb0[18].y * r0.z;
      r6.x = min(cb0[18].w, r0.z);
      r0.z = r0.w + -r1.y;
      r4.xy = saturate(r0.zz * float2(1,-1) + float2(0.5,0.5));
      r4.zw = saturate(r0.xx * r6.yx + -r2.xx);
      r0.z = dot(r4.xy, r4.zw);
      r3.zw = float2(0,0);
      r4.xy = t1.Load(r3.xyw).xy;
      r3.xyz = t0.Load(r3.xyz).xyz;
      r3.w = cb0[18].y * r4.x;
      r6.z = min(cb0[18].w, r3.w);
      r1.y = r4.y + -r1.y;
      r4.xz = saturate(r1.yy * float2(1,-1) + float2(0.5,0.5));
      r6.yw = saturate(r0.xx * r6.yz + -r2.xx);
      r0.x = dot(r4.xz, r6.yw);
      r0.w = cmp(r4.y < r0.w);
      r1.y = cmp(r6.x < r6.z);
      r2.x = r0.w ? r1.y : 0;
      r2.x = r2.x ? r0.x : r0.z;
      r0.w = (int)r0.w | (int)r1.y;
      r0.x = r0.w ? r0.x : r0.z;
      r1.xyz = r2.xxx * r2.yzw + r1.xzw;
      r1.xyz = r0.xxx * r3.xyz + r1.xyz;
      r0.y = r2.x + r0.y;
      r0.x = r0.y + r0.x;
      r0.x = -r0.x * 0.125 + 1;
      r0.x = max(0, r0.x);
      r0.yzw = float3(0.125,0.125,0.125) * r1.xyz;
      r5.xyz = r0.xxx * r5.xyz + r0.yzw;
    }
  }
  o0.xyz = r5.xyz;
  o0.w = 0;
  return;
}