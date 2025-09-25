#include "../Includes/Common.hlsl"

cbuffer cb1_buf : register(b1)
{
    float3 cb1_m0 : packoffset(c0);
    uint cb1_m1 : packoffset(c0.w);
};

cbuffer cb2_buf : register(b2)
{
    uint4 cb2_m[53] : packoffset(c0);
};

cbuffer cb3_buf : register(b3)
{
    float3 cb3_m0 : packoffset(c0);
    float cb3_m1 : packoffset(c0.w);
    float3 cb3_m2 : packoffset(c1);
    float cb3_m3 : packoffset(c1.w);
    float2 cb3_m4 : packoffset(c2);
    float2 cb3_m5 : packoffset(c2.z);
    float2 cb3_m6 : packoffset(c3);
    float2 cb3_m7 : packoffset(c3.z);
    float4 cb3_m8 : packoffset(c4);
};

cbuffer cb4_buf : register(b4)
{
    uint4 cb4_m[69] : packoffset(c0);
};

Texture2D<float4> t0 : register(t0);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t2 : register(t2);
TextureCube<float4> t3 : register(t3);
Texture2D<float4> t4 : register(t4);
Texture2D<float4> t5 : register(t5);
Texture2D<float4> t10 : register(t10);
Texture2D<float4> t11 : register(t11);
Texture2D<float4> t12 : register(t12);
Texture2D<float4> t13 : register(t13);
Texture2D<float4> t14 : register(t14);
Texture2D<float4> t15 : register(t15);

SamplerState s0 : register(s0);
SamplerState s1 : register(s1);
SamplerState s2 : register(s2);
SamplerState s3 : register(s3);
SamplerState s4 : register(s4);
SamplerState s5 : register(s5);
SamplerState s10 : register(s10);
SamplerState s11 : register(s11);
SamplerState s12 : register(s12);
SamplerState s13 : register(s13);
SamplerComparisonState s14 : register(s14);
SamplerState s15 : register(s15);

static float4 gl_FragCoord;
static float4 TEXCOORD;
static float3 TEXCOORD2;
static float3 TEXCOORD3;
static float3 TEXCOORD4;
static float4 TEXCOORD5;
static float4 TEXCOORD6;
static float4 SV_Target;

struct SPIRV_Cross_Input
{
    float4 TEXCOORD : TEXCOORD0;
    float3 TEXCOORD2 : TEXCOORD2;
    float3 TEXCOORD3 : TEXCOORD3;
    float3 TEXCOORD4 : TEXCOORD4;
    float4 TEXCOORD5 : TEXCOORD5;
    float4 TEXCOORD6 : TEXCOORD6;
    float4 gl_FragCoord : SV_Position;
};

struct SPIRV_Cross_Output
{
    float4 SV_Target : SV_Target0;
};

float dp3_f32(float3 a, float3 b)
{
    precise float _214 = a.x * b.x;
    return mad(a.z, b.z, mad(a.y, b.y, _214));
}

float dp2_f32(float2 a, float2 b)
{
    precise float _203 = a.x * b.x;
    return mad(a.y, b.y, _203);
}

float dp4_f32(float4 a, float4 b)
{
    precise float _185 = a.x * b.x;
    return mad(a.w, b.w, mad(a.z, b.z, mad(a.y, b.y, _185)));
}

