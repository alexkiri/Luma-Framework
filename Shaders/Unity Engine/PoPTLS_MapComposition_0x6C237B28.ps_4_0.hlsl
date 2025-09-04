cbuffer cb0_buf : register(b0)
{
    uint4 cb0_m[132] : packoffset(c0);
};

SamplerState s0 : register(s0);
SamplerState s1 : register(s1);
Texture2D<float4> t0 : register(t0);
Texture2D<float4> t1 : register(t1);
Texture2D<float4> t2 : register(t2);
Texture2D<float4> t3 : register(t3);

int cvt_f32_i32(precise float v)
{
    return isnan(v) ? 0 : ((v < (-2147483648.0f)) ? int(0x80000000) : ((v > 2147483520.0f) ? 2147483647 : int(v)));
}

float dp4_f32(precise float4 a, precise float4 b)
{
    precise float _94 = a.x * b.x;
    return mad(a.w, b.w, mad(a.z, b.z, mad(a.y, b.y, _94)));
}

float dp2_f32(precise float2 a, precise float2 b)
{
    precise float _82 = a.x * b.x;
    return mad(a.y, b.y, _82);
}

void main(
  float4 gl_FragCoord : SV_POSITION0,
  float2 TEXCOORD : TEXCOORD0,
  out float4 SV_Target : SV_Target0)
{
    precise float2 _126 = float2(TEXCOORD.x, TEXCOORD.y);
    precise float _131 = asfloat(cb0_m[21u].x);
    precise float4 _134 = t0.SampleBias(s0, _126, _131);
    precise float _138 = _134.w;
    precise float4 _141 = t1.SampleBias(s0, _126, _131);
    precise float _145 = _141.w;
    precise float4 _148 = t2.SampleBias(s0, _126, _131);
    precise float _149 = _148.w;
    precise float _153 = _138 * 255.f + 0.5f; // Luma: fixed all normalziation (color*255.5 to color*255+0.5), without this, the map is broken when rendered in float textures, due to a lack of alpha quantization to 8 bit
    precise float _159 = asfloat(cb0_m[131u].x);
    precise float _160 = _159 - 0.2f;
    float _838;
    float _839;
    float _840;
    float _841;
    if ((_145 > 0.1f) && (_145 < 0.9f))
    {
        precise float _167 = _160 * 0.91f;
        precise float _168 = _167 + 0.5f;
        precise float _176 = _168 * asfloat(cb0_m[130u].x);
        precise float _177 = _168 * asfloat(cb0_m[130u].y);
        precise float _178 = ddx(TEXCOORD.x);
        precise float _179 = ddy(TEXCOORD.y);
        precise float _180 = TEXCOORD.x - _178;
        precise float _181 = TEXCOORD.y + 0.0f;
        precise float2 _183 = float2(_180, _181);
        precise float _187 = _176 * (-sqrt(2.f));
        precise float _188 = _177 * (-sqrt(2.f));
        precise float _189 = _177 * sqrt(2.f);
        precise float _190 = _180 + _187;
        precise float _191 = _188 + _181;
        precise float _192 = _189 + _181;
        precise float2 _193 = float2(_190, _191);
        precise float2 _197 = float2(_190, _192);
        precise float _201 = _176 * sqrt(2.f);
        precise float _202 = _180 + _201;
        precise float2 _203 = float2(_202, _191);
        precise float2 _207 = float2(_202, _192);
        precise float _211 = _180 - _176;
        precise float _212 = _180 + 0.0f;
        precise float _213 = _181 - _177;
        precise float2 _214 = float2(_211, _181);
        precise float2 _218 = float2(_212, _213);
        precise float _222 = _180 + _176;
        precise float _223 = _181 + _177;
        precise float2 _224 = float2(_222, _181);
        precise float2 _228 = float2(_212, _223);
        precise float _232 = t0.SampleBias(s1, _183, _131).w * 255.f + 0.5f;
        precise float _236 = t0.SampleBias(s1, _193, _131).w * 255.f + 0.5f;
        precise float _240 = t0.SampleBias(s1, _197, _131).w * 255.f + 0.5f;
        precise float _244 = t0.SampleBias(s1, _203, _131).w * 255.f + 0.5f;
        precise float _248 = t0.SampleBias(s1, _207, _131).w * 255.f + 0.5f;
        precise float _252 = t0.SampleBias(s1, _214, _131).w * 255.f + 0.5f;
        precise float _256 = t0.SampleBias(s1, _218, _131).w * 255.f + 0.5f;
        precise float _260 = t0.SampleBias(s1, _224, _131).w * 255.f + 0.5f;
        precise float _264 = t0.SampleBias(s1, _228, _131).w * 255.f + 0.5f;
        precise float _296 = (t0.SampleBias(s0, _183, _131).w != 1.0f) ? 0.0f : 1.0f;
        precise float _307 = ((t0.SampleBias(s0, _193, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _296;
        precise float _308 = ((t0.SampleBias(s0, _197, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _296;
        precise float _313 = ((t0.SampleBias(s0, _203, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _296;
        precise float _315 = ((t0.SampleBias(s0, _207, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _296;
        precise float _321 = ((t0.SampleBias(s0, _214, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _296;
        precise float _323 = ((t0.SampleBias(s0, _218, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _296;
        precise float _329 = ((t0.SampleBias(s0, _224, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _296;
        precise float _330 = ((t0.SampleBias(s0, _228, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _296;
        precise float _336 = TEXCOORD.x + _178;
        precise float2 _337 = float2(_336, _181);
        precise float _341 = _336 + _187;
        precise float2 _342 = float2(_341, _191);
        precise float2 _346 = float2(_341, _192);
        precise float _350 = _201 + _336;
        precise float2 _351 = float2(_350, _191);
        precise float2 _355 = float2(_350, _192);
        precise float _359 = _336 - _176;
        precise float _360 = _336 + _176;
        precise float2 _361 = float2(_359, _181);
        precise float _365 = 1.0f * 0.0f;
        precise float _366 = _177 * (-1.0f);
        precise float _367 = _336 + _365;
        precise float _368 = _366 + _181;
        precise float2 _369 = float2(_367, _368);
        precise float2 _373 = float2(_360, _181);
        precise float _377 = _336 + 0.0f;
        precise float2 _378 = float2(_377, _223);
        precise float _382 = t0.SampleBias(s1, _337, _131).w * 255.f + 0.5f;
        precise float _386 = t0.SampleBias(s1, _342, _131).w * 255.f + 0.5f;
        precise float _390 = t0.SampleBias(s1, _346, _131).w * 255.f + 0.5f;
        precise float _394 = t0.SampleBias(s1, _351, _131).w * 255.f + 0.5f;
        precise float _398 = t0.SampleBias(s1, _355, _131).w * 255.f + 0.5f;
        precise float _402 = t0.SampleBias(s1, _361, _131).w * 255.f + 0.5f;
        precise float _406 = t0.SampleBias(s1, _369, _131).w * 255.f + 0.5f;
        precise float _410 = t0.SampleBias(s1, _373, _131).w * 255.f + 0.5f;
        precise float _414 = t0.SampleBias(s1, _378, _131).w * 255.f + 0.5f;
        precise float _446 = (t0.SampleBias(s0, _337, _131).w != 1.0f) ? 0.0f : 1.0f;
        precise float _457 = _446 + ((t0.SampleBias(s0, _342, _131).w != 1.0f) ? (-0.0f) : (-1.0f));
        precise float _458 = _446 + ((t0.SampleBias(s0, _346, _131).w != 1.0f) ? (-0.0f) : (-1.0f));
        precise float _464 = _446 + ((t0.SampleBias(s0, _351, _131).w != 1.0f) ? (-0.0f) : (-1.0f));
        precise float _465 = _446 + ((t0.SampleBias(s0, _355, _131).w != 1.0f) ? (-0.0f) : (-1.0f));
        precise float _472 = _446 + ((t0.SampleBias(s0, _361, _131).w != 1.0f) ? (-0.0f) : (-1.0f));
        precise float _473 = _446 + ((t0.SampleBias(s0, _369, _131).w != 1.0f) ? (-0.0f) : (-1.0f));
        precise float _479 = _446 + ((t0.SampleBias(s0, _373, _131).w != 1.0f) ? (-0.0f) : (-1.0f));
        precise float _480 = _446 + ((t0.SampleBias(s0, _378, _131).w != 1.0f) ? (-0.0f) : (-1.0f));
        precise float _486 = TEXCOORD.x + 0.0f;
        precise float _487 = TEXCOORD.y - _179;
        precise float2 _488 = float2(_486, _487);
        precise float _492 = _486 + _187;
        precise float _493 = _487 + _188;
        precise float _494 = _487 + _189;
        precise float2 _495 = float2(_492, _493);
        precise float2 _499 = float2(_492, _494);
        precise float _503 = _201 + _486;
        precise float2 _504 = float2(_503, _493);
        precise float2 _508 = float2(_503, _494);
        precise float _512 = _176 * (-1.0f);
        precise float _513 = _486 + _512;
        precise float _514 = _487 + _365;
        precise float2 _515 = float2(_513, _514);
        precise float _519 = TEXCOORD.x + _365;
        precise float _520 = _487 + _366;
        precise float2 _521 = float2(_519, _520);
        precise float _525 = _486 + _176;
        precise float _526 = _487 + 0.0f;
        precise float _527 = _487 + _177;
        precise float2 _528 = float2(_525, _526);
        precise float2 _532 = float2(_486, _527);
        precise float _536 = t0.SampleBias(s1, _488, _131).w * 255.f + 0.5f;
        precise float _540 = t0.SampleBias(s1, _495, _131).w * 255.f + 0.5f;
        precise float _544 = t0.SampleBias(s1, _499, _131).w * 255.f + 0.5f;
        precise float _548 = t0.SampleBias(s1, _504, _131).w * 255.f + 0.5f;
        precise float _552 = t0.SampleBias(s1, _508, _131).w * 255.f + 0.5f;
        precise float _556 = t0.SampleBias(s1, _515, _131).w * 255.f + 0.5f;
        precise float _560 = t0.SampleBias(s1, _521, _131).w * 255.f + 0.5f;
        precise float _564 = t0.SampleBias(s1, _528, _131).w * 255.f + 0.5f;
        precise float _568 = t0.SampleBias(s1, _532, _131).w * 255.f + 0.5f;
        precise float _608 = (t0.SampleBias(s0, _488, _131).w != 1.0f) ? 0.0f : 1.0f;
        precise float _611 = ((t0.SampleBias(s0, _495, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _608;
        precise float _612 = ((t0.SampleBias(s0, _499, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _608;
        precise float _618 = ((t0.SampleBias(s0, _504, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _608;
        precise float _619 = ((t0.SampleBias(s0, _508, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _608;
        precise float _626 = ((t0.SampleBias(s0, _515, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _608;
        precise float _627 = ((t0.SampleBias(s0, _521, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _608;
        precise float _632 = ((t0.SampleBias(s0, _528, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _608;
        precise float _634 = ((t0.SampleBias(s0, _532, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _608;
        precise float _640 = TEXCOORD.y + _179;
        precise float2 _641 = float2(_486, _640);
        precise float _645 = _188 + _640;
        precise float _646 = _189 + _640;
        precise float2 _647 = float2(_492, _645);
        precise float2 _651 = float2(_492, _646);
        precise float2 _655 = float2(_503, _645);
        precise float2 _659 = float2(_503, _646);
        precise float _663 = _365 + _640;
        precise float2 _664 = float2(_513, _663);
        precise float _668 = _366 + _640;
        precise float2 _669 = float2(_519, _668);
        precise float _673 = _640 + 0.0f;
        precise float _674 = _177 + _640;
        precise float2 _675 = float2(_525, _673);
        precise float2 _679 = float2(_486, _674);
        precise float _683 = t0.SampleBias(s1, _641, _131).w * 255.f + 0.5f;
        precise float _687 = t0.SampleBias(s1, _647, _131).w * 255.f + 0.5f;
        precise float _691 = t0.SampleBias(s1, _651, _131).w * 255.f + 0.5f;
        precise float _695 = t0.SampleBias(s1, _655, _131).w * 255.f + 0.5f;
        precise float _699 = t0.SampleBias(s1, _659, _131).w * 255.f + 0.5f;
        precise float _703 = t0.SampleBias(s1, _664, _131).w * 255.f + 0.5f;
        precise float _707 = t0.SampleBias(s1, _669, _131).w * 255.f + 0.5f;
        precise float _711 = t0.SampleBias(s1, _675, _131).w * 255.f + 0.5f;
        precise float _715 = t0.SampleBias(s1, _679, _131).w * 255.f + 0.5f;
        precise float _755 = (t0.SampleBias(s0, _641, _131).w != 1.0f) ? 0.0f : 1.0f;
        precise float _757 = ((t0.SampleBias(s0, _647, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _755;
        precise float _759 = ((t0.SampleBias(s0, _651, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _755;
        precise float _765 = ((t0.SampleBias(s0, _655, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _755;
        precise float _766 = ((t0.SampleBias(s0, _659, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _755;
        precise float _774 = ((t0.SampleBias(s0, _664, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _755;
        precise float _775 = ((t0.SampleBias(s0, _669, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _755;
        precise float _780 = ((t0.SampleBias(s0, _675, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _755;
        precise float _781 = ((t0.SampleBias(s0, _679, _131).w != 1.0f) ? (-0.0f) : (-1.0f)) + _755;
        float _788 = dp4_f32(float4(max(max(max(abs(_308), abs(_307)), max(abs(_313), abs(_315))), max(max(abs(_321), abs(_323)), max(abs(_330), abs(_329)))), max(max(max(abs(_458), abs(_457)), max(abs(_465), abs(_464))), max(max(abs(_473), abs(_472)), max(abs(_480), abs(_479)))), max(max(max(abs(_612), abs(_611)), max(abs(_619), abs(_618))), max(max(abs(_627), abs(_626)), max(abs(_634), abs(_632)))), max(max(max(abs(_757), abs(_759)), max(abs(_766), abs(_765))), max(max(abs(_775), abs(_774)), max(abs(_781), abs(_780))))), 0.25f.xxxx);
        precise float _790 = float(min(min(min(min(min(min(min(min(min((cvt_f32_i32(_232) >> int(3u)), 31), (cvt_f32_i32(_236) >> int(3u))), (cvt_f32_i32(_240) >> int(3u))), (cvt_f32_i32(_244) >> int(3u))), (cvt_f32_i32(_248) >> int(3u))), (cvt_f32_i32(_252) >> int(3u))), (cvt_f32_i32(_256) >> int(3u))), (cvt_f32_i32(_260) >> int(3u))), (cvt_f32_i32(_264) >> int(3u)))) * 0.03125f;
        precise float _791 = _790 + (2.f / 256.f);
        precise float4 _795 = t3.SampleBias(s1, float2(_791, 1.0f), _131);
        precise float _800 = float(min(min(min(min(min(min(min(min(min((cvt_f32_i32(_382) >> int(3u)), 31), (cvt_f32_i32(_386) >> int(3u))), (cvt_f32_i32(_390) >> int(3u))), (cvt_f32_i32(_394) >> int(3u))), (cvt_f32_i32(_398) >> int(3u))), (cvt_f32_i32(_402) >> int(3u))), (cvt_f32_i32(_406) >> int(3u))), (cvt_f32_i32(_410) >> int(3u))), (cvt_f32_i32(_414) >> int(3u)))) * 0.03125f;
        precise float _801 = _800 + (2.f / 256.f);
        precise float4 _804 = t3.SampleBias(s1, float2(_801, 1.0f), _131);
        precise float _808 = _795.x + _804.x;
        precise float _809 = _795.y + _804.y;
        precise float _810 = _795.z + _804.z;
        precise float _812 = float(min(min(min(min(min(min(min(min(min((cvt_f32_i32(_536) >> int(3u)), 31), (cvt_f32_i32(_540) >> int(3u))), (cvt_f32_i32(_544) >> int(3u))), (cvt_f32_i32(_548) >> int(3u))), (cvt_f32_i32(_552) >> int(3u))), (cvt_f32_i32(_556) >> int(3u))), (cvt_f32_i32(_560) >> int(3u))), (cvt_f32_i32(_564) >> int(3u))), (cvt_f32_i32(_568) >> int(3u)))) * 0.03125f;
        precise float _813 = _812 + (2.f / 256.f);
        precise float4 _816 = t3.SampleBias(s1, float2(_813, 1.0f), _131);
        precise float _820 = _808 + _816.x;
        precise float _821 = _816.y + _809;
        precise float _822 = _816.z + _810;
        precise float _824 = float(min(min(min(min(min(min(min(min(min((cvt_f32_i32(_683) >> int(3u)), 31), (cvt_f32_i32(_687) >> int(3u))), (cvt_f32_i32(_691) >> int(3u))), (cvt_f32_i32(_695) >> int(3u))), (cvt_f32_i32(_699) >> int(3u))), (cvt_f32_i32(_703) >> int(3u))), (cvt_f32_i32(_707) >> int(3u))), (cvt_f32_i32(_711) >> int(3u))), (cvt_f32_i32(_715) >> int(3u)))) * 0.03125f;
        precise float _825 = _824 + (2.f / 256.f);
        precise float4 _828 = t3.SampleBias(s1, float2(_825, 1.0f), _131);
        precise float _832 = _820 + _828.x;
        precise float _833 = _828.y + _821;
        precise float _834 = _828.z + _822;
        precise float _835 = _832 * 0.25f;
        precise float _836 = _833 * 0.25f;
        precise float _837 = _834 * 0.25f;
        _838 = _788;
        _839 = _837;
        _840 = _836;
        _841 = _835;
    }
    else
    {
        _838 = 0.0f;
        _839 = 0.0f;
        _840 = 0.0f;
        _841 = 0.0f;
    }
    float _847;
    switch (uint(cvt_f32_i32(_153) & 3))
    {
        case 0u:
        {
            _847 = _148.x;
            break;
        }
        case 1u:
        {
            _847 = _148.y;
            break;
        }
        case 2u:
        {
            _847 = _148.z;
            break;
        }
        case 3u:
        {
            _847 = _149;
            break;
        }
        default:
        {
            _847 = _149;
            break;
        }
    }
    precise float _848 = _847 - 0.5f;
    precise float _849 = clamp(_848, 0.0f, 1.0f);
    precise float _850 = _849 + _849;
    precise float _854 = asfloat(cb0_m[131u].y) * 1.01f;
    precise float _855 = _854 - 0.01f;
    precise float _862 = asfloat(cb0_m[20u].z) - 1.0f;
    precise float _863 = asfloat(cb0_m[20u].w) - 1.0f;
    precise float _868 = _862 * gl_FragCoord.x;
    precise float _869 = gl_FragCoord.y * _863;
    precise float _873 = asfloat(cb0_m[20u].x) * _863;
    precise float _874 = _868 * _873;
    precise float _875 = _873 * 0.5f;
    precise float _876 = _875 - _874;
    precise float _877 = 0.5f - _869;
    precise float2 _878 = float2(_876, _877);
    precise float _881 = sqrt(dp2_f32(_878, _878)) * 0.8f;
    precise float _882 = 0.01f - _854;
    precise float _883 = _881 + _882;
    precise float _885 = abs(_883) * (-5.0f);
    precise float _886 = _885 + 1.0f;
    precise float _889 = float(_855 > _881);
    precise float _890 = max(_886, 0.0f) * _889;
    precise float _891 = _890 * _890;
    precise float _892 = _891 * _891;
    precise float _893 = _891 * _892;
    precise float _894 = _893 * 0.5f;
    precise float _898 = float((_847 > 0.0f) && (_847 <= 0.005f));
    precise float _899 = _889 * _898;
    precise float _901 = _141.x * 0.25f;
    precise float _902 = _141.y * 0.25f;
    precise float _903 = _141.z * 0.25f;
    precise float _904 = _134.x * _145;
    precise float _905 = _134.y * _145;
    precise float _906 = _134.z * _145;
    precise float _907 = _901 + _904;
    precise float _908 = _905 + _902;
    precise float _909 = _906 + _903;
    precise float _910 = _841 - _907;
    precise float _911 = _840 - _908;
    precise float _912 = _839 - _909;
    precise float _913 = _910 * _838;
    precise float _914 = _911 * _838;
    precise float _915 = _912 * _838;
    precise float _916 = _907 + _913;
    precise float _917 = _914 + _908;
    precise float _918 = _915 + _909;
    precise float _921 = asfloat(cb0_m[131u].z);
    precise float _922 = _916 * _921;
    precise float _923 = _917 * _921;
    precise float _924 = _918 * _921;
    precise float _925 = _916 - _922;
    precise float _926 = _917 - _923;
    precise float _927 = _918 - _924;
    precise float _928 = _850 * _925;
    precise float _929 = _850 * _926;
    precise float _930 = _850 * _927;
    precise float _931 = _922 + _928;
    precise float _932 = _929 + _923;
    precise float _933 = _930 + _924;
    precise float _934 = _841 * 1.5f;
    precise float _935 = _840 * 1.5f;
    precise float _936 = _839 * 1.5f;
    precise float _940 = _890 * _838;
    precise float _941 = _898 * _940;
    precise float _942 = clamp(_934, 0.0f, 1.0f) - _931;
    precise float _943 = clamp(_935, 0.0f, 1.0f) - _932;
    precise float _944 = clamp(_936, 0.0f, 1.0f) - _933;
    precise float _945 = _941 * _942;
    precise float _946 = _943 * _941;
    precise float _947 = _944 * _941;
    precise float _948 = _931 + _945;
    precise float _949 = _946 + _932;
    precise float _950 = _947 + _933;
    precise float _955 = asfloat(cb0_m[131u].w);
    precise float _956 = 1.0f - _955;
    precise float _957 = _850 * _956;
    precise float _958 = _955 + _957;
    precise float _959 = _958 * ((_138 == 1.0f) ? 0.0f : 1.0f);
    precise float _960 = _838 * 0.25f;
    precise float _961 = 0.2f - _159;
    precise float _962 = _961 * 1.3f;
    precise float _963 = _962 + 1.0f;
    precise float _964 = _960 * _963;
    precise float _966 = _847 + _847;
    precise float _969 = max(_959, _964) * ((_899 > 0.5f) ? 1.0f : clamp(_966, 0.0f, 1.0f));
    precise float _970 = 1.0f - _948;
    precise float _971 = 1.0f - _949;
    precise float _972 = 1.0f - _950;
    precise float _973 = _894 * _970;
    precise float _974 = _971 * _894;
    precise float _975 = _972 * _894;
    precise float _976 = _948 + _973;
    precise float _977 = _974 + _949;
    precise float _978 = _975 + _950;
    SV_Target.x = clamp(_976, 0.0f, 1.0f);
    SV_Target.y = clamp(_977, 0.0f, 1.0f);
    SV_Target.z = clamp(_978, 0.0f, 1.0f);
    SV_Target.w = max(_894, _969);
}