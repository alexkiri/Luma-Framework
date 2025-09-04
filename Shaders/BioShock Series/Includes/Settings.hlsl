#ifndef SRC_GAME_SETTINGS_HLSL
#define SRC_GAME_SETTINGS_HLSL

// Include this after the global "Settings.hlsl" file

/////////////////////////////////////////
// Mafia III LUMA advanced settings
// (note that the defaults might be mirrored in c++, the shader values will be overridden anyway)
/////////////////////////////////////////

#if !defined(ENABLE_LUMA)
#define ENABLE_LUMA 1
#endif

#if !defined(ALLOW_AA)
#define ALLOW_AA 1
#endif

#ifndef ENABLE_IMPROVED_BLOOM
#define ENABLE_IMPROVED_BLOOM 1
#endif

#ifndef TONEMAP_TYPE
#define TONEMAP_TYPE 1
#endif

#if !defined(ENABLE_LUT_EXTRAPOLATION)
#define ENABLE_LUT_EXTRAPOLATION 1
#endif

#ifndef ENABLE_COLOR_GRADING
#define ENABLE_COLOR_GRADING 1
#endif

#ifndef DISABLE_BLACK_BARS
#define DISABLE_BLACK_BARS 0
#endif

// BioShock 2
#ifndef LUT_SAMPLING_ERROR_EMULATION_MODE
#define LUT_SAMPLING_ERROR_EMULATION_MODE 1
#endif

// BioShock 2
// it's better to keep this disabled by default, given that in the game's calibration menu, the image would end up telling that it's calibrated at a gamma of ~1 (two steps down from the default of 1.2)
// TODO: re-enable if it's too dark?
#ifndef DEFAULT_GAMMA_RAMP_EMULATION_MODE
#define DEFAULT_GAMMA_RAMP_EMULATION_MODE 0
#endif

#endif // SRC_GAME_SETTINGS_HLSL