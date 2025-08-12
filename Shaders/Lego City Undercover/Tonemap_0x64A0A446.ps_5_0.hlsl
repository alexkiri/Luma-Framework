cbuffer g_MainFilterPS_CB : register(b0)
{

  struct
  {
    float4 mainFilterToneMapping;
    float4 mainFilterDof;
    float4 edgeFilterParams;
    float4 pixel_size;
  } g_MainFilterPS : packoffset(c0);

}

SamplerState fullColor_tex_ss_s : register(s0);
SamplerState blur_tex_ss_s : register(s3);
SamplerState mipColor1_tex_ss_s : register(s4);
SamplerState cubeTex_ss_s : register(s7);
Texture2D<float4> fullColor_tex : register(t0);
Texture2D<float4> blur_tex : register(t3);
Texture2D<float4> mipColor1_tex : register(t4);
Texture3D<float4> cubeTex : register(t7);

#define cmp -

void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD3,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xyz = fullColor_tex.Sample(fullColor_tex_ss_s, v1.xy).xyz;
  r0.xyz = max(float3(0,0,0), r0.xyz);
  r1.xyzw = mipColor1_tex.Sample(mipColor1_tex_ss_s, v1.xy).xyzw;
  r1.xyzw = max(float4(0,0,0,0), r1.xyzw);
  r1.xyz = r1.xyz + -r0.xyz;
  r0.w = r1.w * g_MainFilterPS.mainFilterDof.x + g_MainFilterPS.mainFilterDof.y;
  r1.w = saturate(r0.w * 2 + -1);
  r0.w = r0.w + r0.w;
  r0.w = saturate(r0.w);
  r0.xyz = r1.www * r1.xyz + r0.xyz;
  r1.xyz = blur_tex.Sample(blur_tex_ss_s, v1.xy).xyz;
  r1.xyz = max(float3(0,0,0), r1.xyz);
  r0.xyz = r1.xyz * r1.xyz + r0.xyz;
  r1.xyz = r0.xyz * float3(0.5,0.5,0.5) + float3(0.119999997,0.119999997,0.119999997);
  r2.xyz = float3(5,5,5) * r0.xyz;
  r1.xyz = r2.xyz * r1.xyz + float3(0.00400000019,0.00400000019,0.00400000019);
  r3.xyz = r0.xyz * float3(0.5,0.5,0.5) + float3(0.400000006,0.400000006,0.400000006);
  r2.xyz = r2.xyz * r3.xyz + float3(0.0599999987,0.0599999987,0.0599999987);
  r1.xyz = r1.xyz / r2.xyz;
  r1.xyz = float3(-0.0666666701,-0.0666666701,-0.0666666701) + r1.xyz;
  r1.xyz = float3(1.33959937,1.33959937,1.33959937) * r1.xyz;
  r1.w = cmp(0 < g_MainFilterPS.mainFilterToneMapping.w);
  r0.xyz = r1.www ? r1.xyz : r0.xyz;
  r1.x = dot(r0.xyz, float3(0.298999995,0.587000012,0.114));
  r0.xyz = cubeTex.Sample(cubeTex_ss_s, r0.xyz).xyz;
  o0.xyz = r0.xyz;
  r0.x = cmp(g_MainFilterPS.mainFilterDof.z < r0.w);
  o0.w = r0.x ? r0.w : r1.x;
  return;
}