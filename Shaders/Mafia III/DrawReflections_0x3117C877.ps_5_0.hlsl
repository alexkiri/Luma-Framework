TextureCube<float4> t4 : register(t4);
TextureCubeArray<float4> t3 : register(t3);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t0 : register(t0);

SamplerState s1_s : register(s1);
SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[47];
}

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  out float4 o0 : SV_Target0,
  out float4 o1 : SV_Target1,
  out float4 o2 : SV_Target2)
{
  float4 r0,r1,r2,r3,r4,r5;
  r0.x = (0.0 != cb0[2].x);
  if (r0.x != 0) {
    r0.x = t1.SampleLevel(s0_s, v1.xy, 0).x;
    r1.xy = v1.zw;
    r1.z = v2.x;
    r0.xyz = r1.xyz * r0.x + cb0[0].xyz;
  } else {
    r1.xy = trunc(v0.xy);
    r1.zw = v1.xy * float2(2,-2) + float2(-1,1);
    r2.xy = -cb0[6].xy + r1.zw;
    r2.z = t1.Load(int3(r1.xy, 0)).x;
    r2.w = 1;
    r0.x = dot(cb0[26].xyzw, r2.xyzw);
    r0.y = dot(cb0[27].xyzw, r2.xyzw);
    r0.z = dot(cb0[28].xyzw, r2.xyzw);
  }
  r1.xz = v1.zw;
  r1.y = v2.x;
  r0.w = dot(-r1.xyz, -r1.xyz);
  r0.w = rsqrt(r0.w);
  r1.xyz = -r1.xyz * r0.w;
  r2.xyzw = t0.Sample(s0_s, v2.yz).xyzw; // Normals and specularity
  float specularity = r2.w;
  r0.w = t2.Sample(s0_s, v2.yz).y;
  r2.xyz = r2.xzy * 2.0 - 1.0;
  r1.w = dot(r2.xyz, r2.xyz);
  r1.w = rsqrt(r1.w);
  r2.xyz = r2.xyz * r1.w;
  r1.w = t1.Sample(s0_s, v2.yz).x;
  r3.x = dot(r1.xyz, r2.xyz);
  r3.x = r3.x + r3.x;
  r1.xyz = r2.xyz * -r3.x + r1.xyz;
  r2.xyz = -r1.xyz;
  r2.w = 16 * r2.w;
  r2.w = exp2(r2.w);
  r3.x = 1 + r2.w;
  r3.x = rsqrt(r3.x);
  r3.x = 443.391998 * r3.x;
  r3.x = log2(r3.x);
  r1.w = (r1.w < 0.9);
  r2.w = 1 / r2.w;
  r2.w = -9.96578407 * r2.w;
  r2.w = exp2(r2.w);
  r3.y = 1 + -r2.w;
  r3.y = sqrt(r3.y);
  r3.z = r2.w * -0.0216409508 + 0.0779804811;
  r3.z = r2.w * r3.z + -0.213300988;
  r2.w = r2.w * r3.z + 1.57079637;
  r2.w = r3.y * r2.w + -0.0145138903;
  r0.w = r2.w * r0.w;
  r0.w = 0.5 * r0.w;
  sincos(r0.w, r4.x, r5.x);
  r0.w = r4.x / r5.x;
  r4.w = r0.w / cb0[21].z;
  r0.xyz = -cb0[46].xzy + r0.xzy;
  r0.xyz = r1.xyz * -1.3 + r0.xyz;
  r1.x = trunc(r3.x);
  r0.w = cb0[46].w; // Decides the cubemap to reflect
  r0.xyz = t3.SampleLevel(s1_s, r0.xyzw, r1.x).xyz; // Reflections (an array of 2D planar reflections)
  r0.w = r0.x + r0.y;
  r0.w = r0.w + r0.z;
  r0.w = (r0.w == 0.0);
  r1.xyz = t4.SampleLevel(s1_s, r2.xyz, r1.x).xyz; // Sky cube map
  r1.xyz = r0.w ? r1.xyz : 0;
  r4.xyz = r1.xyz + r0.xyz;
  r0.xyzw = r1.w ? r4.xyzw : 0;
  o0.xyzw = r0.xyzw;
  o1.xyzw = r0.w;
  o2.xyzw = float4(0,0,0,0);
#if DEVELOPMENT // Test: disable mirrors // TODO: test and expose
  bool isMirror = specularity >= 0.9882; // Mirrors have specularity set to ~0.98
  if (isMirror)
    o0.rgb = 0.0333; // Alpha channel doesn't seem to be needed (maybe). Randomly picked a value that looked good.
  // o1 does other stuff and is best left at its original value
#endif
}