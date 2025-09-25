#include "renodx/tonemap.hlsl"
#include "renodx/effects.hlsl"
#include "../../Includes/Color.hlsl"

float UpgradeToneMapRatio(float ap1_color_hdr, float ap1_color_sdr, float ap1_post_process_color) {
  if (ap1_color_hdr < ap1_color_sdr) {
    // If substracting (user contrast or paperwhite) scale down instead
    // Should only apply on mismatched HDR
    return ap1_color_hdr / ap1_color_sdr;
  } else {
    float ap1_delta = ap1_color_hdr - ap1_color_sdr;
    ap1_delta = max(0, ap1_delta);  // Cleans up NaN
    const float ap1_new = ap1_post_process_color + ap1_delta;

    const bool ap1_valid = (ap1_post_process_color > 0);  // Cleans up NaN and ignore black
    return ap1_valid ? (ap1_new / ap1_post_process_color) : 0;
  }
}

float3 UpgradeToneMapByLuminance(float3 color_hdr, float3 color_sdr, float3 post_process_color, float post_process_strength) {
  float3 bt2020_hdr = max(0, BT709_To_BT2020(color_hdr));
  float3 bt2020_sdr = max(0, BT709_To_BT2020(color_sdr));
  float3 bt2020_post_process = max(0, BT709_To_BT2020(post_process_color));

  float ratio = UpgradeToneMapRatio(
      GetLuminance(bt2020_hdr, CS_BT2020),
      GetLuminance(bt2020_sdr, CS_BT2020),
      GetLuminance(bt2020_post_process, CS_BT2020));

  float3 color_scaled = max(0, bt2020_post_process * ratio);
  color_scaled = BT2020_To_BT709(color_scaled);
  color_scaled = RestoreHueAndChrominance(color_scaled, post_process_color, 1.f, 0.f);
  return lerp(color_hdr, color_scaled, post_process_strength);
}

float3 applyACES(float3 untonemapped, float midGray = 0.1f, float peak_nits = 1000.f, float game_nits = 250.f) {
  renodx::tonemap::Config aces_config = renodx::tonemap::config::Create();
  aces_config.peak_nits = peak_nits;
  aces_config.game_nits = game_nits;
  aces_config.type = 2u;
  aces_config.mid_gray_value = midGray;
  aces_config.mid_gray_nits = midGray * 100.f;
  aces_config.gamma_correction = 0;
  return renodx::tonemap::config::ApplyACES(untonemapped, aces_config);
}

float3 applyReferenceACES(float3 untonemapped, float midGray = 0.1f) {
  return applyACES(untonemapped, midGray, 1000.f, 250.f);
}

float3 extractColorGradeAndApplyTonemap(float3 ungraded_bt709, float3 lutOutputColor_bt2020, float midGray, float2 position) {
  // normalize LUT output paper white and convert to BT.709
  ungraded_bt709 = ungraded_bt709 * 1.5f;
  float3 graded_aces_bt709 = BT2020_To_BT709(lutOutputColor_bt2020 * ( 1 / 250.f ));

  float3 tonemapped_bt709;
//   if (RENODX_TONE_MAP_TYPE != 0) {
//     // separate the display mapping from the color grading/tone mapping
//     float3 reference_tonemap_bt709 = renodx::tonemap::ReinhardScalable(ungraded_bt709, 1000.f / 250.f, 0.f, 0.18f, midGray);
//     float3 graded_untonemapped_bt709 = UpgradeToneMapPerChannel(ungraded_bt709, reference_tonemap_bt709, graded_aces_bt709, 1.f);

//     tonemapped_bt709 = ToneMap(graded_untonemapped_bt709, graded_aces_bt709, midGray);

//     if (CUSTOM_LUT_STRENGTH != 1.f) {
//       float3 ungraded_tonemapped_bt709 = ToneMap(ungraded_bt709, graded_aces_bt709, midGray);

//       tonemapped_bt709 = lerp(ungraded_tonemapped_bt709, tonemapped_bt709, CUSTOM_LUT_STRENGTH);
//     }
//   } else {
    // using custom_aces as hdr_color allows us to extend (or compress) the dynamic range
    // in a way that looks natural and perfectly preserves the original look
    float3 reference_tonemap_bt709 = applyReferenceACES(ungraded_bt709, midGray);
    float3 custom_aces = applyACES(ungraded_bt709, midGray, LumaSettings.PeakWhiteNits, LumaSettings.GamePaperWhiteNits);
    tonemapped_bt709 = UpgradeToneMapByLuminance(custom_aces, reference_tonemap_bt709, graded_aces_bt709, LumaSettings.GameSettings.custom_lut_strength);

    // clean up slight overshoot with very low peak values
    tonemapped_bt709 = min(LumaSettings.PeakWhiteNits / LumaSettings.GamePaperWhiteNits, tonemapped_bt709);
//   }

  if (LumaSettings.GameSettings.custom_film_grain_strength != 0) {
    tonemapped_bt709 = renodx::effects::ApplyFilmGrain(
        tonemapped_bt709.rgb,
        position.xy,
        LumaSettings.GameSettings.custom_random,
        LumaSettings.GameSettings.custom_film_grain_strength * 0.03f,
        1.f);
  }

//   tonemapped_bt709 = convertColorSpace(tonemapped_bt709);

  tonemapped_bt709 = BT709_To_BT2020(tonemapped_bt709);

  return tonemapped_bt709 * (LumaSettings.GamePaperWhiteNits);
}