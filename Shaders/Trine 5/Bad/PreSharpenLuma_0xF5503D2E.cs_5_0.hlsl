// ---- Created with 3Dmigoto v1.3.16 on Tue Jan 28 05:26:29 2025
groupshared struct { float val[1]; } g1[400];
groupshared struct { float val[3]; } g0[400];
Texture2D<unorm4> t4 : register(t4);

Texture2D<snorm4> t3 : register(t3);

Texture2D<float4> t2 : register(t2);

Texture2D<snorm4> t1 : register(t1);

Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);

cbuffer cb0 : register(b0)
{
  float4 cb0[10];
}




// 3Dmigoto declarations
#define cmp -


void main)
{
// Needs manual fix for instruction:
// unknown dcl_: dcl_uav_typed_texture2d (unorm,unorm,unorm,unorm) u0
// Needs manual fix for instruction:
// unknown dcl_: dcl_uav_typed_texture2d (snorm,snorm,snorm,snorm) u1
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11;
  uint4 bitmask, uiDest;
  float4 fDest;

// Needs manual fix for instruction:
// unknown dcl_: dcl_thread_group 16, 16, 1
  r0.xy = cmp((uint2)vThreadGroupID.xy < asuint(cb0[9].xy));
  r0.x = r0.y ? r0.x : 0;
  bitmask.x = ((~(-1 << 2)) << 2) & 0xffffffff;  r1.x = (((uint)vThreadGroupID.y << 2) & bitmask.x) | ((uint)vThreadGroupID.x & ~bitmask.x);
  if (2 == 0) r0.y = 0; else if (2+2 < 32) {   r0.y = (uint)vThreadGroupID.x << (32-(2 + 2)); r0.y = (uint)r0.y >> (32-2);  } else r0.y = (uint)vThreadGroupID.x >> 2;
  bitmask.y = ((~(-1 << 2)) << 0) & 0xffffffff;  r1.y = (((uint)r0.y << 0) & bitmask.y) | ((uint)vThreadGroupID.y & ~bitmask.y);
  r0.xy = r0.xx ? r1.xy : vThreadGroupID.xy;
  r0.z = mad((int)vThreadIDInGroup.y, 16, (int)vThreadIDInGroup.x);
  r1.xyzw = mad((int4)r0.xyyy, int4(16,16,16,16), (int4)vThreadIDInGroup.xyyy);
  r0.xy = (uint2)r0.xy;
  r0.xy = cb0[4].xy * r0.xy;
  r0.xy = r0.xy * float2(16,16) + cb0[7].xy;
  r0.xy = floor(r0.xy);
  r2.xy = (int2)r0.xy;
  r3.zw = float2(0,0);
  r0.w = r0.z;
  while (true) {
    r2.z = cmp((uint)r0.w >= 400);
    if (r2.z != 0) break;
    uiDest.x = (uint)r0.w / 20;
    r5.x = (uint)r0.w % 20;
    r4.x = uiDest.x;
    r5.x = (int)r2.x + (int)r5.x;
    r5.y = (int)r2.y + (int)r4.x;
    r2.zw = (int2)r5.xy + int2(-1,-1);
    r2.zw = max(int2(0,0), (int2)r2.zw);
    r3.xy = min(asint(cb0[4].zw), (int2)r2.zw);
    r4.xyz = t2.Load(r3.xyw).xyz;
    r2.z = t0.Load(r3.xyz).x;
    r4.xyzw = r4.xyzx * r4.xyzx;
    r4.xyzw = min(float4(1,1,1,1), r4.xyzw);
    r3.xy = float2(0.25,0.5) * r4.xy;
    r2.w = r3.x + r3.y;
    r5.x = r4.z * 0.25 + r2.w;
    r2.w = 0.5 * r4.z;
    r5.y = r4.w * 0.5 + -r2.w;
    r2.w = r4.w * -0.25 + r3.y;
    r5.z = -r4.z * 0.25 + r2.w;
    g0[r0.w].val[0/4] = r5.x;
    g0[r0.w].val[0/4+1] = r5.y;
    g0[r0.w].val[0/4+2] = r5.z;
    g1[r0.w].val[0/4] = r2.z;
    r0.w = (int)r0.w + 256;
  }
  GroupMemoryBarrierWithGroupSync();
  r0.zw = cmp((uint2)r1.xw < asuint(cb0[5].xy));
  r0.z = r0.w ? r0.z : 0;
  if (r0.z != 0) {
    r0.zw = (uint2)r1.xw;
    r2.zw = cb0[4].xy * r0.zw;
    r0.zw = r0.zw * cb0[4].xy + cb0[7].xy;
    r0.zw = float2(0.5,0.5) + r0.zw;
    r3.xy = floor(r0.zw);
    r0.xy = r3.xy + -r0.xy;
    r0.xy = (int2)r0.xy;
    r0.xy = max(int2(0,0), (int2)r0.xy);
    r0.xy = min(int2(17,17), (int2)r0.xy);
    r3.x = mad((int)r0.y, 20, (int)r0.x);
    r3.y = g1[r3.x].val[0/4];
    r4.yz = cmp(float2(0,0) < r3.yy);
    r4.x = max(0, r3.y);
    r5.xyzw = (int4)r3.xxxx + int4(21,20,1,22);
    r6.x = g1[r5.z].val[0/4];
    r3.y = cmp(r4.x < r6.x);
    r6.yz = float2(0,-1);
    r3.yzw = r3.yyy ? r6.xyz : r4.xyz;
    r4.xyzw = (int4)r3.xxxx + int4(2,40,41,42);
    r6.x = g1[r4.x].val[0/4];
    r6.w = cmp(r3.y < r6.x);
    r6.yz = float2(1.40129846e-045,-1);
    r3.yzw = r6.www ? r6.xyz : r3.yzw;
    r6.x = g1[r5.y].val[0/4];
    r7.x = cmp(r3.y < r6.x);
    r6.yzw = float3(-1,0,1.40129846e-045);
    r3.yzw = r7.xxx ? r6.xyz : r3.yzw;
    r7.x = g1[r5.x].val[0/4];
    r6.y = cmp(r3.y < r7.x);
    r7.yz = float2(0,0);
    r3.yzw = r6.yyy ? r7.xyz : r3.yzw;
    r6.y = cmp(r3.y < r6.x);
    r3.yzw = r6.yyy ? r6.xwz : r3.yzw;
    r6.x = g1[r4.y].val[0/4];
    r6.w = cmp(r3.y < r6.x);
    r6.yz = float2(-1,1.40129846e-045);
    r3.yzw = r6.www ? r6.xyz : r3.yzw;
    r6.x = g1[r4.z].val[0/4];
    r6.w = cmp(r3.y < r6.x);
    r6.yz = float2(0,1.40129846e-045);
    r3.yzw = r6.www ? r6.xyz : r3.yzw;
    r6.x = g1[r4.w].val[0/4];
    r6.w = cmp(r3.y < r6.x);
    r6.yz = float2(1.40129846e-045,1.40129846e-045);
    r6.xyz = r6.www ? r6.yzx : r3.zwy;
    r0.xy = (int2)r0.xy + (int2)r2.xy;
    r0.xy = (int2)r6.xy + (int2)r0.xy;
    r0.xy = max(int2(0,0), (int2)r0.xy);
    r7.xy = min(asint(cb0[4].zw), (int2)r0.xy);
    r0.xy = cb0[4].xy * float2(0.5,0.5) + r2.zw;
    r6.xy = cb0[6].zw * r0.xy;
    r6.w = 1;
    r2.x = dot(cb0[0].xyzw, r6.xyzw);
    r2.y = dot(cb0[1].xyzw, r6.xyzw);
    r2.z = dot(cb0[3].xyzw, r6.xyzw);
    r2.xy = r2.xy / r2.zz;
    r7.zw = float2(0,0);
    r2.zw = t1.Load(r7.xyz).xy;
    r3.y = r2.z + r2.w;
    r3.yz = cmp(r3.yy < float2(1.89999998,-1.89999998));
    r0.xy = r0.xy * cb0[6].zw + r2.zw;
    r0.xy = r3.yy ? r0.xy : r2.xy;
    r2.xy = float2(-0.5,-0.5) + r0.xy;
    r2.xy = cmp(float2(0.5,0.5) < abs(r2.xy));
    r2.x = (int)r2.y | (int)r2.x;
    r2.x = (int)r3.z | (int)r2.x;
    r2.y = g0[r5.x].val[0/4];
    r2.z = g0[r5.x].val[0/4+1];
    r2.w = g0[r5.x].val[0/4+2];
    r0.zw = frac(r0.zw);
    r6.xyzw = float4(0.5,0.5,-0.5,-0.5) + r0.zwzw;
    r3.yz = float2(0.600000024,0.600000024) * r6.zw;
    r6.xy = -r6.yx * float2(0.600000024,0.600000024) + float2(1,1);
    r3.yz = float2(1,1) + -abs(r3.zy);
    r0.zw = float2(-1.5,-1.5) + r0.zw;
    r0.zw = r0.zw * float2(0.600000024,0.600000024) + float2(1,1);
    r6.zw = r6.yx + r3.zy;
    r6.zw = r6.zw + r0.zw;
    r7.x = g0[r3.x].val[0/4];
    r7.y = g0[r3.x].val[0/4+1];
    r7.z = g0[r3.x].val[0/4+2];
    r3.xw = r6.yz * r6.xw;
    r8.xyz = r3.xxx * r7.xyz;
    r9.x = g0[r5.z].val[0/4];
    r9.y = g0[r5.z].val[0/4+1];
    r9.z = g0[r5.z].val[0/4+2];
    r5.xz = r3.zy * r6.xy;
    r10.xyz = r5.xxx * r9.xyz;
    r11.xyz = r3.xxx * r7.xyz + r10.xyz;
    r9.xyz = r10.xyz * r9.xyz;
    r7.xyz = r8.xyz * r7.xyz + r9.xyz;
    r8.x = g0[r4.x].val[0/4];
    r8.y = g0[r4.x].val[0/4+1];
    r8.z = g0[r4.x].val[0/4+2];
    r6.xy = r0.zw * r6.xy;
    r9.xyz = r6.xxx * r8.xyz;
    r6.xzw = r6.xxx * r8.xyz + r11.xyz;
    r7.xyz = r9.xyz * r8.xyz + r7.xyz;
    r8.x = g0[r5.y].val[0/4];
    r8.y = g0[r5.y].val[0/4+1];
    r8.z = g0[r5.y].val[0/4+2];
    r9.xyz = r8.xyz * r5.zzz;
    r5.xyz = r5.zzz * r8.xyz + r6.xzw;
    r6.xzw = r9.xyz * r8.xyz + r7.xyz;
    r3.x = r3.z * r3.y;
    r7.xyz = r3.xxx * r2.yzw;
    r5.xyz = r3.xxx * r2.yzw + r5.xyz;
    r6.xzw = r7.xyz * r2.yzw + r6.xzw;
    r7.x = g0[r5.w].val[0/4];
    r7.y = g0[r5.w].val[0/4+1];
    r7.z = g0[r5.w].val[0/4+2];
    r3.xy = r0.zw * r3.yz;
    r8.xyz = r3.xxx * r7.xyz;
    r5.xyz = r3.xxx * r7.xyz + r5.xyz;
    r6.xzw = r8.xyz * r7.xyz + r6.xzw;
    r7.x = g0[r4.y].val[0/4];
    r7.y = g0[r4.y].val[0/4+1];
    r7.z = g0[r4.y].val[0/4+2];
    r8.xyz = r7.xyz * r6.yyy;
    r5.xyz = r6.yyy * r7.xyz + r5.xyz;
    r6.xyz = r8.xyz * r7.xyz + r6.xzw;
    r4.x = g0[r4.z].val[0/4];
    r4.y = g0[r4.z].val[0/4+1];
    r4.z = g0[r4.z].val[0/4+2];
    r7.xyz = r4.xyz * r3.yyy;
    r3.xyz = r3.yyy * r4.xyz + r5.xyz;
    r4.xyz = r7.xyz * r4.xyz + r6.xyz;
    r5.x = g0[r4.w].val[0/4];
    r5.y = g0[r4.w].val[0/4+1];
    r5.z = g0[r4.w].val[0/4+2];
    r0.z = r0.z * r0.w;
    r6.xyz = r0.zzz * r5.xyz;
    r3.xyz = r0.zzz * r5.xyz + r3.xyz;
    r4.xyz = r6.xyz * r5.xyz + r4.xyz;
    r0.z = 1 / r3.w;
    r5.xyz = r3.xyz * r0.zzz;
    r6.xyz = r5.xyz * r5.xyz;
    r4.xyz = saturate(r4.xyz * r0.zzz + -r6.xyz);
    r4.xyz = sqrt(r4.xyz);
    r4.xyz = max(float3(0.00200000009,0.00200000009,0.00200000009), r4.xyz);
    r6.xy = r0.xy * cb0[5].zw + float2(-0.5,-0.5);
    r6.xy = floor(r6.xy);
    r6.zw = float2(0.5,0.5) + r6.xy;
    r7.zw = cb0[6].xy * r6.xy;
    r7.xy = cb0[6].xy * float2(2,2) + r7.zw;
    r6.xy = r0.xy * cb0[5].zw + -r6.zw;
    r6.zw = r6.xy * r6.xy;
    r8.xyzw = r6.zwzw * r6.xyxy;
    r9.xy = r8.zw * float2(-0.5,-0.5) + r6.zw;
    r9.xy = -r6.xy * float2(0.5,0.5) + r9.xy;
    r10.xyzw = float4(2.5,2.5,0.5,0.5) * r6.zwzw;
    r9.zw = r8.zw * float2(1.5,1.5) + -r10.xy;
    r9.zw = float2(1,1) + r9.zw;
    r8.xy = float2(-1.5,-1.5) * r8.xy;
    r6.zw = r6.zw * float2(2,2) + r8.xy;
    r6.xy = r6.xy * float2(0.5,0.5) + r6.zw;
    r6.zw = r8.zw * float2(0.5,0.5) + -r10.zw;
    r8.xyzw = t4.Gather(s1_s, r7.zw).xyzw;
    r10.xyzw = t4.Gather(s1_s, r7.xw).xyzw;
    r11.xyzw = t4.Gather(s1_s, r7.zy).xyzw;
    r7.xyzw = t4.Gather(s1_s, r7.xy).xyzw;
    r8.yz = r8.zy * r9.zz;
    r8.xy = r8.wx * r9.xx + r8.yz;
    r8.xy = r10.wx * r6.xx + r8.xy;
    r8.xy = r10.zy * r6.zz + r8.xy;
    r0.w = r8.y * r9.w;
    r0.w = r8.x * r9.y + r0.w;
    r8.xy = r11.zy * r9.zz;
    r8.xy = r11.wx * r9.xx + r8.xy;
    r7.xw = r7.wx * r6.xx + r8.xy;
    r6.xz = r7.zy * r6.zz + r7.xw;
    r0.w = r6.x * r6.y + r0.w;
    r6.x = r6.z * r6.w + r0.w;
    r0.xy = t3.SampleLevel(s1_s, r0.xy, 0).xy;
    r6.yz = float2(0.5,0.5) * r0.xy;
    r0.xyz = -r3.xyz * r0.zzz + r6.xyz;
    r3.xyz = r4.xyz / abs(r0.xyz);
    r0.w = min(r3.y, r3.z);
    r0.w = min(r3.x, r0.w);
    r0.w = min(1, r0.w);
    r0.xyz = r0.xyz * r0.www + r5.xyz;
    r0.w = r2.x ? 0 : 0.899999976;
    r0.xyz = r0.xyz + -r2.yzw;
    r0.xyz = r0.www * r0.xyz + r2.yzw;
  // No code for instruction (needs manual fix):
    store_uav_typed u0.xyzw, r1.xwww, r0.xxxx
    r0.xyzw = r0.yzyy + r0.yzyy;
  // No code for instruction (needs manual fix):
    store_uav_typed u1.xyzw, r1.xyzw, r0.xyzw
  }
  return;
}