// TODO: this is broken
void frag_main()
{
    float _238 = asfloat(cb2_m[10u].x);
    float _239 = asfloat(cb2_m[10u].y);
    float _240 = asfloat(cb2_m[10u].z);
    float _241 = _238 - TEXCOORD5.x;
    float _242 = _239 - TEXCOORD5.y;
    float _243 = _240 - TEXCOORD5.z;
    float3 _244 = float3(_241, _242, _243);
    float _246 = rsqrt(dp3_f32(_244, _244));
    float _247 = _241 * _246;
    float _248 = _246 * _242;
    float _249 = _246 * _243;
    float4 _267 = t1.Sample(s1, float2(TEXCOORD.x * cb3_m5.x, TEXCOORD.y * cb3_m5.y));
    float _272 = mad(_267.x, 2.0f, -1.0f);
    float _273 = mad(_267.y * _267.w, 2.0f, -1.0f);
    float2 _274 = float2(_272, _273);
    float _278 = sqrt(max(1.0f - dp2_f32(_274, _274), 0.0f));
    float _282 = 1.0f / cb3_m7.y;
    float _297 = cb3_m3 * (mad(-_282, clamp(cb3_m7.y - abs(_272), 0.0f, 1.0f), 1.0f) * _272);
    float _298 = cb3_m3 * (_273 * mad(-_282, clamp(cb3_m7.y - abs(_273), 0.0f, 1.0f), 1.0f));
    float _326 = mad(_278, TEXCOORD2.x, (TEXCOORD4.x * _298) + (_297 * TEXCOORD3.x));
    float _327 = mad(_278, TEXCOORD2.y, (_297 * TEXCOORD3.y) + (TEXCOORD4.y * _298));
    float _328 = mad(_278, TEXCOORD2.z, (_297 * TEXCOORD3.z) + (TEXCOORD4.z * _298));
    float3 _329 = float3(_326, _327, _328);
    float _331 = rsqrt(dp3_f32(_329, _329));
    float _332 = _326 * _331;
    float _333 = _331 * _327;
    float _334 = _331 * _328;
    float _1126;
    float _1127;
    float _1128;
    if (cb4_m[62u].x != 0u)
    {
        float _356 = asfloat(cb4_m[0u].x) - TEXCOORD5.x;
        float _357 = asfloat(cb4_m[0u].y) - TEXCOORD5.y;
        float _358 = asfloat(cb4_m[0u].z) - TEXCOORD5.z;
        float3 _359 = float3(_356, _357, _358);
        float _361 = rsqrt(dp3_f32(_359, _359));
        float3 _365 = float3(_356 * _361, _361 * _357, _361 * _358);
        float _366 = dp3_f32(_365, _359);
        float _391 = dp3_f32(_365, float3(-asfloat(cb4_m[1u].x), -asfloat(cb4_m[1u].y), -asfloat(cb4_m[1u].z)));
        bool _404 = (_366 * _391) < asfloat(cb4_m[3u].z);
        float4 _409 = t15.Sample(s15, float2(mad(_366, asfloat(cb4_m[2u].x), asfloat(cb4_m[2u].z)), mad(_366, asfloat(cb4_m[2u].y), asfloat(cb4_m[2u].w))));
        float _411 = clamp(mad(_391, asfloat(cb4_m[3u].x), asfloat(cb4_m[3u].y)), 0.0f, 1.0f) * _409.z;
        float _470 = asfloat(cb4_m[45u].z) + mad(TEXCOORD5.z, asfloat(cb4_m[44u].z), (TEXCOORD5.x * asfloat(cb4_m[42u].z)) + (TEXCOORD5.y * asfloat(cb4_m[43u].z)));
        float _471 = asfloat(cb4_m[45u].w) + mad(TEXCOORD5.z, asfloat(cb4_m[44u].w), (TEXCOORD5.y * asfloat(cb4_m[43u].w)) + (TEXCOORD5.x * asfloat(cb4_m[42u].w)));
        float _485 = dp3_f32(float3(TEXCOORD5.x - _238, TEXCOORD5.y - _239, TEXCOORD5.z - _240), float3(asfloat(cb2_m[11u].x), asfloat(cb2_m[11u].y), asfloat(cb2_m[11u].z)));
        float _561;
        if (asfloat(cb4_m[0u].w) != 0.0f)
        {
            _561 = dp4_f32(t10.Sample(s10, float2(mad(gl_FragCoord.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x)), mad(gl_FragCoord.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y)))), float4(asfloat(cb4_m[5u].x), asfloat(cb4_m[5u].y), asfloat(cb4_m[5u].z), asfloat(cb4_m[5u].w)));
        }
        else
        {
            float _536 = (mad(TEXCOORD5.z, asfloat(cb4_m[44u].x), (TEXCOORD5.y * asfloat(cb4_m[43u].x)) + (TEXCOORD5.x * asfloat(cb4_m[42u].x))) + asfloat(cb4_m[45u].x)) / _471;
            float _537 = (asfloat(cb4_m[45u].y) + mad(TEXCOORD5.z, asfloat(cb4_m[44u].y), (TEXCOORD5.x * asfloat(cb4_m[42u].y)) + (TEXCOORD5.y * asfloat(cb4_m[43u].y)))) / _471;
            float _538 = _536 - 0.0001220703125f;
            float _539 = _537 + 0.00016276042151730507612228393554688f;
            float _545 = _536 + 0.0001220703125f;
            float _550 = _537 - 0.00016276042151730507612228393554688f;
            _561 = mad(clamp(mad(_485, asfloat(cb4_m[5u].x), asfloat(cb4_m[5u].z)), 0.0f, 1.0f) * (((t14.SampleCmpLevelZero(s14, float2(_538, _539), _470) + t14.SampleCmpLevelZero(s14, float2(_545, _539), _470)) + t14.SampleCmpLevelZero(s14, float2(_538, _550), _470)) + t14.SampleCmpLevelZero(s14, float2(_545, _550), _470)), 0.25f, clamp(mad(_485, asfloat(cb4_m[5u].y), asfloat(cb4_m[5u].w)), 0.0f, 1.0f));
        }
        float4 _573 = float4(TEXCOORD5.x, TEXCOORD5.y, TEXCOORD5.z, 1.0f);
        float4 _591 = t12.Sample(s12, float2(dp4_f32(float4(asfloat(cb4_m[54u].x), asfloat(cb4_m[54u].y), asfloat(cb4_m[54u].z), asfloat(cb4_m[54u].w)), _573), dp4_f32(float4(asfloat(cb4_m[55u].x), asfloat(cb4_m[55u].y), asfloat(cb4_m[55u].z), asfloat(cb4_m[55u].w)), _573)));
        float3 _595 = float3(_332, _333, _334);
        float _597 = clamp(dp3_f32(_365, _595), 0.0f, 1.0f);
        float _618 = _404 ? 0.0f : (_411 * (((_597 * asfloat(cb4_m[4u].x)) * _591.x) * _561));
        float _619 = _404 ? 0.0f : (_411 * (((_597 * asfloat(cb4_m[4u].y)) * _591.y) * _561));
        float _620 = _404 ? 0.0f : (_411 * (((_597 * asfloat(cb4_m[4u].z)) * _591.z) * _561));
        float _1123;
        float _1124;
        float _1125;
        if (cb4_m[63u].x != 0u)
        {
            float _638 = asfloat(cb4_m[6u].x) - TEXCOORD5.x;
            float _639 = asfloat(cb4_m[6u].y) - TEXCOORD5.y;
            float _640 = asfloat(cb4_m[6u].z) - TEXCOORD5.z;
            float3 _641 = float3(_638, _639, _640);
            float _643 = rsqrt(dp3_f32(_641, _641));
            float3 _647 = float3(_638 * _643, _643 * _639, _643 * _640);
            float _648 = dp3_f32(_647, _641);
            float _673 = dp3_f32(_647, float3(-asfloat(cb4_m[7u].x), -asfloat(cb4_m[7u].y), -asfloat(cb4_m[7u].z)));
            bool _686 = (_648 * _673) < asfloat(cb4_m[9u].z);
            float4 _689 = t15.Sample(s15, float2(mad(_648, asfloat(cb4_m[8u].x), asfloat(cb4_m[8u].z)), mad(_648, asfloat(cb4_m[8u].y), asfloat(cb4_m[8u].w))));
            float _691 = clamp(mad(_673, asfloat(cb4_m[9u].x), asfloat(cb4_m[9u].y)), 0.0f, 1.0f) * _689.z;
            float _750 = asfloat(cb4_m[49u].z) + mad(TEXCOORD5.z, asfloat(cb4_m[48u].z), (TEXCOORD5.x * asfloat(cb4_m[46u].z)) + (TEXCOORD5.y * asfloat(cb4_m[47u].z)));
            float _751 = asfloat(cb4_m[49u].w) + mad(TEXCOORD5.z, asfloat(cb4_m[48u].w), (TEXCOORD5.x * asfloat(cb4_m[46u].w)) + (TEXCOORD5.y * asfloat(cb4_m[47u].w)));
            float _827;
            if (asfloat(cb4_m[6u].w) != 0.0f)
            {
                _827 = dp4_f32(t10.Sample(s10, float2(mad(gl_FragCoord.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x)), mad(gl_FragCoord.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y)))), float4(asfloat(cb4_m[11u].x), asfloat(cb4_m[11u].y), asfloat(cb4_m[11u].z), asfloat(cb4_m[11u].w)));
            }
            else
            {
                float _802 = (mad(TEXCOORD5.z, asfloat(cb4_m[48u].x), (TEXCOORD5.y * asfloat(cb4_m[47u].x)) + (TEXCOORD5.x * asfloat(cb4_m[46u].x))) + asfloat(cb4_m[49u].x)) / _751;
                float _803 = (asfloat(cb4_m[49u].y) + mad(TEXCOORD5.z, asfloat(cb4_m[48u].y), (TEXCOORD5.x * asfloat(cb4_m[46u].y)) + (TEXCOORD5.y * asfloat(cb4_m[47u].y)))) / _751;
                float _804 = _802 - 0.0001220703125f;
                float _805 = _803 + 0.00016276042151730507612228393554688f;
                float _811 = _802 + 0.0001220703125f;
                float _816 = _803 - 0.00016276042151730507612228393554688f;
                _827 = mad(clamp(mad(_485, asfloat(cb4_m[11u].x), asfloat(cb4_m[11u].z)), 0.0f, 1.0f) * (((t14.SampleCmpLevelZero(s14, float2(_804, _805), _750) + t14.SampleCmpLevelZero(s14, float2(_811, _805), _750)) + t14.SampleCmpLevelZero(s14, float2(_804, _816), _750)) + t14.SampleCmpLevelZero(s14, float2(_811, _816), _750)), 0.25f, clamp(mad(_485, asfloat(cb4_m[11u].y), asfloat(cb4_m[11u].w)), 0.0f, 1.0f));
            }
            float4 _856 = t13.Sample(s13, float2(dp4_f32(float4(asfloat(cb4_m[57u].x), asfloat(cb4_m[57u].y), asfloat(cb4_m[57u].z), asfloat(cb4_m[57u].w)), _573), dp4_f32(float4(asfloat(cb4_m[58u].x), asfloat(cb4_m[58u].y), asfloat(cb4_m[58u].z), asfloat(cb4_m[58u].w)), _573)));
            float _861 = clamp(dp3_f32(_647, _595), 0.0f, 1.0f);
            float _885 = _618 + (_686 ? 0.0f : (_691 * (((_861 * asfloat(cb4_m[10u].x)) * _856.x) * _827)));
            float _886 = _619 + (_686 ? 0.0f : (_691 * (_827 * (_856.y * (_861 * asfloat(cb4_m[10u].y))))));
            float _887 = _620 + (_686 ? 0.0f : (_691 * (_827 * (_856.z * (_861 * asfloat(cb4_m[10u].z))))));
            float _1120;
            float _1121;
            float _1122;
            if (cb4_m[64u].x != 0u)
            {
                float _905 = asfloat(cb4_m[12u].x) - TEXCOORD5.x;
                float _906 = asfloat(cb4_m[12u].y) - TEXCOORD5.y;
                float _907 = asfloat(cb4_m[12u].z) - TEXCOORD5.z;
                float3 _908 = float3(_905, _906, _907);
                float _910 = rsqrt(dp3_f32(_908, _908));
                float3 _914 = float3(_905 * _910, _910 * _906, _910 * _907);
                float _915 = dp3_f32(_914, _908);
                float _940 = dp3_f32(_914, float3(-asfloat(cb4_m[13u].x), -asfloat(cb4_m[13u].y), -asfloat(cb4_m[13u].z)));
                bool _953 = (_915 * _940) < asfloat(cb4_m[15u].z);
                float4 _956 = t15.Sample(s15, float2(mad(_915, asfloat(cb4_m[14u].x), asfloat(cb4_m[14u].z)), mad(_915, asfloat(cb4_m[14u].y), asfloat(cb4_m[14u].w))));
                float _958 = clamp(mad(_940, asfloat(cb4_m[15u].x), asfloat(cb4_m[15u].y)), 0.0f, 1.0f) * _956.z;
                float _1017 = asfloat(cb4_m[53u].z) + mad(TEXCOORD5.z, asfloat(cb4_m[52u].z), (TEXCOORD5.x * asfloat(cb4_m[50u].z)) + (TEXCOORD5.y * asfloat(cb4_m[51u].z)));
                float _1018 = asfloat(cb4_m[53u].w) + mad(TEXCOORD5.z, asfloat(cb4_m[52u].w), (TEXCOORD5.x * asfloat(cb4_m[50u].w)) + (TEXCOORD5.y * asfloat(cb4_m[51u].w)));
                float _1094;
                if (asfloat(cb4_m[12u].w) != 0.0f)
                {
                    _1094 = dp4_f32(t10.Sample(s10, float2(mad(gl_FragCoord.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x)), mad(gl_FragCoord.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y)))), float4(asfloat(cb4_m[17u].x), asfloat(cb4_m[17u].y), asfloat(cb4_m[17u].z), asfloat(cb4_m[17u].w)));
                }
                else
                {
                    float _1069 = (mad(TEXCOORD5.z, asfloat(cb4_m[52u].x), (TEXCOORD5.y * asfloat(cb4_m[51u].x)) + (TEXCOORD5.x * asfloat(cb4_m[50u].x))) + asfloat(cb4_m[53u].x)) / _1018;
                    float _1070 = (asfloat(cb4_m[53u].y) + mad(TEXCOORD5.z, asfloat(cb4_m[52u].y), (TEXCOORD5.x * asfloat(cb4_m[50u].y)) + (TEXCOORD5.y * asfloat(cb4_m[51u].y)))) / _1018;
                    float _1071 = _1069 - 0.0001220703125f;
                    float _1072 = _1070 + 0.00016276042151730507612228393554688f;
                    float _1078 = _1069 + 0.0001220703125f;
                    float _1083 = _1070 - 0.00016276042151730507612228393554688f;
                    _1094 = mad(clamp(mad(_485, asfloat(cb4_m[17u].x), asfloat(cb4_m[17u].z)), 0.0f, 1.0f) * (((t14.SampleCmpLevelZero(s14, float2(_1071, _1072), _1017) + t14.SampleCmpLevelZero(s14, float2(_1078, _1072), _1017)) + t14.SampleCmpLevelZero(s14, float2(_1071, _1083), _1017)) + t14.SampleCmpLevelZero(s14, float2(_1078, _1083), _1017)), 0.25f, clamp(mad(_485, asfloat(cb4_m[17u].y), asfloat(cb4_m[17u].w)), 0.0f, 1.0f));
                }
                float _1096 = clamp(dp3_f32(_914, _595), 0.0f, 1.0f);
                _1120 = (_953 ? 0.0f : (_958 * ((_1096 * asfloat(cb4_m[16u].z)) * _1094))) + _887;
                _1121 = (_953 ? 0.0f : (_958 * ((_1096 * asfloat(cb4_m[16u].y)) * _1094))) + _886;
                _1122 = _885 + (_953 ? 0.0f : (_958 * ((_1096 * asfloat(cb4_m[16u].x)) * _1094)));
            }
            else
            {
                _1120 = _887;
                _1121 = _886;
                _1122 = _885;
            }
            _1123 = _1120;
            _1124 = _1121;
            _1125 = _1122;
        }
        else
        {
            _1123 = _620;
            _1124 = _619;
            _1125 = _618;
        }
        _1126 = _1123;
        _1127 = _1124;
        _1128 = _1125;
    }
    else
    {
        _1126 = 0.0f;
        _1127 = 0.0f;
        _1128 = 0.0f;
    }
    float _1405;
    float _1406;
    float _1407;
    if (cb4_m[65u].x != 0u)
    {
        float _1142 = asfloat(cb4_m[18u].x) - TEXCOORD5.x;
        float _1143 = asfloat(cb4_m[18u].y) - TEXCOORD5.y;
        float _1144 = asfloat(cb4_m[18u].z) - TEXCOORD5.z;
        float3 _1145 = float3(_1142, _1143, _1144);
        float _1147 = rsqrt(dp3_f32(_1145, _1145));
        float3 _1151 = float3(_1142 * _1147, _1147 * _1143, _1147 * _1144);
        float _1152 = dp3_f32(_1151, _1145);
        float _1177 = dp3_f32(_1151, float3(-asfloat(cb4_m[19u].x), -asfloat(cb4_m[19u].y), -asfloat(cb4_m[19u].z)));
        bool _1190 = (_1152 * _1177) < asfloat(cb4_m[21u].z);
        float4 _1195 = t15.Sample(s15, float2(mad(_1152, asfloat(cb4_m[20u].x), asfloat(cb4_m[20u].z)), mad(_1152, asfloat(cb4_m[20u].y), asfloat(cb4_m[20u].w))));
        float _1197 = clamp(mad(_1177, asfloat(cb4_m[21u].x), asfloat(cb4_m[21u].y)), 0.0f, 1.0f) * _1195.z;
        float3 _1198 = float3(_332, _333, _334);
        float _1200 = clamp(dp3_f32(_1151, _1198), 0.0f, 1.0f);
        float _1218 = _1128 + (_1190 ? 0.0f : ((_1200 * asfloat(cb4_m[22u].x)) * _1197));
        float _1219 = _1127 + (_1190 ? 0.0f : (_1197 * (_1200 * asfloat(cb4_m[22u].y))));
        float _1220 = _1126 + (_1190 ? 0.0f : (_1197 * (_1200 * asfloat(cb4_m[22u].z))));
        float _1402;
        float _1403;
        float _1404;
        if (cb4_m[66u].x != 0u)
        {
            float _1234 = asfloat(cb4_m[24u].x) - TEXCOORD5.x;
            float _1235 = asfloat(cb4_m[24u].y) - TEXCOORD5.y;
            float _1236 = asfloat(cb4_m[24u].z) - TEXCOORD5.z;
            float3 _1237 = float3(_1234, _1235, _1236);
            float _1239 = rsqrt(dp3_f32(_1237, _1237));
            float3 _1243 = float3(_1234 * _1239, _1239 * _1235, _1239 * _1236);
            float _1244 = dp3_f32(_1243, _1237);
            float _1269 = dp3_f32(_1243, float3(-asfloat(cb4_m[25u].x), -asfloat(cb4_m[25u].y), -asfloat(cb4_m[25u].z)));
            bool _1282 = (_1244 * _1269) < asfloat(cb4_m[27u].z);
            float4 _1285 = t15.Sample(s15, float2(mad(_1244, asfloat(cb4_m[26u].x), asfloat(cb4_m[26u].z)), mad(_1244, asfloat(cb4_m[26u].y), asfloat(cb4_m[26u].w))));
            float _1287 = clamp(mad(_1269, asfloat(cb4_m[27u].x), asfloat(cb4_m[27u].y)), 0.0f, 1.0f) * _1285.z;
            float _1289 = clamp(dp3_f32(_1243, _1198), 0.0f, 1.0f);
            float _1307 = _1218 + (_1282 ? 0.0f : ((_1289 * asfloat(cb4_m[28u].x)) * _1287));
            float _1308 = _1219 + (_1282 ? 0.0f : (_1287 * (_1289 * asfloat(cb4_m[28u].y))));
            float _1309 = _1220 + (_1282 ? 0.0f : (_1287 * (_1289 * asfloat(cb4_m[28u].z))));
            float _1399;
            float _1400;
            float _1401;
            if (cb4_m[67u].x != 0u)
            {
                float _1323 = asfloat(cb4_m[30u].x) - TEXCOORD5.x;
                float _1324 = asfloat(cb4_m[30u].y) - TEXCOORD5.y;
                float _1325 = asfloat(cb4_m[30u].z) - TEXCOORD5.z;
                float3 _1326 = float3(_1323, _1324, _1325);
                float _1328 = rsqrt(dp3_f32(_1326, _1326));
                float3 _1332 = float3(_1323 * _1328, _1328 * _1324, _1328 * _1325);
                float _1333 = dp3_f32(_1332, _1326);
                float _1358 = dp3_f32(_1332, float3(-asfloat(cb4_m[31u].x), -asfloat(cb4_m[31u].y), -asfloat(cb4_m[31u].z)));
                bool _1371 = (_1333 * _1358) < asfloat(cb4_m[33u].z);
                float _1376 = clamp(mad(_1358, asfloat(cb4_m[33u].x), asfloat(cb4_m[33u].y)), 0.0f, 1.0f) * t15.Sample(s15, float2(mad(_1333, asfloat(cb4_m[32u].x), asfloat(cb4_m[32u].z)), mad(_1333, asfloat(cb4_m[32u].y), asfloat(cb4_m[32u].w)))).z;
                float _1378 = clamp(dp3_f32(_1332, _1198), 0.0f, 1.0f);
                _1399 = _1309 + (_1371 ? 0.0f : (_1376 * (_1378 * asfloat(cb4_m[34u].z))));
                _1400 = _1308 + (_1371 ? 0.0f : (_1376 * (_1378 * asfloat(cb4_m[34u].y))));
                _1401 = _1307 + (_1371 ? 0.0f : ((_1378 * asfloat(cb4_m[34u].x)) * _1376));
            }
            else
            {
                _1399 = _1309;
                _1400 = _1308;
                _1401 = _1307;
            }
            _1402 = _1399;
            _1403 = _1400;
            _1404 = _1401;
        }
        else
        {
            _1402 = _1220;
            _1403 = _1219;
            _1404 = _1218;
        }
        _1405 = _1402;
        _1406 = _1403;
        _1407 = _1404;
    }
    else
    {
        _1405 = _1126;
        _1406 = _1127;
        _1407 = _1128;
    }
    float _1633;
    float _1634;
    float _1635;
    if (cb4_m[68u].x != 0u)
    {
        bool _1429 = TEXCOORD6.w < asfloat(cb2_m[52u].y);
        bool _1430 = TEXCOORD6.w < asfloat(cb2_m[52u].z);
        bool _1431 = TEXCOORD6.w < asfloat(cb2_m[52u].w);
        float _1505 = mad(TEXCOORD6.x, _1431 ? asfloat(cb2_m[50u].x) : (_1430 ? asfloat(cb2_m[48u].x) : (_1429 ? asfloat(cb2_m[46u].x) : 1.0f)), _1431 ? asfloat(cb2_m[51u].x) : (_1430 ? asfloat(cb2_m[49u].x) : (_1429 ? asfloat(cb2_m[47u].x) : 0.0f)));
        float _1506 = mad(TEXCOORD6.y, _1431 ? asfloat(cb2_m[50u].y) : (_1430 ? asfloat(cb2_m[48u].y) : (_1429 ? asfloat(cb2_m[46u].y) : 1.0f)), _1431 ? asfloat(cb2_m[51u].y) : (_1430 ? asfloat(cb2_m[49u].y) : (_1429 ? asfloat(cb2_m[47u].y) : 0.0f)));
        float _1507 = mad(TEXCOORD6.z, _1431 ? asfloat(cb2_m[50u].z) : (_1430 ? asfloat(cb2_m[48u].z) : (_1429 ? asfloat(cb2_m[46u].z) : 1.0f)), _1431 ? asfloat(cb2_m[51u].z) : (_1430 ? asfloat(cb2_m[49u].z) : (_1429 ? asfloat(cb2_m[47u].z) : 0.0f)));
        float _1566;
        if (asfloat(cb4_m[36u].w) != 0.0f)
        {
            _1566 = dp4_f32(t10.Sample(s10, float2(mad(gl_FragCoord.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x)), mad(gl_FragCoord.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y)))), float4(asfloat(cb4_m[41u].x), asfloat(cb4_m[41u].y), asfloat(cb4_m[41u].z), asfloat(cb4_m[41u].w)));
        }
        else
        {
            float _1544 = _1505 - 0.0001220703125f;
            float _1545 = _1506 + 0.00016276042151730507612228393554688f;
            float _1551 = _1505 + 0.0001220703125f;
            float _1556 = _1506 - 0.00016276042151730507612228393554688f;
            _1566 = (((t14.SampleCmpLevelZero(s14, float2(_1544, _1545), _1507) + t14.SampleCmpLevelZero(s14, float2(_1551, _1545), _1507)) + t14.SampleCmpLevelZero(s14, float2(_1544, _1556), _1507)) + t14.SampleCmpLevelZero(s14, float2(_1551, _1556), _1507)) * 0.25f;
        }
        float _1567 = (TEXCOORD6.w < asfloat(cb2_m[52u].x)) ? _1566 : 1.0f;
        float4 _1579 = float4(TEXCOORD5.x, TEXCOORD5.y, TEXCOORD5.z, 1.0f);
        float4 _1597 = t11.Sample(s11, float2(dp4_f32(float4(asfloat(cb4_m[60u].x), asfloat(cb4_m[60u].y), asfloat(cb4_m[60u].z), asfloat(cb4_m[60u].w)), _1579), dp4_f32(float4(asfloat(cb4_m[61u].x), asfloat(cb4_m[61u].y), asfloat(cb4_m[61u].z), asfloat(cb4_m[61u].w)), _1579)));
        float _1615 = clamp(dp3_f32(float3(-asfloat(cb4_m[37u].x), -asfloat(cb4_m[37u].y), -asfloat(cb4_m[37u].z)), float3(_332, _333, _334)), 0.0f, 1.0f);
        _1633 = mad(_1567, (_1615 * asfloat(cb4_m[40u].z)) * _1597.z, _1405);
        _1634 = mad(_1567, (_1615 * asfloat(cb4_m[40u].y)) * _1597.y, _1406);
        _1635 = mad(_1567, _1597.x * (_1615 * asfloat(cb4_m[40u].x)), _1407);
    }
    else
    {
        _1633 = _1405;
        _1634 = _1406;
        _1635 = _1407;
    }
    float3 _1636 = float3(_332, _333, _334);
    float _1638 = mad(dp3_f32(_1636, float3(0.25f, 0.25f, 1.0f)), 0.5f, 0.5f);
    float _1652 = asfloat(cb2_m[28u].x);
    float _1653 = asfloat(cb2_m[28u].y);
    float _1654 = asfloat(cb2_m[28u].z);
    float4 _1671 = t5.Sample(s5, float2(TEXCOORD.x * cb3_m4.x, TEXCOORD.y * cb3_m4.y));
    float4 _1685 = t0.Sample(s0, float2(TEXCOORD.x * cb3_m6.x, TEXCOORD.y * cb3_m6.y));
    float _1712 = mad(gl_FragCoord.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x));
    float _1713 = mad(gl_FragCoord.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y));
    float4 _1718 = t4.Sample(s4, float2(_1712, _1713));
    float _1726 = dp3_f32(_1636, float3(_247, _248, _249));
    float _1734 = min(exp2(cb3_m1 * log2(clamp(1.0f - _1726, 0.0f, 1.0f))), 1.0f);
    float _1735 = _1726 + _1726;
    float4 _1747 = t3.Sample(s3, float3((_332 * _1735) - _247, (_333 * _1735) - _248, (_334 * _1735) - _249));
    float _1772 = asfloat(cb2_m[33u].x);
    float _1775 = cb3_m7.x * _1772;
    float _1776 = mad(_1772, 0.4000000059604644775390625f, 1.0f);
    float _1777 = mad(_1718.x, 2.0f, _1635) * _1776;
    float _1778 = mad(_1718.y, 2.0f, _1634) * _1776;
    float _1779 = mad(_1718.z, 2.0f, _1633) * _1776;
    float _1787 = mad(-cb3_m7.x, _1772, 1.0f);
    float _1797 = _1777 + (mad(_1638, asfloat(cb2_m[27u].x) - _1652, _1652) * mad(-_1777, _1772, 1.0f));
    float _1798 = (mad(-_1778, _1772, 1.0f) * mad(asfloat(cb2_m[27u].y) - _1653, _1638, _1653)) + _1778;
    float _1799 = (mad(-_1779, _1772, 1.0f) * mad(asfloat(cb2_m[27u].z) - _1654, _1638, _1654)) + _1779;
    float _1809 = ((_1734 * (_1671.x * (cb3_m0.x * (cb3_m8.y * _1747.x)))) * _1797) + ((_1775 + ((cb3_m2.x * _1685.x) * _1787)) * _1797);
    float _1810 = (_1798 * (((cb3_m2.y * _1685.y) * _1787) + _1775)) + (_1798 * ((((cb3_m8.y * _1747.y) * cb3_m0.y) * _1671.y) * _1734));
    float _1811 = (_1799 * (((cb3_m2.z * _1685.z) * _1787) + _1775)) + (_1799 * ((((cb3_m8.y * _1747.z) * cb3_m0.z) * _1671.z) * _1734));
