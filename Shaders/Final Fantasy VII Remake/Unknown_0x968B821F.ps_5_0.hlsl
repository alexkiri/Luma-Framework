// ---- Created with 3Dmigoto v1.4.1 on Wed Aug  6 21:21:56 2025
Texture2D<float4> t1 : register(t1);

Texture3D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[19];
}




// 3Dmigoto declarations
#define cmp -


void main(
  linear noperspective float4 v0 : TEXCOORD0,
  linear noperspective float4 v1 : TEXCOORD1,
  linear noperspective float4 v2 : TEXCOORD2,
  float4 v3 : SV_POSITION0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = dot(v1.xyz, v1.xyz);
  r0.x = max(9.99999975e-06, r0.x);
  r0.x = rcp(r0.x);
  r0.y = v1.z * v1.z;
  r0.x = -r0.y * r0.x + 1;
  r0.x = max(0, r0.x);
  r0.x = sqrt(r0.x);
  r0.x = cb0[18].x * r0.x;
  r0.x = 0.00999999978 * r0.x;
  r1.x = v2.x;
  r1.y = cb0[18].z * v2.y;
  r0.y = dot(r1.xy, r1.xy);
  r0.y = rsqrt(r0.y);
  r0.yz = r1.xy * r0.yy;
  r0.xy = r0.xx * r0.yz;
  r1.xz = float2(-1,-1) * r0.xx;
  r1.yw = cb0[18].ww * r0.yy;
  r0.xy = (int2)v3.xy;
  r0.xy = (int2)r0.xy & int2(63,63);
  r0.zw = float2(0,0);
  r0.x = t0.Load(r0.xyzw).x;
  r2.xyzw = float4(1,2,3,4) + r0.xxxx;
  r3.xyzw = r2.xxyy * r1.zwzw;
  r2.xyzw = r2.zzww * r1.zwzw;
  r2.xyzw = r2.xyzw * float4(0.0909090936,0.0909090936,0.0909090936,0.0909090936) + v0.xyxy;
  r3.xyzw = r3.xyzw * float4(0.0909090936,0.0909090936,0.0909090936,0.0909090936) + v0.xyxy;
  r0.yzw = t1.Sample(s0_s, r3.xy).xyz;
  r3.xyz = t1.Sample(s0_s, r3.zw).xyz;
  r3.w = dot(r0.yzw, float3(0.212599993,0.715200007,0.0722000003));
  r0.yzw = -r3.www + r0.yzw;
  r4.x = saturate(cb0[18].y);
  r0.yzw = r4.xxx * r0.yzw + r3.www;
  r4.yzw = r0.xxx * float3(0,0.0508474559,0.214285716) + float3(0.0344827585,0,0.142857149);
  r0.yzw = r4.yzw * r0.yzw;
  r4.yz = r1.zw * r0.xx;
  r4.yz = r4.yz * float2(0.0909090936,0.0909090936) + v0.xy;
  r4.yzw = t1.Sample(s0_s, r4.yz).xyz;
  r3.w = dot(r4.yzw, float3(0.212599993,0.715200007,0.0722000003));
  r4.yzw = r4.yzw + -r3.www;
  r4.yzw = r4.xxx * r4.yzw + r3.www;
  r4.yzw = r4.yzw * r0.xxx;
  r0.yzw = r4.yzw * float3(0.0344827585,0,0.142857149) + r0.yzw;
  r3.w = dot(r3.xyz, float3(0.212599993,0.715200007,0.0722000003));
  r3.xyz = r3.xyz + -r3.www;
  r3.xyz = r4.xxx * r3.xyz + r3.www;
  r4.yzw = r0.xxx * float3(-0.0229885057,0.101694912,-0.0892857313) + float3(0.0344827585,0.0508474559,0.357142866);
  r0.yzw = r3.xyz * r4.yzw + r0.yzw;
  r3.xyz = t1.Sample(s0_s, r2.xy).xyz;
  r2.xyz = t1.Sample(s0_s, r2.zw).xyz;
  r2.w = dot(r3.xyz, float3(0.212599993,0.715200007,0.0722000003));
  r3.xyz = r3.xyz + -r2.www;
  r3.xyz = r4.xxx * r3.xyz + r2.www;
  r4.yzw = r0.xxx * float3(-0.0114942528,0.0423728824,-0.107142851) + float3(0.0114942528,0.152542368,0.267857134);
  r0.yzw = r3.xyz * r4.yzw + r0.yzw;
  r2.w = dot(r2.xyz, float3(0.212599993,0.715200007,0.0722000003));
  r2.xyz = r2.xyz + -r2.www;
  r2.xyz = r4.xxx * r2.xyz + r2.www;
  r3.xyz = r0.xxx * float3(0.0114942528,0.00847457349,-0.089285709) + float3(0,0.19491525,0.160714284);
  r0.yzw = r2.xyz * r3.xyz + r0.yzw;
  r2.xyzw = float4(5,6,7,8) + r0.xxxx;
  r3.xyzw = r2.xxyy * r1.zwzw;
  r2.xyzw = r2.zzww * r1.zwzw;
  r2.xyzw = r2.xyzw * float4(0.0909090936,0.0909090936,0.0909090936,0.0909090936) + v0.xyxy;
  r3.xyzw = r3.xyzw * float4(0.0909090936,0.0909090936,0.0909090936,0.0909090936) + v0.xyxy;
  r4.yzw = t1.Sample(s0_s, r3.xy).xyz;
  r3.xyz = t1.Sample(s0_s, r3.zw).xyz;
  r3.w = dot(r4.yzw, float3(0.212599993,0.715200007,0.0722000003));
  r4.yzw = r4.yzw + -r3.www;
  r4.yzw = r4.xxx * r4.yzw + r3.www;
  r5.xyz = r0.xxx * float3(0.149425298,-0.00847457349,-0.0714285746) + float3(0.0114942528,0.203389823,0.0714285746);
  r0.yzw = r4.yzw * r5.xyz + r0.yzw;
  r3.w = dot(r3.xyz, float3(0.212599993,0.715200007,0.0722000003));
  r3.xyz = r3.xyz + -r3.www;
  r3.xyz = r4.xxx * r3.xyz + r3.www;
  r4.yzw = r0.xxx * float3(0.114942521,-0.0423728824,0) + float3(0.160919547,0.19491525,0);
  r0.yzw = r3.xyz * r4.yzw + r0.yzw;
  r3.xyz = t1.Sample(s0_s, r2.xy).xyz;
  r2.xyz = t1.Sample(s0_s, r2.zw).xyz;
  r2.w = dot(r3.xyz, float3(0.212599993,0.715200007,0.0722000003));
  r3.xyz = r3.xyz + -r2.www;
  r3.xyz = r4.xxx * r3.xyz + r2.www;
  r4.yzw = r0.xxx * float3(-0.0114942491,-0.101694912,0) + float3(0.275862068,0.152542368,0);
  r0.yzw = r3.xyz * r4.yzw + r0.yzw;
  r2.w = dot(r2.xyz, float3(0.212599993,0.715200007,0.0722000003));
  r2.xyz = r2.xyz + -r2.www;
  r2.xyz = r4.xxx * r2.xyz + r2.www;
  r3.xyz = r0.xxx * float3(-0.114942536,-0.0508474559,0) + float3(0.264367819,0.0508474559,0);
  r0.yzw = r2.xyz * r3.xyz + r0.yzw;
  r2.xyzw = float4(9,9,10,10) + r0.xxxx;
  r3.xyzw = r0.xxxx * float4(-0.0919540226,0,-0.0574712642,0) + float4(0.149425283,0,0.0574712642,0);
  r1.xyzw = r2.xyzw * r1.xyzw;
  r1.xyzw = r1.xyzw * float4(0.0909090936,0.0909090936,0.0909090936,0.0909090936) + v0.xyxy;
  r2.xyz = t1.Sample(s0_s, r1.xy).xyz;
  r1.xyz = t1.Sample(s0_s, r1.zw).xyz;
  r0.x = dot(r2.xyz, float3(0.212599993,0.715200007,0.0722000003));
  r2.xyz = r2.xyz + -r0.xxx;
  r2.xyz = r4.xxx * r2.xyz + r0.xxx;
  r0.xyz = r2.xyz * r3.xyy + r0.yzw;
  r0.w = dot(r1.xyz, float3(0.212599993,0.715200007,0.0722000003));
  r1.xyz = r1.xyz + -r0.www;
  r1.xyz = r4.xxx * r1.xyz + r0.www;
  o0.xyz = r1.xyz * r3.zww + r0.xyz;
  o0.w = 1;
  return;
}