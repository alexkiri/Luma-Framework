cbuffer cb0_buf : register(b0)
{
    float3 cb0_m0 : packoffset(c0);
    uint cb0_m1 : packoffset(c0.w);
    uint4 cb0_m2 : packoffset(c1);
    uint4 cb0_m3 : packoffset(c2);
    uint4 cb0_m4 : packoffset(c3);
    float4 cb0_m5 : packoffset(c4);
    float3 cb0_m6 : packoffset(c5);
    uint cb0_m7 : packoffset(c5.w);
};

cbuffer cb1_buf : register(b1)
{
    float3 cb1_m0 : packoffset(c0);
    float cb1_m1 : packoffset(c0.w);
};

SamplerState s0 : register(s0);
SamplerState s1 : register(s1);
Texture2D<float4> t0 : register(t0);
Texture2D<float4> t1 : register(t1);

struct SPIRV_Cross_Input
{
    float4 v0 : SV_POSITION0;
    float2 TEXCOORD : TEXCOORD0;
    float TEXCOORD1 : TEXCOORD1;
    float4 TEXCOORD2 : TEXCOORD2;
    float3 TEXCOORD3 : TEXCOORD3;
};

float dp3_f32(precise float3 a, precise float3 b)
{
    precise float _74 = a.x * b.x;
    return mad(a.z, b.z, mad(a.y, b.y, _74));
}

float4 main(SPIRV_Cross_Input stage_input) : SV_Target
{
    float2 _TEXCOORD = stage_input.TEXCOORD;
    float _TEXCOORD1 = stage_input.TEXCOORD1;
    float4 _TEXCOORD2 = stage_input.TEXCOORD2;
    float3 _TEXCOORD3 = stage_input.TEXCOORD3;
    precise float _91 = _TEXCOORD2.x / _TEXCOORD2.w;
    precise float _92 = _TEXCOORD2.y / _TEXCOORD2.w;
    precise float4 _98 = t1.Sample(s0, float2(_91, _92));
    precise float3 _115 = cb0_m0.xyz - log2(max(_98.xyz, 0.000977517105638980865478515625f));
    precise float3 _118 = saturate(_115);
    precise float _121 = _118.x * 2.0f;
    precise float _122 = _118.y * 2.0f;
    precise float _123 = _121 - _118.y;
    precise float _124 = _122 - _118.x;
    precise float _125 = _123 - _118.z;
    precise float _126 = _124 - _118.z;
    precise float _129 = _125 * 0.3333333432674407958984375f;
    precise float _130 = _126 * 0.3333333432674407958984375f;
    precise float _131 = abs(_130);
    precise float _132 = abs(_129);
    precise float _136 = (1.0f / max(_131, _132)) * min(_131, _132); // Note: this could cause NaNs?
    precise float _137 = _136 * _136;
    precise float _138 = _137 * 0.02083509974181652069091796875f;
    precise float _139 = _138 - 0.08513300120830535888671875f;
    precise float _140 = _137 * _139;
    precise float _141 = _140 + 0.1801410019397735595703125f;
    precise float _142 = _137 * _141;
    precise float _143 = _142 - 0.33029949665069580078125f;
    precise float _144 = _137 * _143;
    precise float _145 = _144 + 0.999866008758544921875f;
    precise float _146 = _136 * _145;
    precise float _147 = _146 * (-2.0f);
    precise float _148 = _147 + 1.57079637050628662109375f;
    precise float _152 = _146 + ((_131 < _132) ? _148 : 0.0f);
    precise float _156 = _152 + (((-_130) > _130) ? (-3.1415927410125732421875f) : 0.0f);
    precise float _157 = min(_130, _129);
    precise float _160 = max(_130, _129);
    precise float _161 = _129 * _129;
    precise float _162 = _130 * _130;
    precise float _163 = _161 + _162;
    precise float _164 = sqrt(_163);
    precise float _171 = (_164 > 0.0f) ? (((_157 < (-_157)) && (_160 >= (-_160))) ? (-_156) : _156) : 0.0f;
    precise float _196 = (((uint(_TEXCOORD.x < 0.75f) * uint(_TEXCOORD.x > 0.5f)) != 0u) && ((uint(_TEXCOORD.y > 0.25f) * uint(_TEXCOORD.y < 0.5f)) != 0u)) ? cb0_m5.y : cb0_m5.x;
    precise float _197 = dp3_f32(0.33329999446868896484375f.xxx, _118) - _196;
    precise float _199 = (1.0f - _196) - _196;
    precise float _201 = saturate(_197 / _199);
    precise float _202 = _164 * sin(_171);
    precise float _203 = _201 - _202;
    precise float _204 = _164 * cos(_171);
    precise float _205 = _203 - _204;
    precise float _207 = _202 + _201;
    precise float _208 = _204 + _201;
    precise float _209 = _201 - 0.20000000298023223876953125f;
    precise float _210 = _209 * (-5.0f);
    precise float _212 = max(_210, 0.0f) * 0.60000002384185791015625f;
    precise float _219 = _207 + _TEXCOORD3.x;
    precise float _220 = _208 + _TEXCOORD3.y;
    precise float _221 = saturate(_205) + _TEXCOORD3.z;
    precise float4 _226 = t0.Sample(s1, float2(_TEXCOORD.x, _TEXCOORD.y));
    precise float _230 = _219 * _226.x;
    precise float _231 = _226.y * _220;
    precise float _232 = _226.z * _221;
    float _234 = dp3_f32(float3(_230, _231, _232), float3(0.2199999988079071044921875f, 0.7070000171661376953125f, 0.071000002324581146240234375f));
    precise float _235 = _234 - _230;
    precise float _236 = _234 - _231;
    precise float _237 = _234 - _232;
    precise float _238 = _212 * _235;
    precise float _239 = _212 * _236;
    precise float _240 = _212 * _237;
    precise float _241 = _230 + _238;
    precise float _242 = _239 + _231;
    precise float _243 = _240 + _232;
    precise float _255 = _241 * cb0_m6.x;
    precise float _256 = _242 * cb0_m6.y;
    precise float _257 = _243 * cb0_m6.z;
    precise float _258 = _255 - cb1_m0.x;
    precise float _259 = _256 - cb1_m0.y;
    precise float _260 = _257 - cb1_m0.z;
    precise float _263 = 1.0f - cb1_m1;
    precise float _265 = clamp(_263, _TEXCOORD1, 1.0f);
    precise float _266 = _258 * _265;
    precise float _267 = _259 * _265;
    precise float _268 = _260 * _265;
    precise float _269 = cb1_m0.x + _266;
    precise float _270 = _267 + cb1_m0.y;
    precise float _271 = _268 + cb1_m0.z;
    float4 SV_Target;
    SV_Target.x = _269;
    SV_Target.y = _270;
    SV_Target.z = _271;
    SV_Target.w = 1.0f;
    return SV_Target;
}