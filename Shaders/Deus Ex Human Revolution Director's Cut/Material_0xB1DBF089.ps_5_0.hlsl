#include "../Includes/Common.hlsl"

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

float dp3_f32(float3 a, float3 b)
{
    precise float _213 = a.x * b.x;
    return mad(a.z, b.z, mad(a.y, b.y, _213));
}

float dp2_f32(float2 a, float2 b)
{
    precise float _202 = a.x * b.x;
    return mad(a.y, b.y, _202);
}

float dp4_f32(float4 a, float4 b)
{
    precise float _184 = a.x * b.x;
    return mad(a.w, b.w, mad(a.z, b.z, mad(a.y, b.y, _184)));
}

void main(
    float4 v0 : SV_Position0,
    float4 v1 : TEXCOORD0,
    float3 v2 : TEXCOORD2,
    float3 v3 : TEXCOORD3,
    float3 v4 : TEXCOORD4,
    float4 v5 : TEXCOORD5,
    float4 v6 : TEXCOORD6,
    out float4 o0 : SV_Target0)
{
    float _237 = asfloat(cb2_m[10u].x);
    float _238 = asfloat(cb2_m[10u].y);
    float _239 = asfloat(cb2_m[10u].z);
    float _240 = _237 - v5.x;
    float _241 = _238 - v5.y;
    float _242 = _239 - v5.z;
    float3 _243 = float3(_240, _241, _242);
    float _245 = rsqrt(dp3_f32(_243, _243));
    float _246 = _240 * _245;
    float _247 = _245 * _241;
    float _248 = _245 * _242;
    float4 _266 = t1.Sample(s1, float2(v1.x * cb3_m5.x, v1.y * cb3_m5.y));
    float _271 = mad(_266.x, 2.0f, -1.0f);
    float _272 = mad(_266.y * _266.w, 2.0f, -1.0f);
    float2 _273 = float2(_271, _272);
    float _277 = sqrt(max(1.0f - dp2_f32(_273, _273), 0.0f));
    float _281 = 1.0f / cb3_m7.x;
    float _296 = cb3_m1 * (mad(-_281, saturate(cb3_m7.x - abs(_271)), 1.0f) * _271);
    float _297 = cb3_m1 * (_272 * mad(-_281, saturate(cb3_m7.x - abs(_272)), 1.0f));
    float _325 = mad(_277, v2.x, (v4.x * _297) + (_296 * v3.x));
    float _326 = mad(_277, v2.y, (_296 * v3.y) + (v4.y * _297));
    float _327 = mad(_277, v2.z, (_296 * v3.z) + (v4.z * _297));
    float3 _328 = float3(_325, _326, _327);
    float _330 = rsqrt(dp3_f32(_328, _328));
    float _331 = _325 * _330;
    float _332 = _330 * _326;
    float _333 = _330 * _327;
    float _1125;
    float _1126;
    float _1127;
    if (cb4_m[62u].x != 0u)
    {
        float _355 = asfloat(cb4_m[0u].x) - v5.x;
        float _356 = asfloat(cb4_m[0u].y) - v5.y;
        float _357 = asfloat(cb4_m[0u].z) - v5.z;
        float3 _358 = float3(_355, _356, _357);
        float _360 = rsqrt(dp3_f32(_358, _358));
        float3 _364 = float3(_355 * _360, _360 * _356, _360 * _357);
        float _365 = dp3_f32(_364, _358);
        float _390 = dp3_f32(_364, float3(-asfloat(cb4_m[1u].x), -asfloat(cb4_m[1u].y), -asfloat(cb4_m[1u].z)));
        bool _403 = (_365 * _390) < asfloat(cb4_m[3u].z);
        float4 _408 = t15.Sample(s15, float2(mad(_365, asfloat(cb4_m[2u].x), asfloat(cb4_m[2u].z)), mad(_365, asfloat(cb4_m[2u].y), asfloat(cb4_m[2u].w))));
        float _410 = saturate(mad(_390, asfloat(cb4_m[3u].x), asfloat(cb4_m[3u].y))) * _408.z;
        float _469 = asfloat(cb4_m[45u].z) + mad(v5.z, asfloat(cb4_m[44u].z), (v5.x * asfloat(cb4_m[42u].z)) + (v5.y * asfloat(cb4_m[43u].z)));
        float _470 = asfloat(cb4_m[45u].w) + mad(v5.z, asfloat(cb4_m[44u].w), (v5.y * asfloat(cb4_m[43u].w)) + (v5.x * asfloat(cb4_m[42u].w)));
        float _484 = dp3_f32(float3(v5.x - _237, v5.y - _238, v5.z - _239), float3(asfloat(cb2_m[11u].x), asfloat(cb2_m[11u].y), asfloat(cb2_m[11u].z)));
        float _560;
        if (asfloat(cb4_m[0u].w) != 0.0f)
        {
            _560 = dp4_f32(t10.Sample(s10, float2(mad(v0.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x)), mad(v0.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y)))), float4(asfloat(cb4_m[5u].x), asfloat(cb4_m[5u].y), asfloat(cb4_m[5u].z), asfloat(cb4_m[5u].w)));
        }
        else
        {
            float _535 = (mad(v5.z, asfloat(cb4_m[44u].x), (v5.y * asfloat(cb4_m[43u].x)) + (v5.x * asfloat(cb4_m[42u].x))) + asfloat(cb4_m[45u].x)) / _470;
            float _536 = (asfloat(cb4_m[45u].y) + mad(v5.z, asfloat(cb4_m[44u].y), (v5.x * asfloat(cb4_m[42u].y)) + (v5.y * asfloat(cb4_m[43u].y)))) / _470;
            float _537 = _535 - 0.0001220703125f;
            float _538 = _536 + 0.00016276042151730507612228393554688f;
            float _544 = _535 + 0.0001220703125f;
            float _549 = _536 - 0.00016276042151730507612228393554688f;
            _560 = mad(saturate(mad(_484, asfloat(cb4_m[5u].x), asfloat(cb4_m[5u].z))) * (((t14.SampleCmpLevelZero(s14, float2(_537, _538), _469) + t14.SampleCmpLevelZero(s14, float2(_544, _538), _469)) + t14.SampleCmpLevelZero(s14, float2(_537, _549), _469)) + t14.SampleCmpLevelZero(s14, float2(_544, _549), _469)), 0.25f, saturate(mad(_484, asfloat(cb4_m[5u].y), asfloat(cb4_m[5u].w))));
        }
        float4 _572 = float4(v5.x, v5.y, v5.z, 1.0f);
        float4 _590 = t12.Sample(s12, float2(dp4_f32(float4(asfloat(cb4_m[54u].x), asfloat(cb4_m[54u].y), asfloat(cb4_m[54u].z), asfloat(cb4_m[54u].w)), _572), dp4_f32(float4(asfloat(cb4_m[55u].x), asfloat(cb4_m[55u].y), asfloat(cb4_m[55u].z), asfloat(cb4_m[55u].w)), _572)));
        float3 _594 = float3(_331, _332, _333);
        float _596 = saturate(dp3_f32(_364, _594));
        float _617 = _403 ? 0.0f : (_410 * (((_596 * asfloat(cb4_m[4u].x)) * _590.x) * _560));
        float _618 = _403 ? 0.0f : (_410 * (((_596 * asfloat(cb4_m[4u].y)) * _590.y) * _560));
        float _619 = _403 ? 0.0f : (_410 * (((_596 * asfloat(cb4_m[4u].z)) * _590.z) * _560));
        float _1122;
        float _1123;
        float _1124;
        if (cb4_m[63u].x != 0u)
        {
            float _637 = asfloat(cb4_m[6u].x) - v5.x;
            float _638 = asfloat(cb4_m[6u].y) - v5.y;
            float _639 = asfloat(cb4_m[6u].z) - v5.z;
            float3 _640 = float3(_637, _638, _639);
            float _642 = rsqrt(dp3_f32(_640, _640));
            float3 _646 = float3(_637 * _642, _642 * _638, _642 * _639);
            float _647 = dp3_f32(_646, _640);
            float _672 = dp3_f32(_646, float3(-asfloat(cb4_m[7u].x), -asfloat(cb4_m[7u].y), -asfloat(cb4_m[7u].z)));
            bool _685 = (_647 * _672) < asfloat(cb4_m[9u].z);
            float4 _688 = t15.Sample(s15, float2(mad(_647, asfloat(cb4_m[8u].x), asfloat(cb4_m[8u].z)), mad(_647, asfloat(cb4_m[8u].y), asfloat(cb4_m[8u].w))));
            float _690 = saturate(mad(_672, asfloat(cb4_m[9u].x), asfloat(cb4_m[9u].y))) * _688.z;
            float _749 = asfloat(cb4_m[49u].z) + mad(v5.z, asfloat(cb4_m[48u].z), (v5.x * asfloat(cb4_m[46u].z)) + (v5.y * asfloat(cb4_m[47u].z)));
            float _750 = asfloat(cb4_m[49u].w) + mad(v5.z, asfloat(cb4_m[48u].w), (v5.x * asfloat(cb4_m[46u].w)) + (v5.y * asfloat(cb4_m[47u].w)));
            float _826;
            if (asfloat(cb4_m[6u].w) != 0.0f)
            {
                _826 = dp4_f32(t10.Sample(s10, float2(mad(v0.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x)), mad(v0.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y)))), float4(asfloat(cb4_m[11u].x), asfloat(cb4_m[11u].y), asfloat(cb4_m[11u].z), asfloat(cb4_m[11u].w)));
            }
            else
            {
                float _801 = (mad(v5.z, asfloat(cb4_m[48u].x), (v5.y * asfloat(cb4_m[47u].x)) + (v5.x * asfloat(cb4_m[46u].x))) + asfloat(cb4_m[49u].x)) / _750;
                float _802 = (asfloat(cb4_m[49u].y) + mad(v5.z, asfloat(cb4_m[48u].y), (v5.x * asfloat(cb4_m[46u].y)) + (v5.y * asfloat(cb4_m[47u].y)))) / _750;
                float _803 = _801 - 0.0001220703125f;
                float _804 = _802 + 0.00016276042151730507612228393554688f;
                float _810 = _801 + 0.0001220703125f;
                float _815 = _802 - 0.00016276042151730507612228393554688f;
                _826 = mad(saturate(mad(_484, asfloat(cb4_m[11u].x), asfloat(cb4_m[11u].z))) * (((t14.SampleCmpLevelZero(s14, float2(_803, _804), _749) + t14.SampleCmpLevelZero(s14, float2(_810, _804), _749)) + t14.SampleCmpLevelZero(s14, float2(_803, _815), _749)) + t14.SampleCmpLevelZero(s14, float2(_810, _815), _749)), 0.25f, saturate(mad(_484, asfloat(cb4_m[11u].y), asfloat(cb4_m[11u].w))));
            }
            float4 _855 = t13.Sample(s13, float2(dp4_f32(float4(asfloat(cb4_m[57u].x), asfloat(cb4_m[57u].y), asfloat(cb4_m[57u].z), asfloat(cb4_m[57u].w)), _572), dp4_f32(float4(asfloat(cb4_m[58u].x), asfloat(cb4_m[58u].y), asfloat(cb4_m[58u].z), asfloat(cb4_m[58u].w)), _572)));
            float _860 = saturate(dp3_f32(_646, _594));
            float _884 = _617 + (_685 ? 0.0f : (_690 * (((_860 * asfloat(cb4_m[10u].x)) * _855.x) * _826)));
            float _885 = _618 + (_685 ? 0.0f : (_690 * (_826 * (_855.y * (_860 * asfloat(cb4_m[10u].y))))));
            float _886 = _619 + (_685 ? 0.0f : (_690 * (_826 * (_855.z * (_860 * asfloat(cb4_m[10u].z))))));
            float _1119;
            float _1120;
            float _1121;
            if (cb4_m[64u].x != 0u)
            {
                float _904 = asfloat(cb4_m[12u].x) - v5.x;
                float _905 = asfloat(cb4_m[12u].y) - v5.y;
                float _906 = asfloat(cb4_m[12u].z) - v5.z;
                float3 _907 = float3(_904, _905, _906);
                float _909 = rsqrt(dp3_f32(_907, _907));
                float3 _913 = float3(_904 * _909, _909 * _905, _909 * _906);
                float _914 = dp3_f32(_913, _907);
                float _939 = dp3_f32(_913, float3(-asfloat(cb4_m[13u].x), -asfloat(cb4_m[13u].y), -asfloat(cb4_m[13u].z)));
                bool _952 = (_914 * _939) < asfloat(cb4_m[15u].z);
                float4 _955 = t15.Sample(s15, float2(mad(_914, asfloat(cb4_m[14u].x), asfloat(cb4_m[14u].z)), mad(_914, asfloat(cb4_m[14u].y), asfloat(cb4_m[14u].w))));
                float _957 = saturate(mad(_939, asfloat(cb4_m[15u].x), asfloat(cb4_m[15u].y))) * _955.z;
                float _1016 = asfloat(cb4_m[53u].z) + mad(v5.z, asfloat(cb4_m[52u].z), (v5.x * asfloat(cb4_m[50u].z)) + (v5.y * asfloat(cb4_m[51u].z)));
                float _1017 = asfloat(cb4_m[53u].w) + mad(v5.z, asfloat(cb4_m[52u].w), (v5.x * asfloat(cb4_m[50u].w)) + (v5.y * asfloat(cb4_m[51u].w)));
                float _1093;
                if (asfloat(cb4_m[12u].w) != 0.0f)
                {
                    _1093 = dp4_f32(t10.Sample(s10, float2(mad(v0.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x)), mad(v0.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y)))), float4(asfloat(cb4_m[17u].x), asfloat(cb4_m[17u].y), asfloat(cb4_m[17u].z), asfloat(cb4_m[17u].w)));
                }
                else
                {
                    float _1068 = (mad(v5.z, asfloat(cb4_m[52u].x), (v5.y * asfloat(cb4_m[51u].x)) + (v5.x * asfloat(cb4_m[50u].x))) + asfloat(cb4_m[53u].x)) / _1017;
                    float _1069 = (asfloat(cb4_m[53u].y) + mad(v5.z, asfloat(cb4_m[52u].y), (v5.x * asfloat(cb4_m[50u].y)) + (v5.y * asfloat(cb4_m[51u].y)))) / _1017;
                    float _1070 = _1068 - 0.0001220703125f;
                    float _1071 = _1069 + 0.00016276042151730507612228393554688f;
                    float _1077 = _1068 + 0.0001220703125f;
                    float _1082 = _1069 - 0.00016276042151730507612228393554688f;
                    _1093 = mad(saturate(mad(_484, asfloat(cb4_m[17u].x), asfloat(cb4_m[17u].z))) * (((t14.SampleCmpLevelZero(s14, float2(_1070, _1071), _1016) + t14.SampleCmpLevelZero(s14, float2(_1077, _1071), _1016)) + t14.SampleCmpLevelZero(s14, float2(_1070, _1082), _1016)) + t14.SampleCmpLevelZero(s14, float2(_1077, _1082), _1016)), 0.25f, saturate(mad(_484, asfloat(cb4_m[17u].y), asfloat(cb4_m[17u].w))));
                }
                float _1095 = saturate(dp3_f32(_913, _594));
                _1119 = (_952 ? 0.0f : (_957 * ((_1095 * asfloat(cb4_m[16u].z)) * _1093))) + _886;
                _1120 = (_952 ? 0.0f : (_957 * ((_1095 * asfloat(cb4_m[16u].y)) * _1093))) + _885;
                _1121 = _884 + (_952 ? 0.0f : (_957 * ((_1095 * asfloat(cb4_m[16u].x)) * _1093)));
            }
            else
            {
                _1119 = _886;
                _1120 = _885;
                _1121 = _884;
            }
            _1122 = _1119;
            _1123 = _1120;
            _1124 = _1121;
        }
        else
        {
            _1122 = _619;
            _1123 = _618;
            _1124 = _617;
        }
        _1125 = _1122;
        _1126 = _1123;
        _1127 = _1124;
    }
    else
    {
        _1125 = 0.0f;
        _1126 = 0.0f;
        _1127 = 0.0f;
    }
    float _1404;
    float _1405;
    float _1406;
    if (cb4_m[65u].x != 0u)
    {
        float _1141 = asfloat(cb4_m[18u].x) - v5.x;
        float _1142 = asfloat(cb4_m[18u].y) - v5.y;
        float _1143 = asfloat(cb4_m[18u].z) - v5.z;
        float3 _1144 = float3(_1141, _1142, _1143);
        float _1146 = rsqrt(dp3_f32(_1144, _1144));
        float3 _1150 = float3(_1141 * _1146, _1146 * _1142, _1146 * _1143);
        float _1151 = dp3_f32(_1150, _1144);
        float _1176 = dp3_f32(_1150, float3(-asfloat(cb4_m[19u].x), -asfloat(cb4_m[19u].y), -asfloat(cb4_m[19u].z)));
        bool _1189 = (_1151 * _1176) < asfloat(cb4_m[21u].z);
        float4 _1194 = t15.Sample(s15, float2(mad(_1151, asfloat(cb4_m[20u].x), asfloat(cb4_m[20u].z)), mad(_1151, asfloat(cb4_m[20u].y), asfloat(cb4_m[20u].w))));
        float _1196 = saturate(mad(_1176, asfloat(cb4_m[21u].x), asfloat(cb4_m[21u].y))) * _1194.z;
        float3 _1197 = float3(_331, _332, _333);
        float _1199 = saturate(dp3_f32(_1150, _1197));
        float _1217 = _1127 + (_1189 ? 0.0f : ((_1199 * asfloat(cb4_m[22u].x)) * _1196));
        float _1218 = _1126 + (_1189 ? 0.0f : (_1196 * (_1199 * asfloat(cb4_m[22u].y))));
        float _1219 = _1125 + (_1189 ? 0.0f : (_1196 * (_1199 * asfloat(cb4_m[22u].z))));
        float _1401;
        float _1402;
        float _1403;
        if (cb4_m[66u].x != 0u)
        {
            float _1233 = asfloat(cb4_m[24u].x) - v5.x;
            float _1234 = asfloat(cb4_m[24u].y) - v5.y;
            float _1235 = asfloat(cb4_m[24u].z) - v5.z;
            float3 _1236 = float3(_1233, _1234, _1235);
            float _1238 = rsqrt(dp3_f32(_1236, _1236));
            float3 _1242 = float3(_1233 * _1238, _1238 * _1234, _1238 * _1235);
            float _1243 = dp3_f32(_1242, _1236);
            float _1268 = dp3_f32(_1242, float3(-asfloat(cb4_m[25u].x), -asfloat(cb4_m[25u].y), -asfloat(cb4_m[25u].z)));
            bool _1281 = (_1243 * _1268) < asfloat(cb4_m[27u].z);
            float4 _1284 = t15.Sample(s15, float2(mad(_1243, asfloat(cb4_m[26u].x), asfloat(cb4_m[26u].z)), mad(_1243, asfloat(cb4_m[26u].y), asfloat(cb4_m[26u].w))));
            float _1286 = saturate(mad(_1268, asfloat(cb4_m[27u].x), asfloat(cb4_m[27u].y))) * _1284.z;
            float _1288 = saturate(dp3_f32(_1242, _1197));
            float _1306 = _1217 + (_1281 ? 0.0f : ((_1288 * asfloat(cb4_m[28u].x)) * _1286));
            float _1307 = _1218 + (_1281 ? 0.0f : (_1286 * (_1288 * asfloat(cb4_m[28u].y))));
            float _1308 = _1219 + (_1281 ? 0.0f : (_1286 * (_1288 * asfloat(cb4_m[28u].z))));
            float _1398;
            float _1399;
            float _1400;
            if (cb4_m[67u].x != 0u)
            {
                float _1322 = asfloat(cb4_m[30u].x) - v5.x;
                float _1323 = asfloat(cb4_m[30u].y) - v5.y;
                float _1324 = asfloat(cb4_m[30u].z) - v5.z;
                float3 _1325 = float3(_1322, _1323, _1324);
                float _1327 = rsqrt(dp3_f32(_1325, _1325));
                float3 _1331 = float3(_1322 * _1327, _1327 * _1323, _1327 * _1324);
                float _1332 = dp3_f32(_1331, _1325);
                float _1357 = dp3_f32(_1331, float3(-asfloat(cb4_m[31u].x), -asfloat(cb4_m[31u].y), -asfloat(cb4_m[31u].z)));
                bool _1370 = (_1332 * _1357) < asfloat(cb4_m[33u].z);
                float _1375 = saturate(mad(_1357, asfloat(cb4_m[33u].x), asfloat(cb4_m[33u].y))) * t15.Sample(s15, float2(mad(_1332, asfloat(cb4_m[32u].x), asfloat(cb4_m[32u].z)), mad(_1332, asfloat(cb4_m[32u].y), asfloat(cb4_m[32u].w)))).z;
                float _1377 = saturate(dp3_f32(_1331, _1197));
                _1398 = _1308 + (_1370 ? 0.0f : (_1375 * (_1377 * asfloat(cb4_m[34u].z))));
                _1399 = _1307 + (_1370 ? 0.0f : (_1375 * (_1377 * asfloat(cb4_m[34u].y))));
                _1400 = _1306 + (_1370 ? 0.0f : ((_1377 * asfloat(cb4_m[34u].x)) * _1375));
            }
            else
            {
                _1398 = _1308;
                _1399 = _1307;
                _1400 = _1306;
            }
            _1401 = _1398;
            _1402 = _1399;
            _1403 = _1400;
        }
        else
        {
            _1401 = _1219;
            _1402 = _1218;
            _1403 = _1217;
        }
        _1404 = _1401;
        _1405 = _1402;
        _1406 = _1403;
    }
    else
    {
        _1404 = _1125;
        _1405 = _1126;
        _1406 = _1127;
    }
    float _1632;
    float _1633;
    float _1634;
    if (cb4_m[68u].x != 0u)
    {
        bool _1428 = v6.w < asfloat(cb2_m[52u].y);
        bool _1429 = v6.w < asfloat(cb2_m[52u].z);
        bool _1430 = v6.w < asfloat(cb2_m[52u].w);
        float _1504 = mad(v6.x, _1430 ? asfloat(cb2_m[50u].x) : (_1429 ? asfloat(cb2_m[48u].x) : (_1428 ? asfloat(cb2_m[46u].x) : 1.0f)), _1430 ? asfloat(cb2_m[51u].x) : (_1429 ? asfloat(cb2_m[49u].x) : (_1428 ? asfloat(cb2_m[47u].x) : 0.0f)));
        float _1505 = mad(v6.y, _1430 ? asfloat(cb2_m[50u].y) : (_1429 ? asfloat(cb2_m[48u].y) : (_1428 ? asfloat(cb2_m[46u].y) : 1.0f)), _1430 ? asfloat(cb2_m[51u].y) : (_1429 ? asfloat(cb2_m[49u].y) : (_1428 ? asfloat(cb2_m[47u].y) : 0.0f)));
        float _1506 = mad(v6.z, _1430 ? asfloat(cb2_m[50u].z) : (_1429 ? asfloat(cb2_m[48u].z) : (_1428 ? asfloat(cb2_m[46u].z) : 1.0f)), _1430 ? asfloat(cb2_m[51u].z) : (_1429 ? asfloat(cb2_m[49u].z) : (_1428 ? asfloat(cb2_m[47u].z) : 0.0f)));
        float _1565;
        if (asfloat(cb4_m[36u].w) != 0.0f)
        {
            _1565 = dp4_f32(t10.Sample(s10, float2(mad(v0.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x)), mad(v0.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y)))), float4(asfloat(cb4_m[41u].x), asfloat(cb4_m[41u].y), asfloat(cb4_m[41u].z), asfloat(cb4_m[41u].w)));
        }
        else
        {
            float _1543 = _1504 - 0.0001220703125f;
            float _1544 = _1505 + 0.00016276042151730507612228393554688f;
            float _1550 = _1504 + 0.0001220703125f;
            float _1555 = _1505 - 0.00016276042151730507612228393554688f;
            _1565 = (((t14.SampleCmpLevelZero(s14, float2(_1543, _1544), _1506) + t14.SampleCmpLevelZero(s14, float2(_1550, _1544), _1506)) + t14.SampleCmpLevelZero(s14, float2(_1543, _1555), _1506)) + t14.SampleCmpLevelZero(s14, float2(_1550, _1555), _1506)) * 0.25f;
        }
        float _1566 = (v6.w < asfloat(cb2_m[52u].x)) ? _1565 : 1.0f;
        float4 _1578 = float4(v5.x, v5.y, v5.z, 1.0f);
        float4 _1596 = t11.Sample(s11, float2(dp4_f32(float4(asfloat(cb4_m[60u].x), asfloat(cb4_m[60u].y), asfloat(cb4_m[60u].z), asfloat(cb4_m[60u].w)), _1578), dp4_f32(float4(asfloat(cb4_m[61u].x), asfloat(cb4_m[61u].y), asfloat(cb4_m[61u].z), asfloat(cb4_m[61u].w)), _1578)));
        float _1614 = saturate(dp3_f32(float3(-asfloat(cb4_m[37u].x), -asfloat(cb4_m[37u].y), -asfloat(cb4_m[37u].z)), float3(_331, _332, _333)));
        _1632 = mad(_1566, (_1614 * asfloat(cb4_m[40u].z)) * _1596.z, _1404);
        _1633 = mad(_1566, (_1614 * asfloat(cb4_m[40u].y)) * _1596.y, _1405);
        _1634 = mad(_1566, _1596.x * (_1614 * asfloat(cb4_m[40u].x)), _1406);
    }
    else
    {
        _1632 = _1404;
        _1633 = _1405;
        _1634 = _1406;
    }
    float3 _1635 = float3(_331, _332, _333);
    float _1637 = mad(dp3_f32(_1635, float3(0.25f, 0.25f, 1.0f)), 0.5f, 0.5f);
    float _1651 = asfloat(cb2_m[28u].x);
    float _1652 = asfloat(cb2_m[28u].y);
    float _1653 = asfloat(cb2_m[28u].z);
    float4 _1674 = t5.Sample(s5, float2(cb3_m4.x * v1.w, v1.z * cb3_m4.y));
    float4 _1688 = t0.Sample(s0, float2(v1.x * cb3_m6.x, v1.y * cb3_m6.y));
    float _1715 = mad(v0.x, asfloat(cb2_m[44u].z), asfloat(cb2_m[44u].x));
    float _1716 = mad(v0.y, asfloat(cb2_m[44u].w), asfloat(cb2_m[44u].y));
    float4 _1721 = t4.Sample(s4, float2(_1715, _1716));
    float _1729 = dp3_f32(float3(_246, _247, _248), _1635);
    float _1730 = _1729 + _1729;
    float4 _1742 = t3.Sample(s3, float3((_331 * _1730) - _246, (_332 * _1730) - _247, (_333 * _1730) - _248));
    float _1764 = asfloat(cb2_m[33u].x);
    float _1767 = cb3_m3 * _1764;
    float _1768 = mad(_1764, 0.4000000059604644775390625f, 1.0f);
    float _1769 = mad(_1721.x, 2.0f, _1634) * _1768;
    float _1770 = mad(_1721.y, 2.0f, _1633) * _1768;
    float _1771 = mad(_1721.z, 2.0f, _1632) * _1768;
    float _1779 = mad(-cb3_m3, _1764, 1.0f);
    float _1789 = _1769 + (mad(_1637, asfloat(cb2_m[27u].x) - _1651, _1651) * mad(-_1769, _1764, 1.0f));
    float _1790 = (mad(-_1770, _1764, 1.0f) * mad(asfloat(cb2_m[27u].y) - _1652, _1637, _1652)) + _1770;
    float _1791 = (mad(-_1771, _1764, 1.0f) * mad(asfloat(cb2_m[27u].z) - _1653, _1637, _1653)) + _1771;
    float _1801 = (((_1674.x * (cb3_m0.x * (cb3_m8.x * _1742.x))) * _1789) + ((_1767 + ((cb3_m2.x * _1688.x) * _1779)) * _1789));
    float _1802 = ((_1790 * (((cb3_m2.y * _1688.y) * _1779) + _1767)) + (_1790 * (((cb3_m8.x * _1742.y) * cb3_m0.y) * _1674.y)));
    float _1803 = ((_1791 * (((cb3_m2.z * _1688.z) * _1779) + _1767)) + (_1791 * (((cb3_m8.x * _1742.z) * cb3_m0.z) * _1674.z)));
#if 0 // Luma: removed saturates
    _1801 = saturate(_1801);
    _1802 = saturate(_1802);
    _1803 = saturate(_1803);
#endif
    float _1806 = asfloat(cb2_m[43u].x);
    float4 _1813 = t2.Sample(s2, float2(_1715 * _1806, _1716 * _1806));
    float _1814 = _1813.w;
#if 1 // Luma: fixed BT.601 luminance
    float _1822 = GetLuminance(float3(_1801, _1802, _1803));
#else
    float _1822 = dp3_f32(float3(_1801, _1802, _1803), float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));
#endif
    o0.w = (cb3_m7.y * _1764) * (_1822 * _1822);
    float _1833 = saturate(v5.w) * asfloat(cb2_m[29u].x);
    o0.x = (_1801 * _1814) + (_1833 * mad(-_1801, _1814, cb1_m0.x));
    o0.y = (mad(-_1802, _1814, cb1_m0.y) * _1833) + (_1802 * _1814);
    o0.z = (mad(-_1803, _1814, cb1_m0.z) * _1833) + (_1803 * _1814);
}