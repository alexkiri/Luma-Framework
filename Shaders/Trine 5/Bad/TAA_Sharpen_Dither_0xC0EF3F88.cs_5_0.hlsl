Texture2D<unorm float4> t3 : register(t3); // Film grain / noise / dither
Texture2D<unorm float> t2 : register(t2); // Scene Y (luminance)
Texture2D<snorm float2> t1 : register(t1); // Scene Co/Cg
#if 1 // LUMA
Texture2D<float4> t0 : register(t0); // Source color (HDR)
RWTexture2D<float4> u0 : register(u0); // Output
#else
Texture2D<unorm float4> t0 : register(t0); // Source color (SDR)
RWTexture2D<unorm float4> u0 : register(u0); // Output
#endif

cbuffer cb0 : register(b0)
{
  float4 cb0[3];
}

#define cmp -

[numthreads(64, 1, 1)]
void main(uint3 vThreadGroupID : SV_GroupID, uint3 vThreadIDInGroup : SV_GroupThreadID)
{
  float4 r0,r1,r2,r3,r4,r5;
  uint4 bitmask;
  
  r0.x = (uint)vThreadIDInGroup.x >> 3;
  bitmask.y = ((~(-1 << 1)) << 0) & 0xffffffff;  r0.y = (((uint)vThreadIDInGroup.x << 0) & bitmask.y) | ((uint)r0.x & ~bitmask.y);
  if (3 == 0) r0.x = 0; else if (3+1 < 32) {   r0.x = (uint)vThreadIDInGroup.x << (32-(3 + 1)); r0.x = (uint)r0.x >> (32-3);  } else r0.x = (uint)vThreadIDInGroup.x >> 1;
  r0.xz = mad((int2)vThreadGroupID.xy, int2(16,16), (int2)r0.xy);
  r0.yw = float2(0,0);
  r1.x = t2.Load(r0.xzw).x;
  r1.yz = t1.Load(r0.xzy).xy;
  r1.w = -r1.y * 0.5 + r1.x;
  r2.yw = r1.zy * float2(0.5,0.5) + r1.xx;
  r2.z = -r1.z * 0.5 + r1.w;
  r2.x = -r1.z * 0.5 + r2.w;
  r2.xyz = saturate(r2.xyz);
  r1.xyz = log2(r2.xyz);
  r1.xyz = float3(0.416666657,0.416666657,0.416666657) * r1.xyz;
  r1.xyz = exp2(r1.xyz);
  r1.xyz = r1.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = r2.xyz * float3(12.9200001,12.9200001,12.9200001) + -r1.xyz;
  r2.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r2.xyz);
  r2.xyz = r2.xyz ? float3(1,1,1) : 0;
  r1.xyz = r2.xyz * r3.xyz + r1.xyz;
  r2.xy = (int2)r0.xz + asint(cb0[1].zw);
  r2.xy = (int2)r2.xy & int2(63,63);
  r2.zw = float2(0,0);
  r2.xyz = t3.Load(r2.xyz).xyz;
  r2.xyz = r2.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r3.xyz = cmp(float3(0,0,0) < r2.xyz);
  r4.xyz = cmp(r2.xyz < float3(0,0,0));
  r2.xyz = float3(1,1,1) + -abs(r2.xyz);
  r2.xyz = sqrt(r2.xyz);
  r2.xyz = float3(1,1,1) + -r2.xyz;
  r3.xyz = (int3)-r3.xyz + (int3)r4.xyz;
  r3.xyz = (int3)r3.xyz;
  r2.xyz = r3.xyz * r2.xyz;
  r1.xyz = r2.xyz * float3(0.00787401572,0.00787401572,0.00787401572) + r1.xyz;
  r1.w = 1;
  r2.xyzw = (int4)r0.xzzz + asint(cb0[2].xyyy);
  r0.xy = (int2)r0.xz + int2(8,8);
// No code for instruction (needs manual fix):
store_uav_typed u0.xyzw, r2.xyzw, r1.xyzw
  r1.x = t2.Load(r0.xzw).x;
  r1.yz = t1.Load(r0.xzw).xy;
  r1.w = -r1.y * 0.5 + r1.x;
  r2.yw = r1.zy * float2(0.5,0.5) + r1.xx;
  r2.z = -r1.z * 0.5 + r1.w;
  r2.x = -r1.z * 0.5 + r2.w;
  r2.xyz = saturate(r2.xyz);
  r1.xyz = log2(r2.xyz);
  r1.xyz = float3(0.416666657,0.416666657,0.416666657) * r1.xyz;
  r1.xyz = exp2(r1.xyz);
  r1.xyz = r1.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = r2.xyz * float3(12.9200001,12.9200001,12.9200001) + -r1.xyz;
  r2.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r2.xyz);
  r2.xyz = r2.xyz ? float3(1,1,1) : 0;
  r1.xyz = r2.xyz * r3.xyz + r1.xyz;
  r2.zw = float2(0,0);
  r3.xyzw = (int4)r0.xzxy + asint(cb0[1].zwzw);
  r2.xy = (int2)r3.xy & int2(63,63);
  r3.xy = (int2)r3.zw & int2(63,63);
  r2.xyz = t3.Load(r2.xyz).xyz;
  r2.xyz = r2.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r4.xyz = cmp(float3(0,0,0) < r2.xyz);
  r5.xyz = cmp(r2.xyz < float3(0,0,0));
  r2.xyz = float3(1,1,1) + -abs(r2.xyz);
  r2.xyz = sqrt(r2.xyz);
  r2.xyz = float3(1,1,1) + -r2.xyz;
  r4.xyz = (int3)-r4.xyz + (int3)r5.xyz;
  r4.xyz = (int3)r4.xyz;
  r2.xyz = r4.xyz * r2.xyz;
  r1.xyz = r2.xyz * float3(0.00787401572,0.00787401572,0.00787401572) + r1.xyz;
  r1.w = 1;
  r2.xyzw = (int4)r0.xzzz + asint(cb0[2].xyyy);
