#include "Includes/Common.hlsl"
#include "../Includes/Reinhard.hlsl"

#define NEW_IMPLEMENTATION 0

#if NEW_IMPLEMENTATION
cbuffer cb0 : register(b0)
{
  float4 cb0[10];
}
#else
cbuffer cb0_buf : register(b0)
{
    float4 cb0_m0 : packoffset(c0);
    float4 cb0_m1 : packoffset(c1);
    uint4 cb0_m2 : packoffset(c2);
    float4 cb0_m3 : packoffset(c3);
    float2 cb0_m4 : packoffset(c4);
    int2 cb0_m5 : packoffset(c4.z);
    uint2 cb0_m6 : packoffset(c5);
    float2 cb0_m7 : packoffset(c5.z);
    float2 cb0_m8 : packoffset(c6);
    float2 cb0_m9 : packoffset(c6.z);
    float2 cb0_m10 : packoffset(c7);
    uint2 cb0_m11 : packoffset(c7.z);
    uint4 cb0_m12 : packoffset(c8);
    uint2 cb0_m13 : packoffset(c9);
    uint2 cb0_m14 : packoffset(c9.z);
};
#endif

Texture2D<float> t0 : register(t0); // Depth
Texture2D<snorm float2> t1 : register(t1); // Some mask
Texture2D<float4> t2 : register(t2); // Scene
Texture2D<snorm float2> t3 : register(t3); // Previous frame's u1
Texture2D<unorm float> t4 : register(t4); // Previous frame's u0

RWTexture2D<unorm float> u0 : register(u0);
RWTexture2D<snorm float2> u1 : register(u1);

SamplerState s1_s : register(s1);

#define cmp

#if NEW_IMPLEMENTATION
groupshared struct { float val[1]; } g1[400];
groupshared struct { float val[3]; } g0[400];
#else
struct trioData
{
    float _m0;
    float _m1;
    float _m2;
};
groupshared trioData g0[400];
groupshared float g1[400];
#endif

uint spvBitfieldInsert(uint Base, uint Insert, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : (((1u << Count) - 1) << (Offset & 31));
    return (Base & ~Mask) | ((Insert << Offset) & Mask);
}

uint2 spvBitfieldInsert(uint2 Base, uint2 Insert, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : (((1u << Count) - 1) << (Offset & 31));
    return (Base & ~Mask) | ((Insert << Offset) & Mask);
}

uint3 spvBitfieldInsert(uint3 Base, uint3 Insert, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : (((1u << Count) - 1) << (Offset & 31));
    return (Base & ~Mask) | ((Insert << Offset) & Mask);
}

uint4 spvBitfieldInsert(uint4 Base, uint4 Insert, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : (((1u << Count) - 1) << (Offset & 31));
    return (Base & ~Mask) | ((Insert << Offset) & Mask);
}

uint spvBitfieldUExtract(uint Base, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : ((1 << Count) - 1);
    return (Base >> Offset) & Mask;
}

uint2 spvBitfieldUExtract(uint2 Base, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : ((1 << Count) - 1);
    return (Base >> Offset) & Mask;
}

uint3 spvBitfieldUExtract(uint3 Base, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : ((1 << Count) - 1);
    return (Base >> Offset) & Mask;
}

uint4 spvBitfieldUExtract(uint4 Base, uint Offset, uint Count)
{
    uint Mask = Count == 32 ? 0xffffffff : ((1 << Count) - 1);
    return (Base >> Offset) & Mask;
}

int spvBitfieldSExtract(int Base, int Offset, int Count)
{
    int Mask = Count == 32 ? -1 : ((1 << Count) - 1);
    int Masked = (Base >> Offset) & Mask;
    int ExtendShift = (32 - Count) & 31;
    return (Masked << ExtendShift) >> ExtendShift;
}

int2 spvBitfieldSExtract(int2 Base, int Offset, int Count)
{
    int Mask = Count == 32 ? -1 : ((1 << Count) - 1);
    int2 Masked = (Base >> Offset) & Mask;
    int ExtendShift = (32 - Count) & 31;
    return (Masked << ExtendShift) >> ExtendShift;
}