#if 0 // Luma: removed saturates
    _1809 = saturate(_1809);
    _1810 = saturate(_1810);
    _1811 = saturate(_1811);
#endif
    float _1814 = asfloat(cb2_m[43u].x);
    float4 _1821 = t2.Sample(s2, float2(_1712 * _1814, _1713 * _1814));
    float _1822 = _1821.w;
#if 1 // Luma: fixed BT.601 luminance
    float _1830 = GetLuminance(float3(_1809, _1810, _1811));
#else
    float _1830 = dp3_f32(float3(_1809, _1810, _1811), float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
#endif
    SV_Target.w = (cb3_m8.x * _1772) * (_1830 * _1830);
    float _1841 = clamp(TEXCOORD5.w, 0.0f, 1.0f) * asfloat(cb2_m[29u].x);
    SV_Target.x = (_1809 * _1822) + (_1841 * mad(-_1809, _1822, cb1_m0.x));
    SV_Target.y = (mad(-_1810, _1822, cb1_m0.y) * _1841) + (_1810 * _1822);
    SV_Target.z = (mad(-_1811, _1822, cb1_m0.z) * _1841) + (_1811 * _1822);
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    gl_FragCoord = stage_input.gl_FragCoord;
    gl_FragCoord.w = 1.0 / gl_FragCoord.w;
    TEXCOORD = stage_input.TEXCOORD;
    TEXCOORD2 = stage_input.TEXCOORD2;
    TEXCOORD3 = stage_input.TEXCOORD3;
    TEXCOORD4 = stage_input.TEXCOORD4;
    TEXCOORD5 = stage_input.TEXCOORD5;
    TEXCOORD6 = stage_input.TEXCOORD6;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.SV_Target = SV_Target;
    return stage_output;
}
