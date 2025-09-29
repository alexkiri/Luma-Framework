#include "includes/Common.hlsl"

struct _36
{
    uint _m0;
    uint _m1;
    uint _m2;
    uint _m3;
};

static const _36 _655 = { 0u, 0u, 0u, 0u };
static const _36 _39[256] = { { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u }, { 0u, 0u, 0u, 0u } };

cbuffer cb0_buf : register(b0)
{
    uint4 cb0_m0 : packoffset(c0);
    uint4 cb0_m1 : packoffset(c1);
    uint4 cb0_m2 : packoffset(c2);
    uint4 cb0_m3 : packoffset(c3);
    uint4 cb0_m4 : packoffset(c4);
    uint4 cb0_m5 : packoffset(c5);
    uint4 cb0_m6 : packoffset(c6);
    uint4 cb0_m7 : packoffset(c7);
    uint4 cb0_m8 : packoffset(c8);
    uint4 cb0_m9 : packoffset(c9);
    uint4 cb0_m10 : packoffset(c10);
    uint4 cb0_m11 : packoffset(c11);
    uint4 cb0_m12 : packoffset(c12);
    uint4 cb0_m13 : packoffset(c13);
    uint4 cb0_m14 : packoffset(c14);
    uint2 cb0_m15 : packoffset(c15);
    uint2 cb0_m16 : packoffset(c15.z);
    uint4 cb0_m17 : packoffset(c16);
    uint4 cb0_m18 : packoffset(c17);
    float4 cb0_m19 : packoffset(c18);
    float4 cb0_m20 : packoffset(c19);
};

cbuffer cb1_buf : register(b1)
{
    uint4 cb1_m[58] : packoffset(c0);
};

cbuffer cb2_buf : register(b2)
{
    float3 cb2_m0 : packoffset(c0);
    float cb2_m1 : packoffset(c0.w);
    float4 cb2_m2 : packoffset(c1);
    float4 cb2_m3 : packoffset(c2);
    float4 cb2_m4 : packoffset(c3);
    float4 cb2_m5 : packoffset(c4);
};

Texture2D<float4> t0 : register(t0);
Texture2D<float4> t1 : register(t1);
RWTexture2D<float4> u0 : register(u0);
RWTexture2D<float4> u1 : register(u1);

static uint3 gl_WorkGroupID;
static uint3 gl_GlobalInvocationID;
static uint gl_LocalInvocationIndex;
struct SPIRV_Cross_Input
{
    uint3 gl_WorkGroupID : SV_GroupID;
    uint3 gl_GlobalInvocationID : SV_DispatchThreadID;
    uint gl_LocalInvocationIndex : SV_GroupIndex;
};

groupshared _36 g0[256];

float dp3_f32(float3 a, float3 b)
{
    precise float _118 = a.x * b.x;
    return mad(a.z, b.z, mad(a.y, b.y, _118));
}

float dp2_f32(float2 a, float2 b)
{
    precise float _106 = a.x * b.x;
    return mad(a.y, b.y, _106);
}