int3 spvBitfieldSExtract(int3 Base, int Offset, int Count)
{
    int Mask = Count == 32 ? -1 : ((1 << Count) - 1);
    int3 Masked = (Base >> Offset) & Mask;
    int ExtendShift = (32 - Count) & 31;
    return (Masked << ExtendShift) >> ExtendShift;
}

int4 spvBitfieldSExtract(int4 Base, int Offset, int Count)
{
    int Mask = Count == 32 ? -1 : ((1 << Count) - 1);
    int4 Masked = (Base >> Offset) & Mask;
    int ExtendShift = (32 - Count) & 31;
    return (Masked << ExtendShift) >> ExtendShift;
}

int cvt_f32_i32(float v)
{
    return isnan(v) ? 0 : ((v < (-2147483648.0f)) ? int(0x80000000) : ((v > 2147483520.0f) ? 2147483647 : int(v)));
}

float dp4_f32(float4 a, float4 b)
{
    precise float _96 = a.x * b.x;
    return mad(a.w, b.w, mad(a.z, b.z, mad(a.y, b.y, _96)));
}

[numthreads(16, 16, 1)]
void main(uint3 vThreadGroupID : SV_GroupID, uint3 vThreadIDInGroup : SV_GroupThreadID)
{
	float whiteRatio = 1.0;
#if 1 // Luma: scale the luminance stored in the sharpen preparation Y texture by the peak brightness (range would have been 0-1 in SDR, but now it'd clip). It's ok as the texture is 16 bit so there's quality for it.
	whiteRatio = LumaSettings.PeakWhiteNits / LumaSettings.GamePaperWhiteNits;
#endif

#if NEW_IMPLEMENTATION // Easier to read version, seems to work properly!

  float4 r0,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11;
  uint4 r0u;
  int4 r0i;
  int4 r1i;
  int4 r2i;
  uint4 r3u;
  uint4 r4u;
  uint4 r5u;

  r0u.xy = cmp(vThreadGroupID.xy < asuint(cb0[9].xy));
  r0u.x = r0u.y | r0u.x;
  r0u.y = r0u.x ? spvBitfieldInsert(vThreadGroupID.y, spvBitfieldUExtract(vThreadGroupID.x, 2u, 2u), 0u, 2u) : vThreadGroupID.y;
  r0u.x = r0u.x ? spvBitfieldInsert(vThreadGroupID.x, vThreadGroupID.y, 2u, 2u) : vThreadGroupID.x;
  r0u.z = vThreadIDInGroup.y * 16 + vThreadIDInGroup.x;
  r0u.w = r0u.z;
  r1i.xy = r0u.xy * 16 + vThreadIDInGroup.xy;
  r0.xy = float2(r0u.xy);
  r0.xy *= cb0[4].xy;
  r0.xy = r0.xy * float2(16,16) + cb0[7].xy;
  r0.xy = floor(r0.xy);
  r2i.xy = int2(r0.xy);
  r3u.zw = 0;
  while (true) {
    if (r0u.w >= 400) break;
    r5u.x = r0u.w % 20;
    r4u.x = r0u.w / 20;
    r5u.x = r2i.x + r5u.x;
    r5u.y = r2i.y + r4u.x;
    r2i.zw = r5u.xy - 1;
    r2i.zw = max(int2(0,0), r2i.zw);
    r3u.xy = min(asint(cb0[4].zw), r2i.zw);
    r4.xyz = t2.Load(r3u.xyw).xyz;
    r2.z = t0.Load(r3u.xyz).x;
#if 0 // Luma: remove pow 2.0 encoding and clamping, given that the tonemapper directly outputs linear now
    r4.xyz = r4.xyz * r4.xyz;
    r4.xyz = min(1.0, r4.xyz);
#endif
    r3.xy = float2(0.25,0.5) * r4.xy;
    r2.w = r3.x + r3.y;
    r5.x = r4.z * 0.25 + r2.w;
    r2.w = 0.5 * r4.z;
    r5.y = r4.z * 0.5 + -r2.w;
    r2.w = r4.z * -0.25 + r3.y;
    r5.z = -r4.z * 0.25 + r2.w;
    g0[r0u.w].val[0/4] = r5.x;
    g0[r0u.w].val[0/4+1] = r5.y;
    g0[r0u.w].val[0/4+2] = r5.z;
    g1[r0u.w].val[0/4] = r2.z;
    r0u.w += 256;
  }
  
  GroupMemoryBarrierWithGroupSync();

  if (asuint(r1i.x) < asuint(cb0[5].x) && asuint(r1i.y) < asuint(cb0[5].y)) {
    r0.zw = float2(r1i.xy);
    r2.zw = cb0[4].xy * r0.zw;
    r0.zw = r0.zw * cb0[4].xy + cb0[7].xy;
    r0.zw = float2(0.5,0.5) + r0.zw;
    r3.xy = floor(r0.zw);
    r0.xy = r3.xy - r0.xy;
    r0i.xy = (int2)r0.xy;
    r0i.xy = max(int2(0,0), r0i.xy);
    r0i.xy = min(int2(17,17), r0i.xy);
    r3.x = mad(r0i.y, 20, r0i.x);
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
    r0.xy = asfloat(r0u.xy + asint(r2i.xy));
    r0.xy = asfloat(asint(r6.xy) + asint(r0.xy));
    r0.xy = asfloat(max(int2(0,0), asfloat(r0.xy)));
    r7.xy = asfloat(min(asint(cb0[4].zw), asint(r0.xy)));
    r0.xy = cb0[4].xy * float2(0.5,0.5) + r2.zw;
    r6.xy = cb0[6].zw * r0.xy;
    r6.w = 1;
    r2.x = dot(cb0[0].xyzw, r6.xyzw);
    r2.y = dot(cb0[1].xyzw, r6.xyzw);
    r2.z = dot(cb0[3].xyzw, r6.xyzw);
    r2.xy = r2.xy / r2.zz;
    r7.zw = float2(0,0);
    r2.zw = t1.Load(asint(r7.xyz)).xy;
    r3.y = r2.z + r2.w;
    r3.yz = cmp(r3.yy < float2(1.89999998,-1.89999998));
    r0.xy = r0.xy * cb0[6].zw + r2.zw;
    r0.xy = r3.yy ? r0.xy : r2.xy;
    r2.xy = float2(-0.5,-0.5) + r0.xy;
    r2.xy = cmp(float2(0.5,0.5) < abs(r2.xy));
    r2.x = asfloat(asint(r2.y) | asint(r2.x));
    r2.x = asfloat(asint(r3.z) | asint(r2.x));
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
#if 1 // Luma: attempted support for HDR colors
    r4.xyz = r4.xyz * r0.zzz - r6.xyz;
    r4.xyz = sqrt(abs(r4.xyz)) * sign(r4.xyz);
#else
    r4.xyz = saturate(r4.xyz * r0.zzz - r6.xyz);
    r4.xyz = sqrt(r4.xyz);
    r4.xyz = max(0.002, r4.xyz);
#endif
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
#if 1
    r8.xyzw *= whiteRatio;
    r10.xyzw *= whiteRatio;
    r11.xyzw *= whiteRatio;
    r7.xyzw *= whiteRatio;
#endif
    r8.yz = r8.zy * r9.zz;
    r8.xy = r8.wx * r9.x + r8.yz;
    r8.xy = r10.wx * r6.x + r8.xy;
    r8.xy = r10.zy * r6.z + r8.xy;
    r0.w = r8.y * r9.w;
    r0.w = r8.x * r9.y + r0.w;
    r8.xy = r11.zy * r9.z;
    r8.xy = r11.wx * r9.x + r8.xy;
    r7.xw = r7.wx * r6.x + r8.xy;
    r6.xz = r7.zy * r6.z + r7.xw;
    r0.w = r6.x * r6.y + r0.w;
    r6.x = r6.z * r6.w + r0.w;
    r0.xy = t3.SampleLevel(s1_s, r0.xy, 0).xy;
    r6.yz = float2(0.5,0.5) * r0.xy;
    r0.xyz = -r3.xyz * r0.z + r6.xyz;
    r3.xyz = r4.xyz / abs(r0.xyz);
    r0.w = min(r3.y, r3.z);
    r0.w = min(r3.x, r0.w);
    r0.w = min(1.0, r0.w); // TODO: review. Use "whiteRatio" insteaD?
    r0.xyz = r0.xyz * r0.w + r5.xyz;
    r0.w = r2.x ? 0 : 0.9;
    r0.xyz = r0.xyz + -r2.yzw;
    r0.xyz = r0.w * r0.xyz + r2.yzw;
#if 1
    r0.x /= whiteRatio;
#endif
    u0[r1i.xy] = r0.x;
    u1[r1i.xy] = r0.yz * 2.0; // TODO: this is broken...
  }

#else

    bool _135 = (vThreadGroupID.y < cb0_m13.y) && (vThreadGroupID.x < cb0_m13.x);
    uint _139 = _135 ? spvBitfieldInsert(vThreadGroupID.x, vThreadGroupID.y, 2u, 2u) : vThreadGroupID.x;
    uint _140 = _135 ? spvBitfieldInsert(vThreadGroupID.y, spvBitfieldUExtract(vThreadGroupID.x, 2u, 2u), 0u, 2u) : vThreadGroupID.y;
    uint _146 = vThreadIDInGroup.x + (vThreadIDInGroup.y * 16u);
    uint _149 = (_139 * 16u) + vThreadIDInGroup.x;
    uint _150 = vThreadIDInGroup.y + (_140 * 16u);
    float _166 = floor(mad(float(_139) * cb0_m4.x, 16.0f, cb0_m10.x));
    float _167 = floor(mad(float(_140) * cb0_m4.y, 16.0f, cb0_m10.y));
    int _168 = cvt_f32_i32(_166);
    int _169 = cvt_f32_i32(_167);
    uint _172;
    uint _171 = _146;
    for (;;)
    {
        if (_171 >= 400u)
        {
            break;
        }
        uint2 _197 = uint2(uint(clamp((_168 + int(_171 % 20u)) - 1, 0, cb0_m5.x)), uint(clamp((int(_171 / 20u) + _169) - 1, 0, cb0_m5.y)));
        float4 _198 = t2.Load(int3(_197, 0u));
        float _199 = _198.x;
        float _200 = _198.y;
        float _201 = _198.z;
#if 0 // Luma: remove pow 2.0 encoding and clamping, given that the tonemapper directly outputs linear now
        _199 *= _199;
        _200 *= _200;
        _201 *= _201;
        float _208 = min(_199, 1.0f);
        float _210 = min(_201, 1.0f);
        float _212 = min(_200, 1.0f) * 0.5f;
#else
        float _208 = _199;
        float _210 = _201;
        float _212 = _200 * 0.5f;
#endif
        g0[_171]._m0 = mad(_210, 0.25f, _212 + (_208 * 0.25f));
        g0[_171]._m1 = (_208 * 0.5f) - (_210 * 0.5f);
        g0[_171]._m2 = mad(_210, -0.25f, _212 + (_208 * (-0.25f)));
        g1[_171] = t0.Load(int3(_197, 0u)).x;
        _172 = _171 + 256u;
        _171 = _172;
        continue;
    }
    GroupMemoryBarrierWithGroupSync();
    if ((cb0_m6.y > _150) && (_149 < cb0_m6.x))
    {
        float _239 = float(_149);
        float _240 = float(_150);
        float _245 = mad(_239, cb0_m4.x, cb0_m10.x) + 0.5f;
        float _246 = mad(_240, cb0_m4.y, cb0_m10.y) + 0.5f;
        int _253 = clamp(cvt_f32_i32(floor(_245) - _166), 0, 17);
        int _254 = clamp(cvt_f32_i32(floor(_246) - _167), 0, 17);
        int _256 = (_254 * 20) + _253;
        uint _257 = uint(_256);
        bool _260 = g1[_257] > 0.0f;
        float _261 = max(g1[_257], 0.0f);
        uint _263 = uint(_256 + 21);
        uint _265 = uint(_256 + 20);
        uint _267 = uint(_256 + 1);
        uint _269 = uint(_256 + 22);
        bool _272 = g1[_267] > _261;
        float _273 = _272 ? g1[_267] : _261;
        uint _278 = uint(_256 + 2);
        uint _280 = uint(_256 + 40);
        uint _282 = uint(_256 + 41);
        uint _284 = uint(_256 + 42);
        bool _287 = g1[_278] > _273;
        float _288 = _287 ? g1[_278] : _273;
        bool _292 = g1[_265] > _288;
        float _293 = _292 ? g1[_265] : _288;
        bool _298 = g1[_263] > _293;
        float _299 = _298 ? g1[_263] : _293;
        bool _301 = g1[_265] > _299;
        float _302 = _301 ? g1[_265] : _299;
        bool _306 = g1[_280] > _302;
        float _307 = _306 ? g1[_280] : _302;
        bool _310 = g1[_282] > _307;
        float _311 = _310 ? g1[_282] : _307;
        bool _315 = g1[_284] > _311;
        float _340 = (_239 * cb0_m4.x) + (cb0_m4.x * 0.5f);
        float _341 = (_240 * cb0_m4.y) + (cb0_m4.y * 0.5f);
        float4 _351 = float4(_340 * cb0_m9.x, cb0_m9.y * _341, _315 ? g1[_284] : _311, 1.0f);
        float _358 = dp4_f32(cb0_m3, _351);
        float2 _365 = t1.Load(int3(uint2(uint(clamp((_168 + _253) + (_315 ? 1 : (_310 ? 0 : (_306 ? (-1) : (_301 ? 1 : (_298 ? 0 : (_292 ? (-1) : (_287 ? 1 : ((_272 || (!_260)) ? 0 : (-1))))))))), 0, cb0_m5.x)), uint(clamp((_169 + _254) + ((_315 || (_306 || _310)) ? 1 : ((_301 || (_298 || (_292 || (!((_260 || _272) || _287))))) ? 0 : (-1))), 0, cb0_m5.y))), 0u));
        float _366 = _365.x;
        float _367 = _365.y;
        float _368 = _366 + _367;
        bool _369 = _368 < 1.89999997615814208984375f;
        float _373 = _369 ? mad(_340, cb0_m9.x, _366) : (dp4_f32(cb0_m0, _351) / _358);
        float _374 = _369 ? mad(cb0_m9.y, _341, _367) : (dp4_f32(cb0_m1, _351) / _358);
        float _392 = frac(_245);
        float _393 = frac(_246);
        float _400 = mad(_393 + 0.5f, -0.60000002384185791015625f, 1.0f);
        float _401 = mad(_392 + 0.5f, -0.60000002384185791015625f, 1.0f);
        float _404 = 1.0f - abs((_393 - 0.5f) * 0.60000002384185791015625f);
        float _405 = 1.0f - abs((_392 - 0.5f) * 0.60000002384185791015625f);
        float _408 = mad(_392 - 1.5f, 0.60000002384185791015625f, 1.0f);
        float _409 = mad(_393 - 1.5f, 0.60000002384185791015625f, 1.0f);
        float _423 = _400 * _401;
        float _425 = g0[_257]._m0 * _423;
        float _426 = g0[_257]._m1 * _423;
        float _427 = g0[_257]._m2 * _423;
        float _437 = _400 * _405;
        float _438 = _404 * _401;
        float _439 = g0[_267]._m0 * _437;
        float _440 = _437 * g0[_267]._m1;
        float _441 = g0[_267]._m2 * _437;
        float _463 = _400 * _408;
        float _464 = _409 * _401;
        float _492 = _404 * _405;
        float _511 = _404 * _408;
        float _512 = _409 * _405;
        float _567 = _408 * _409;
        float _571 = mad(_567, g0[_284]._m0, mad(g0[_282]._m0, _512, mad(_464, g0[_280]._m0, mad(g0[_269]._m0, _511, mad(_492, g0[_263]._m0, mad(_438, g0[_265]._m0, mad(_463, g0[_278]._m0, _425 + _439)))))));
        float _577 = 1.0f / ((_408 + (_405 + _401)) * ((_400 + _404) + _409));
        float _578 = _571 * _577;
        float _579 = _577 * mad(_567, g0[_284]._m1, mad(g0[_282]._m1, _512, mad(_464, g0[_280]._m1, mad(_511, g0[_269]._m1, mad(_492, g0[_263]._m1, mad(_438, g0[_265]._m1, mad(_463, g0[_278]._m1, _440 + _426)))))));
        float _580 = _577 * mad(_567, g0[_284]._m2, mad(_512, g0[_282]._m2, mad(g0[_280]._m2, _464, mad(_511, g0[_269]._m2, mad(g0[_263]._m2, _492, mad(g0[_265]._m2, _438, mad(_463, g0[_278]._m2, _441 + _427)))))));
        float _605 = floor(mad(cb0_m7.x, _373, -0.5f));
        float _606 = floor(mad(cb0_m7.y, _374, -0.5f));
        float _607 = _605 + 0.5f;
        float _608 = _606 + 0.5f;
        float _613 = _605 * cb0_m8.x;
        float _614 = _606 * cb0_m8.y;
        float _617 = (cb0_m8.x * 2.0f) + _613;
        float _618 = (cb0_m8.y * 2.0f) + _614;
        float _620 = mad(cb0_m7.x, _373, -_607);
        float _622 = mad(cb0_m7.y, _374, -_608);
        float _623 = _620 * _620;
        float _624 = _622 * _622;
        float _625 = _620 * _623;
        float _626 = _624 * _622;
        float _635 = mad(mad(-cb0_m7.x, _373, _607), 0.5f, _623 + (_625 * (-0.5f)));
        float _645 = ((_625 * 1.5f) - (_623 * 2.5f)) + 1.0f;
        float _653 = mad(_620, 0.5f, (_625 * (-1.5f)) + (_623 * 2.0f));
        float _657 = (_625 * 0.5f) - (_623 * 0.5f);
        float4 _664 = t4.GatherRed(s1_s, float2(_613, _614));
        float4 _671 = t4.GatherRed(s1_s, float2(_617, _614));
        float4 _678 = t4.GatherRed(s1_s, float2(_613, _618));
        float4 _685 = t4.GatherRed(s1_s, float2(_617, _618));
#if 1
        _664.xyzw *= whiteRatio;
        _671.xyzw *= whiteRatio;
        _678.xyzw *= whiteRatio;
        _685.xyzw *= whiteRatio;
#endif
        float2 _718 = t3.SampleLevel(s1_s, float2(_373, _374), 0.0f);
        float _724 = mad(-_571, _577, mad(mad(_657, _685.y, mad(_653, _685.x, (_635 * _678.x) + (_645 * _678.y))), (_626 * 0.5f) - (_624 * 0.5f), mad(mad(_622, 0.5f, (_624 * 2.0f) + (_626 * (-1.5f))), mad(_657, _685.z, mad(_653, _685.w, (_645 * _678.z) + (_635 * _678.w))), (mad(_657, _671.y, mad(_653, _671.x, (_635 * _664.x) + (_645 * _664.y))) * (((_626 * 1.5f) - (_624 * 2.5f)) + 1.0f)) + (mad(mad(-cb0_m7.y, _374, _608), 0.5f, (_626 * (-0.5f)) + _624) * mad(_657, _671.z, mad(_653, _671.w, (_645 * _664.z) + (_635 * _664.w)))))));
        float _725 = (_718.x * 0.5f) - _579;
        float _726 = (_718.y * 0.5f) - _580;
#if 1
        float3 preSquareRoot;
        preSquareRoot.x = ((mad(_567 * g0[_284]._m0, g0[_284]._m0, mad(g0[_282]._m0, g0[_282]._m0 * _512, mad(_464 * g0[_280]._m0, g0[_280]._m0, mad(g0[_269]._m0, g0[_269]._m0 * _511, mad(_492 * g0[_263]._m0, g0[_263]._m0, mad(_438 * g0[_265]._m0, g0[_265]._m0, mad(_463 * g0[_278]._m0, g0[_278]._m0, (g0[_267]._m0 * _439) + (g0[_257]._m0 * _425)))))))) * _577) - (_578 * _578));
        preSquareRoot.y = ((_577 * mad(_567 * g0[_284]._m2, g0[_284]._m2, mad(_512 * g0[_282]._m2, g0[_282]._m2, mad(g0[_280]._m2, g0[_280]._m2 * _464, mad(_511 * g0[_269]._m2, g0[_269]._m2, mad(g0[_263]._m2, g0[_263]._m2 * _492, mad(g0[_265]._m2, g0[_265]._m2 * _438, mad(_463 * g0[_278]._m2, g0[_278]._m2, (g0[_257]._m2 * _427) + (g0[_267]._m2 * _441))))))))) - (_580 * _580));
        preSquareRoot.z = ((_577 * mad(_567 * g0[_284]._m1, g0[_284]._m1, mad(g0[_282]._m1, g0[_282]._m1 * _512, mad(_464 * g0[_280]._m1, g0[_280]._m1, mad(_511 * g0[_269]._m1, g0[_269]._m1, mad(g0[_263]._m1, _492 * g0[_263]._m1, mad(_438 * g0[_265]._m1, g0[_265]._m1, mad(_463 * g0[_278]._m1, g0[_278]._m1, (g0[_257]._m1 * _426) + (_440 * g0[_267]._m1))))))))) - (_579 * _579));
        float3 newSquareRoot = sqrt(abs(preSquareRoot)) * sign(preSquareRoot);
        float _734 = min(newSquareRoot.x / abs(_724), min(newSquareRoot.y / abs(_726), newSquareRoot.z / abs(_725)));
#else
        float _734 = min(max(sqrt(clamp((mad(_567 * g0[_284]._m0, g0[_284]._m0, mad(g0[_282]._m0, g0[_282]._m0 * _512, mad(_464 * g0[_280]._m0, g0[_280]._m0, mad(g0[_269]._m0, g0[_269]._m0 * _511, mad(_492 * g0[_263]._m0, g0[_263]._m0, mad(_438 * g0[_265]._m0, g0[_265]._m0, mad(_463 * g0[_278]._m0, g0[_278]._m0, (g0[_267]._m0 * _439) + (g0[_257]._m0 * _425)))))))) * _577) - (_578 * _578), 0.0f, 1.0f)), 0.00200000009499490261077880859375f) / abs(_724), min(max(sqrt(clamp((_577 * mad(_567 * g0[_284]._m2, g0[_284]._m2, mad(_512 * g0[_282]._m2, g0[_282]._m2, mad(g0[_280]._m2, g0[_280]._m2 * _464, mad(_511 * g0[_269]._m2, g0[_269]._m2, mad(g0[_263]._m2, g0[_263]._m2 * _492, mad(g0[_265]._m2, g0[_265]._m2 * _438, mad(_463 * g0[_278]._m2, g0[_278]._m2, (g0[_257]._m2 * _427) + (g0[_267]._m2 * _441))))))))) - (_580 * _580), 0.0f, 1.0f)), 0.00200000009499490261077880859375f) / abs(_726), max(sqrt(clamp((_577 * mad(_567 * g0[_284]._m1, g0[_284]._m1, mad(g0[_282]._m1, g0[_282]._m1 * _512, mad(_464 * g0[_280]._m1, g0[_280]._m1, mad(_511 * g0[_269]._m1, g0[_269]._m1, mad(g0[_263]._m1, _492 * g0[_263]._m1, mad(_438 * g0[_265]._m1, g0[_265]._m1, mad(_463 * g0[_278]._m1, g0[_278]._m1, (g0[_257]._m1 * _426) + (_440 * g0[_267]._m1))))))))) - (_579 * _579), 0.0f, 1.0f)), 0.00200000009499490261077880859375f) / abs(_725)));
#endif
        float _735 = min(_734, 1.0f);
        float _742 = (((abs(_373 - 0.5f) > 0.5f) || (abs(_374 - 0.5f) > 0.5f)) || (_368 < (-1.9f))) ? 0.0f : 0.9f;
        float _747 = mad(((_725 * _735) + _579) - g0[_263]._m1, _742, g0[_263]._m1);
        float _748 = mad(((_726 * _735) + _580) - g0[_263]._m2, _742, g0[_263]._m2);
        uint2 _750 = uint2(_149, _150);
        float finalY = mad((_578 + (_724 * _735)) - g0[_263]._m0, _742, g0[_263]._m0).x;
#if 1
        finalY /= whiteRatio;
#endif
        u0[_750] = finalY;
        float _752 = _747 + _747;
        u1[_750] = float2(_752, _748 + _748);
    }

#endif
}