// No code for instruction (needs manual fix):
store_uav_typed u0.xyzw, r2.xyzw, r1.xyzw
  r0.z = t2.Load(r0.xyw).x;
  r1.xy = t1.Load(r0.xyw).xy;
  r2.yzw = r0.yww;
  r0.w = -r1.x * 0.5 + r0.z;
  r4.yw = r1.yx * float2(0.5,0.5) + r0.zz;
  r4.z = -r1.y * 0.5 + r0.w;
  r4.x = -r1.y * 0.5 + r4.w;
  r4.xyz = saturate(r4.xyz);
  r1.xyz = log2(r4.xyz);
  r1.xyz = float3(0.416666657,0.416666657,0.416666657) * r1.xyz;
  r1.xyz = exp2(r1.xyz);
  r1.xyz = r1.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r5.xyz = r4.xyz * float3(12.9200001,12.9200001,12.9200001) + -r1.xyz;
  r4.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r4.xyz);
  r4.xyz = r4.xyz ? float3(1,1,1) : 0;
  r1.xyz = r4.xyz * r5.xyz + r1.xyz;
  r3.zw = float2(0,0);
  r3.xyz = t3.Load(r3.xyz).xyz;
  r3.xyz = r3.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r4.xyz = cmp(float3(0,0,0) < r3.xyz);
  r5.xyz = cmp(r3.xyz < float3(0,0,0));
  r3.xyz = float3(1,1,1) + -abs(r3.xyz);
  r3.xyz = sqrt(r3.xyz);
  r3.xyz = float3(1,1,1) + -r3.xyz;
  r4.xyz = (int3)-r4.xyz + (int3)r5.xyz;
  r4.xyz = (int3)r4.xyz;
  r3.xyz = r4.xyz * r3.xyz;
  r1.xyz = r3.xyz * float3(0.00787401572,0.00787401572,0.00787401572) + r1.xyz;
  r1.w = 1;
  r3.xyzw = (int4)r0.xyyy + asint(cb0[2].xyyy);
  r2.x = (int)r0.x + -8;
// No code for instruction (needs manual fix):
store_uav_typed u0.xyzw, r3.xyzw, r1.xyzw
  r0.x = t2.Load(r2.xyw).x;
  r0.yz = t1.Load(r2.xyz).xy;
  r0.w = -r0.y * 0.5 + r0.x;
  r1.yw = r0.zy * float2(0.5,0.5) + r0.xx;
  r1.z = -r0.z * 0.5 + r0.w;
  r1.x = -r0.z * 0.5 + r1.w;
  r1.xyz = saturate(r1.xyz);
  r0.xyz = log2(r1.xyz);
  r0.xyz = float3(0.416666657,0.416666657,0.416666657) * r0.xyz;
  r0.xyz = exp2(r0.xyz);
  r0.xyz = r0.xyz * float3(1.05499995,1.05499995,1.05499995) + float3(-0.0549999997,-0.0549999997,-0.0549999997);
  r3.xyz = r1.xyz * float3(12.9200001,12.9200001,12.9200001) + -r0.xyz;
  r1.xyz = cmp(float3(0.00313080009,0.00313080009,0.00313080009) >= r1.xyz);
  r1.xyz = r1.xyz ? float3(1,1,1) : 0;
  r0.xyz = r1.xyz * r3.xyz + r0.xyz;
  r1.xy = (int2)r2.xy + asint(cb0[1].zw);
  r2.xyzw = (int4)r2.xyyy + asint(cb0[2].xyyy);
  r1.xy = (int2)r1.xy & int2(63,63);
  r1.zw = float2(0,0);
  r1.xyz = t3.Load(r1.xyz).xyz;
  r1.xyz = r1.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r3.xyz = cmp(float3(0,0,0) < r1.xyz);
  r4.xyz = cmp(r1.xyz < float3(0,0,0));
  r1.xyz = float3(1,1,1) + -abs(r1.xyz);
  r1.xyz = sqrt(r1.xyz);
  r1.xyz = float3(1,1,1) + -r1.xyz;
  r3.xyz = (int3)-r3.xyz + (int3)r4.xyz;
  r3.xyz = (int3)r3.xyz;
  r1.xyz = r3.xyz * r1.xyz;
  r0.xyz = r1.xyz * float3(0.00787401572,0.00787401572,0.00787401572) + r0.xyz;
  r0.w = 1;
// No code for instruction (needs manual fix):
store_uav_typed u0.xyzw, r2.xyzw, r0.xyzw
  return;
}