void comp_main()
{
    uint4 viewportSize;
    float resolutionScale;
    if (LumaData.GameData.DrewUpscaling) {
        viewportSize = LumaData.GameData.ViewportRect;
        resolutionScale = LumaData.GameData.ResolutionScale.y;
    }
    else {
        viewportSize = uint4(cb0_m15, cb0_m16); 
        resolutionScale = 1.0f;
    }
    uint _138 = gl_GlobalInvocationID.x * resolutionScale + viewportSize.x;
    uint _139 = gl_GlobalInvocationID.y * resolutionScale + viewportSize.y;
    uint2 _141 = uint2(_138, _139);
    float4 _142 = t0.Load(int3(_141, 0u));
    float _143 = _142.x;
    float4 _146 = t1.Load(int3(_141, 0u));
    float _147 = _146.x;
    float _160 = (float(gl_GlobalInvocationID.x) + 0.5f) * resolutionScale / float(viewportSize.z - viewportSize.x);
    float _161 = (float(gl_GlobalInvocationID.y) + 0.5f) * resolutionScale / float(viewportSize.w - viewportSize.y);
    float _172 = 1.0f / (cb2_m1 + dp3_f32(float3(_160, _161, _147), cb2_m0));
    float _223 = _172 * (mad(_147, cb2_m3.y, mad(_160 * _160, cb2_m3.x, (_160 * (((cb2_m2.x * _161) + (_147 * cb2_m2.y)) + cb2_m2.z)) + (cb2_m2.w * _161))) + cb2_m3.z);
    float _224 = _172 * (mad(_147, cb2_m5.y, mad(_161 * _161, cb2_m5.x, ((((_160 * cb2_m4.x) + (_147 * cb2_m4.y)) + cb2_m4.z) * _161) + (_160 * cb2_m4.w))) + cb2_m5.z);
    float _225 = _223 + _223;
    float _227 = _224 + _224;
    float2 _228 = float2(_143, _142.y);
    bool _230 = dp2_f32(_228, _228) > 0.0f;
    float _232 = _143 - 0.49999237060546875f;
    float _233 = _142.y - 0.49999237060546875f;
    float _241 = _230 ? (_232 * 4.008016109466552734375f) : (-_225);
    float _245 = cb0_m19.x * (_230 ? (_233 * 4.008016109466552734375f) : _227);
    float _246 = -_245;
    float _251 = max(abs(_241), 9.9999997473787516355514526367188e-05f);
    float _252 = max(abs(_245), 9.9999997473787516355514526367188e-05f);
    float _255 = min(_252, _251) / max(_252, _251);
    float _256 = _255 * _255;
    float _259 = mad(_256, mad(_256, mad(_256, -0.046496473252773284912109375f, 0.159314215183258056640625f), -0.32762277126312255859375f), 1.0f);
    float _260 = _255 * _259;
    bool _261 = _252 > _251;
    float _263 = mad(-_255, _259, 1.57079637050628662109375f);
    float _264 = _261 ? _263 : _260;
    bool _265 = _241 < 0.0f;
    float _266 = 3.1415927410125732421875f - _264;
    uint _276 = (_246 < 0.0f) ? asuint(-(_265 ? _266 : _264)) : (_265 ? asuint(_266) : (_261 ? asuint(_263) : asuint(_260)));
    float2 _277 = float2(_246, _241);
    float2 _279 = float2(-(cb0_m19.x * (_230 ? mad(_233, 4.008016109466552734375f, -_227) : 0.0f)), _230 ? mad(_232, 4.008016109466552734375f, _225) : 0.0f);
    float _281 = sqrt(dp2_f32(_277, _277));
    float _287 = mad(cb0_m20.w, min(_281, sqrt(dp2_f32(_279, _279))) - _281, _281);
    bool _290 = (viewportSize.z > _138) && (viewportSize.w > _139);
    if (_290)
    {
        u0[_141] = float4(_287, mad(_147, asfloat(cb1_m[57u].x), asfloat(cb1_m[57u].y)) + (1.0f / mad(_147, asfloat(cb1_m[57u].z), -asfloat(cb1_m[57u].w))), 0.0f, 0.0f);
    }
    float _319 = min(_287, cb0_m19.w / cb0_m19.y);
    uint _321 = asuint(_319);
    uint _322 = _290 ? _321 : 1073741824u;
    uint _324 = _290 ? _321 : 0u;
    g0[gl_LocalInvocationIndex]._m0 = _322;
    g0[gl_LocalInvocationIndex]._m1 = _276;
    g0[gl_LocalInvocationIndex]._m2 = _324;
    g0[gl_LocalInvocationIndex]._m3 = _276;
    GroupMemoryBarrierWithGroupSync();
    if (gl_LocalInvocationIndex < 128u)
    {
        uint _342 = gl_LocalInvocationIndex + 128u;
        uint _345 = g0[_342]._m0;
        uint _348 = g0[_342]._m1;
        uint _351 = g0[_342]._m2;
        uint _354 = g0[_342]._m3;
        bool _356 = asfloat(_345) > (_290 ? _319 : 2.0f);
        bool _360 = asfloat(_351) < (_290 ? _319 : 0.0f);
        g0[gl_LocalInvocationIndex]._m0 = _356 ? _322 : _345;
        g0[gl_LocalInvocationIndex]._m1 = _356 ? _276 : _348;
        g0[gl_LocalInvocationIndex]._m2 = _360 ? _324 : _351;
        g0[gl_LocalInvocationIndex]._m3 = _360 ? _276 : _354;
    }
    GroupMemoryBarrierWithGroupSync();
    if (gl_LocalInvocationIndex < 64u)
    {
        uint _370 = g0[gl_LocalInvocationIndex]._m0;
        uint _372 = g0[gl_LocalInvocationIndex]._m1;
        uint _374 = g0[gl_LocalInvocationIndex]._m2;
        uint _376 = g0[gl_LocalInvocationIndex]._m3;
        uint _377 = gl_LocalInvocationIndex + 64u;
        uint _380 = g0[_377]._m0;
        uint _383 = g0[_377]._m1;
        uint _386 = g0[_377]._m2;
        uint _389 = g0[_377]._m3;
        bool _392 = asfloat(_370) < asfloat(_380);
        bool _397 = asfloat(_386) < asfloat(_374);
        g0[gl_LocalInvocationIndex]._m0 = _392 ? _370 : _380;
        g0[gl_LocalInvocationIndex]._m1 = _392 ? _372 : _383;
        g0[gl_LocalInvocationIndex]._m2 = _397 ? _374 : _386;
        g0[gl_LocalInvocationIndex]._m3 = _397 ? _376 : _389;
    }
    GroupMemoryBarrierWithGroupSync();
    if (gl_LocalInvocationIndex < 32u)
    {
        uint _407 = g0[gl_LocalInvocationIndex]._m0;
        uint _409 = g0[gl_LocalInvocationIndex]._m1;
        uint _411 = g0[gl_LocalInvocationIndex]._m2;
        uint _413 = g0[gl_LocalInvocationIndex]._m3;
        uint _414 = gl_LocalInvocationIndex + 32u;
        uint _417 = g0[_414]._m0;
        uint _420 = g0[_414]._m1;
        uint _423 = g0[_414]._m2;
        uint _426 = g0[_414]._m3;
        bool _429 = asfloat(_407) < asfloat(_417);
        bool _434 = asfloat(_423) < asfloat(_411);
        g0[gl_LocalInvocationIndex]._m0 = _429 ? _407 : _417;
        g0[gl_LocalInvocationIndex]._m1 = _429 ? _409 : _420;
        g0[gl_LocalInvocationIndex]._m2 = _434 ? _411 : _423;
        g0[gl_LocalInvocationIndex]._m3 = _434 ? _413 : _426;
    }
    if (gl_LocalInvocationIndex < 16u)
    {
        uint _444 = g0[gl_LocalInvocationIndex]._m0;
        uint _446 = g0[gl_LocalInvocationIndex]._m1;
        uint _448 = g0[gl_LocalInvocationIndex]._m2;
        uint _450 = g0[gl_LocalInvocationIndex]._m3;
        uint _451 = gl_LocalInvocationIndex + 16u;
        uint _454 = g0[_451]._m0;
        uint _457 = g0[_451]._m1;
        uint _460 = g0[_451]._m2;
        uint _463 = g0[_451]._m3;
        bool _466 = asfloat(_444) < asfloat(_454);
        bool _471 = asfloat(_460) < asfloat(_448);
        g0[gl_LocalInvocationIndex]._m0 = _466 ? _444 : _454;
        g0[gl_LocalInvocationIndex]._m1 = _466 ? _446 : _457;
        g0[gl_LocalInvocationIndex]._m2 = _471 ? _448 : _460;
        g0[gl_LocalInvocationIndex]._m3 = _471 ? _450 : _463;
    }
    if (gl_LocalInvocationIndex < 8u)
    {
        uint _485 = g0[gl_LocalInvocationIndex]._m0;
        uint _487 = g0[gl_LocalInvocationIndex]._m1;
        uint _489 = g0[gl_LocalInvocationIndex]._m2;
        uint _491 = g0[gl_LocalInvocationIndex]._m3;
        uint _492 = gl_LocalInvocationIndex + 8u;
        uint _495 = g0[_492]._m0;
        uint _498 = g0[_492]._m1;
        uint _501 = g0[_492]._m2;
        uint _504 = g0[_492]._m3;
        bool _507 = asfloat(_485) < asfloat(_495);
        bool _512 = asfloat(_501) < asfloat(_489);
        g0[gl_LocalInvocationIndex]._m0 = _507 ? _485 : _495;
        g0[gl_LocalInvocationIndex]._m1 = _507 ? _487 : _498;
        g0[gl_LocalInvocationIndex]._m2 = _512 ? _489 : _501;
        g0[gl_LocalInvocationIndex]._m3 = _512 ? _491 : _504;
    }
    if (gl_LocalInvocationIndex < 4u)
    {
        uint _522 = g0[gl_LocalInvocationIndex]._m0;
        uint _524 = g0[gl_LocalInvocationIndex]._m1;
        uint _526 = g0[gl_LocalInvocationIndex]._m2;
        uint _528 = g0[gl_LocalInvocationIndex]._m3;
        uint _529 = gl_LocalInvocationIndex + 4u;
        uint _532 = g0[_529]._m0;
        uint _535 = g0[_529]._m1;
        uint _538 = g0[_529]._m2;
        uint _541 = g0[_529]._m3;
        bool _544 = asfloat(_522) < asfloat(_532);
        bool _549 = asfloat(_538) < asfloat(_526);
        g0[gl_LocalInvocationIndex]._m0 = _544 ? _522 : _532;
        g0[gl_LocalInvocationIndex]._m1 = _544 ? _524 : _535;
        g0[gl_LocalInvocationIndex]._m2 = _549 ? _526 : _538;
        g0[gl_LocalInvocationIndex]._m3 = _549 ? _528 : _541;
    }
    if (gl_LocalInvocationIndex < 2u)
    {
        uint _559 = g0[gl_LocalInvocationIndex]._m0;
        uint _561 = g0[gl_LocalInvocationIndex]._m1;
        uint _563 = g0[gl_LocalInvocationIndex]._m2;
        uint _565 = g0[gl_LocalInvocationIndex]._m3;
        uint _566 = gl_LocalInvocationIndex + 2u;
        uint _569 = g0[_566]._m0;
        uint _572 = g0[_566]._m1;
        uint _575 = g0[_566]._m2;
        uint _578 = g0[_566]._m3;
        bool _581 = asfloat(_559) < asfloat(_569);
        bool _586 = asfloat(_575) < asfloat(_563);
        g0[gl_LocalInvocationIndex]._m0 = _581 ? _559 : _569;
        g0[gl_LocalInvocationIndex]._m1 = _581 ? _561 : _572;
        g0[gl_LocalInvocationIndex]._m2 = _586 ? _563 : _575;
        g0[gl_LocalInvocationIndex]._m3 = _586 ? _565 : _578;
    }
    if (gl_LocalInvocationIndex < 1u)
    {
        uint _596 = g0[0u]._m0;
        uint _598 = g0[0u]._m1;
        uint _600 = g0[0u]._m2;
        uint _602 = g0[0u]._m3;
        uint _604 = g0[1u]._m0;
        uint _606 = g0[1u]._m1;
        uint _608 = g0[1u]._m2;
        uint _610 = g0[1u]._m3;
        bool _613 = asfloat(_596) < asfloat(_604);
        bool _618 = asfloat(_608) < asfloat(_600);
        g0[0u]._m0 = _613 ? _596 : _604;
        g0[0u]._m1 = _613 ? _598 : _606;
        g0[0u]._m2 = _618 ? _600 : _608;
        g0[0u]._m3 = _618 ? _602 : _610;
    }
    if (gl_LocalInvocationIndex == 0u)
    {
        float _636 = asfloat(g0[0u]._m1);
        float _639 = asfloat(g0[0u]._m0);
        float _642 = asfloat(g0[0u]._m3);
        float _645 = asfloat(g0[0u]._m2);
        u1[uint2(gl_WorkGroupID.x, gl_WorkGroupID.y)] = float4(cos(_636) * _639, sin(_636) * _639, cos(_642) * _645, sin(_642) * _645);
    }
}

[numthreads(16, 16, 1)]
void main(SPIRV_Cross_Input stage_input)
{
    gl_WorkGroupID = stage_input.gl_WorkGroupID;
    gl_GlobalInvocationID = stage_input.gl_GlobalInvocationID;
    gl_LocalInvocationIndex = stage_input.gl_LocalInvocationIndex;
    comp_main();
}
