cbuffer cb2 : register(b2)
{
  float4 cb2[26];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[1];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[905];
}

#define cmp

void main(
  uint4 v0 : POSITION0,
  uint4 v1 : TANGENT0,
  uint4 v2 : NORMAL0,
  uint4 v3 : BLENDINDICES0,
  float4 v4 : BLENDWEIGHT0,
  float4 v5 : COLOR0,
  float4 v6 : TEXCOORD0,
  float4 v7 : TEXCOORD2,
  float3 v8 : TEXCOORD4,
  uint4 v9 : PSIZE1,
  float4 v10 : POSITION1,
  float2 v11 : NORMAL1,
  out float4 o0 : SV_Position0,
  out float4 o1 : TEXCOORD0,
  out float4 o2 : TEXCOORD1,
  out float4 o3 : TEXCOORD2,
  out float4 o4 : TEXCOORD3,
  out float4 o5 : TEXCOORD4,
  out float4 o6 : TEXCOORD5,
  out float4 o7 : TEXCOORD6)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12;
  r0.xyzw = (uint4)v1.xyzw;
  r1.x = cmp(r0.y >= 128);
  r1.xy = r1.xx ? float2(-128,-1) : float2(-0,1);
  r0.y = r1.x + r0.y;
  r1.xz = float2(1,256) * cb0[1].ww;
  r2.z = dot(r0.xy, r1.xz);
  r3.xyzw = (uint4)v0.xyzw;
  r2.x = dot(r3.xy, r1.xz);
  r2.y = dot(r3.zw, r1.xz);
  r1.xzw = cb0[1].xyz + r2.xyz;
  r2.xyzw = (uint4)v10.xyzw >> int4(16,24,24,31);
  r3.y = f16tof32(r2.x);
  r2.xyz = (uint3)r2.yzw;
  r4.xyz = (int3)v10.xyz & int3(0xffff,0xffff,255);
  r3.xz = f16tof32(r4.xy);
  r4.z = (uint)r4.z;
  r3.xyz = r3.xyz + r1.xzw;
  r3.w = 1;
  r5.xyzw = (int4)v3.xyzw * int4(3,3,3,3);
  r6.xyzw = cb0[r5.y+137].xyzw * v4.yyyy;
  r6.xyzw = v4.xxxx * cb0[r5.x+137].xyzw + r6.xyzw;
  r6.xyzw = v4.zzzz * cb0[r5.z+137].xyzw + r6.xyzw;
  r6.xyzw = v4.wwww * cb0[r5.w+137].xyzw + r6.xyzw;
  r7.x = dot(r6.xyzw, r3.xyzw);
  r8.xyzw = cb0[r5.y+138].xyzw * v4.yyyy;
  r8.xyzw = v4.xxxx * cb0[r5.x+138].xyzw + r8.xyzw;
  r8.xyzw = v4.zzzz * cb0[r5.z+138].xyzw + r8.xyzw;
  r8.xyzw = v4.wwww * cb0[r5.w+138].xyzw + r8.xyzw;
  r7.y = dot(r8.xyzw, r3.xyzw);
  r9.xyzw = cb0[r5.y+139].xyzw * v4.yyyy;
  r9.xyzw = v4.xxxx * cb0[r5.x+139].xyzw + r9.xyzw;
  r9.xyzw = v4.zzzz * cb0[r5.z+139].xyzw + r9.xyzw;
  r9.xyzw = v4.wwww * cb0[r5.w+139].xyzw + r9.xyzw;
  r7.z = dot(r9.xyzw, r3.xyzw);
  r7.xyz = cb0[4].xyz + r7.xyz;
  r7.w = 1;
  r3.y = dot(cb2[24].xyzw, r7.xyzw);
  o0.z = r3.y;
  r0.y = dot(cb2[25].xyzw, r7.xyzw);
  o0.w = r0.y;
  r3.x = cb2[1].w * r0.y;
  o3.y = dot(cb2[2].xy, r3.xy);
  o0.x = dot(cb2[22].xyzw, r7.xyzw);
  o0.y = dot(cb2[23].xyzw, r7.xyzw);
  r0.y = (uint)v11.x >> 16;
  r10.y = f16tof32(r0.y);
  r3.xy = (int2)v11.xy & int2(0xffff,0xffff);
  r10.xz = f16tof32(r3.xy);
  r10.xyz = r10.xyz + r1.xzw;
  r11.xyzw = cb0[r5.y+521].xyzw * v4.yyyy;
  r11.xyzw = v4.xxxx * cb0[r5.x+521].xyzw + r11.xyzw;
  r11.xyzw = v4.zzzz * cb0[r5.z+521].xyzw + r11.xyzw;
  r11.xyzw = v4.wwww * cb0[r5.w+521].xyzw + r11.xyzw;
  r10.w = 1;
  r11.x = dot(r11.xyzw, r10.xyzw);
  r12.xyzw = cb0[r5.y+522].xyzw * v4.yyyy;
  r12.xyzw = v4.xxxx * cb0[r5.x+522].xyzw + r12.xyzw;
  r12.xyzw = v4.zzzz * cb0[r5.z+522].xyzw + r12.xyzw;
  r12.xyzw = v4.wwww * cb0[r5.w+522].xyzw + r12.xyzw;
  r11.y = dot(r12.xyzw, r10.xyzw);
  r12.xyzw = cb0[r5.y+523].xyzw * v4.yyyy;
  r12.xyzw = v4.xxxx * cb0[r5.x+523].xyzw + r12.xyzw;
  r12.xyzw = v4.zzzz * cb0[r5.z+523].xyzw + r12.xyzw;
  r5.xyzw = v4.wwww * cb0[r5.w+523].xyzw + r12.xyzw;
  r11.z = dot(r5.xyzw, r10.xyzw);
  r1.xzw = cb0[5].xyz + r11.xyz;
  r1.xzw = r7.xyz + -r1.xzw;
  r5.x = dot(r6.xyz, v8.xyz);
  r5.y = dot(r8.xyz, v8.xyz);
  r5.z = dot(r9.xyz, v8.xyz);
  r1.xzw = r5.xyz + r1.xzw;
  o1.w = r1.x;
  o2.xy = r1.zw;
  r5.xyzw = (uint4)v2.xyzw;
  r0.x = r5.w;
  r5.xyzw = r5.zxyz * float4(0.00784313772,0.00784313772,0.00784313772,0.00784313772) + float4(-1,-1,-1,-1);
  r0.xyz = r0.zwx * float3(0.00784313772,0.00784313772,0.00784313772) + float3(-1,-1,-1);
  // Likely very broken
  if (8 == 0) r1.x = 0; else if (8+16 < 32) {   r1.x = (uint)v10.y << (32-(8 + 16)); r1.x = (uint)r1.x >> (32-8);  } else r1.x = (uint)v10.y >> 16;
  if (8 == 0) r1.z = 0; else if (8+8 < 32) {   r1.z = (uint)v10.z << (32-(8 + 8)); r1.z = (uint)r1.z >> (32-8);  } else r1.z = (uint)v10.z >> 8;
  if (8 == 0) r1.w = 0; else if (8+16 < 32) {   r1.w = (uint)v10.z << (32-(8 + 16)); r1.w = (uint)r1.w >> (32-8);  } else r1.w = (uint)v10.z >> 16;
  r10.xyz = (uint3)r1.xzw;
  r10.w = r2.y;
  r1.xzw = r10.yzw * float3(0.00784313772,0.00784313772,0.00784313772) + float3(-1,-1,-1);
  r4.x = r10.x;
  r0.xyz = r0.xyz * r2.zzz + r1.xzw;
  o1.x = dot(r6.xyz, r0.xyz);
  o1.y = dot(r8.xyz, r0.xyz);
  o1.z = dot(r9.xyz, r0.xyz);
  o2.zw = r7.xy;
  o3.x = r7.z;
  o3.zw = v5.xy;
  r4.y = r2.x;
  r1.xzw = r4.xyz * float3(0.00784313772,0.00784313772,0.00784313772) + float3(-1,-1,-1);
  r1.xzw = r5.yzw * r2.zzz + r1.xzw;
  o6.z = r5.x;
  o4.w = dot(r6.xyz, r1.xzw);
  r2.xy = float2(0.0700000003,0) + cb1[0].xy;
  r0.w = r2.x + -r3.z;
  o6.y = saturate(0.588235259 * r3.z);
  r0.w = max(0, r0.w);
  r0.w = 100 * r0.w;
  r0.w = min(1, r0.w);
  o4.z = saturate(r0.w * r2.y);
  o4.xy = v5.zw;
  r2.xyz = r1.wxz * r0.yzx;
  r0.xyz = r1.zwx * r0.zxy + -r2.xyz;
  r0.xyz = r0.xyz * r1.yyy;
  o5.z = dot(r6.xyz, r0.xyz);
  o5.w = dot(r8.xyz, r0.xyz);
  o5.x = dot(r8.xyz, r1.xzw);
  o5.y = dot(r9.xyz, r1.xzw);
  o6.x = dot(r9.xyz, r0.xyz);
  o6.w = v6.x;
  o7.x = v6.y;
  o7.yz = v7.xy;
  o7.w = 0;
}