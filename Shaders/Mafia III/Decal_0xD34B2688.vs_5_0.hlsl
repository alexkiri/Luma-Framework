cbuffer cb1 : register(b1)
{
  float4 cb1[46];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[321];
}

void main(
  uint4 v0 : POSITION0,
  uint4 v1 : TANGENT0,
  uint4 v2 : NORMAL0,
  uint v3 : SV_InstanceID0,
  out float4 o0 : SV_Position0,
  out float4 o1 : TEXCOORD0,
  out float4 o2 : TEXCOORD1,
  out float4 o3 : TEXCOORD2,
  out float4 o4 : TEXCOORD3,
  out float4 o5 : TEXCOORD4,
  out float4 o6 : TEXCOORD5,
  out float4 o7 : TEXCOORD6,
  out float4 o8 : TEXCOORD7,
  out float4 o9 : TEXCOORD8,
  out float4 o10 : TEXCOORD9,
  out float4 o11 : TEXCOORD10)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11;
  r0.xy = (uint2)v1.xy;
  r0.w = (r0.y >= 128);
  r0.w = r0.w ? -128 : -0;
  r0.z = r0.y + r0.w;
  r0.yw = float2(1,256) * cb0[0].ww;
  r1.z = dot(r0.xz, r0.yw);
  r2.xyzw = (uint4)v0.xyzw;
  r1.x = dot(r2.xy, r0.yw);
  r1.y = dot(r2.zw, r0.yw);
  r0.xyz = cb0[0].xyz + r1.xyz;
  int r1xi = v3.x << 2;
  r2.xyzw = cb0[r1xi+66].xyzw * cb1[38].yyyy;
  r2.xyzw = cb1[38].xxxx * cb0[r1xi+65].xyzw + r2.xyzw;
  r2.xyzw = cb1[38].zzzz * cb0[r1xi+67].xyzw + r2.xyzw;
  r3.x = r2.x;
  r4.xyzw = cb0[r1xi+66].xyzw * cb1[39].yyyy;
  r4.xyzw = cb1[39].xxxx * cb0[r1xi+65].xyzw + r4.xyzw;
  r4.xyzw = cb1[39].zzzz * cb0[r1xi+67].xwyz + r4.xwyz;
  r3.y = r4.x;
  r5.xyzw = cb0[r1xi+66].xyzw * cb1[40].yyyy;
  r5.xyzw = cb1[40].xxxx * cb0[r1xi+65].xyzw + r5.xyzw;
  r5.xyzw = cb1[40].zzzz * cb0[r1xi+67].xyzw + r5.xyzw;
  r3.z = r5.x;
  r1.y = dot(r3.xyz, r3.xyz);
  r6.x = sqrt(r1.y);
  r7.x = r2.y;
  r7.y = r4.z;
  r7.z = r5.y;
  r1.y = dot(r7.xyz, r7.xyz);
  r6.y = sqrt(r1.y);
  r8.x = r2.z;
  r8.y = r4.w;
  r8.z = r5.z;
  r1.y = dot(r8.xyz, r8.xyz);
  r6.z = sqrt(r1.y);
  r9.xyz = r6.xyz * r0.xyz;
  r9.w = 1;
  r1.yzw = r3.xyz / r6.xxx;
  r4.x = r1.z;
  r3.xyz = r7.xyz / r6.yyy;
  r4.z = r3.y;
  r5.xyz = r8.xyz / r6.zzz;
  r7.xyz = r5.xyz / r6.zzz;
  r4.w = r5.y;
  r10.x = dot(r9.xwyz, r4.xyzw);
  o10.w = r4.x;
  o11.x = r4.z;
  r11.xyzw = cb1[43].xyzw * r10.xxxx;
  r2.z = r5.x;
  r2.x = r1.y;
  r2.y = r3.x;
  r2.z = dot(r9.xyzw, r2.xyzw);
  o10.xy = r2.xy;
  r4.x = r2.w;
  r11.xyzw = r2.zzzz * cb1[42].xyzw + r11.xyzw;
  o7.w = r2.z;
  r5.x = r1.w;
  r5.y = r3.z;
  r10.y = dot(r9.xyzw, r5.xyzw);
  o8.zw = r5.xy;
  r4.z = r5.w;
  r2.xyz = -r8.xyz * float3(0.5,0.5,0.5) + r4.xyz;
  r4.xyzw = r10.yyyy * cb1[44].xyzw + r11.xyzw;
  o8.xy = r10.xy;
  o0.xyzw = cb1[45].xyzw + r4.xyzw;
  o1.w = 0;
  r4.x = cb0[r1xi+65].x;
  r4.y = cb0[r1xi+66].x;
  r4.z = cb0[r1xi+67].x;
  o1.xyz = -r4.xyz;
  r0.w = 1;
  r4.x = dot(r0.xyzw, cb0[r1xi+65].xyzw);
  r4.y = dot(r0.xyzw, cb0[r1xi+66].xyzw);
  r4.z = dot(r0.xyzw, cb0[r1xi+67].xyzw);
  r0.xyz = cb1[0].xyz + r4.xyz;
  o2.zw = r0.xy;
  o2.xy = float2(0,0);
  r0.w = 1;
  o3.xy = r0.zw;
  r0.xy = float2(1,1) / r6.xy;
  r0.zw = float2(-1,-1) + r6.xy;
  r0.zw = r0.zw * r0.xy;
  r0.zw = float2(0.5,0.5) * r0.zw;
  o4.xy = r0.xy * float2(0.5,0.5) + r0.zw;
  o3.zw = float2(1,-1) * r0.xy;
  o4.zw = cb0[r1xi+68].xy;
  o5.xy = cb0[r1xi+68].zw;
  o5.z = cb0[r1xi+65].z;
  o5.w = cb0[r1xi+66].z;
  o6.xw = cb0[r1xi+67].zy;
  o6.y = cb0[r1xi+65].y;
  o6.z = cb0[r1xi+66].y;
  r0.x = v3.x;
  o7.xyz = cb0[r0.x+1].xyz;
  r0.x = dot(r2.xyz, r1.yzw);
  o9.y = -r0.x;
  r0.x = dot(r2.xyz, r3.xyz);
  r0.y = dot(r2.xyz, r7.xyz);
  o9.zw = -r0.xy;
  o9.x = r7.z;
  o10.z = r7.x;
  o11.y = r7.y;
  o11.zw = float2(0,0);
  // TODO: this needs jittering!
}