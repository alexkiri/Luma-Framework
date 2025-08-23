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

#if !defined(ENABLE_CHROMATIC_ABERRATION)
#define ENABLE_CHROMATIC_ABERRATION 1
#endif

#if !defined(ENABLE_FILM_GRAIN)
#define ENABLE_FILM_GRAIN 1
#endif

#if !defined(ENABLE_DITHERING)
#define ENABLE_DITHERING 1
#endif

#if !defined(ALLOW_AA)
#define ALLOW_AA 1
#endif

#if !defined(ENABLE_SHARPENING)
#define ENABLE_SHARPENING 1
#endif

#if !defined(ENABLE_AUTO_HDR)
#define ENABLE_AUTO_HDR 1
#endif

#if !defined(ENABLE_CITY_LIGHTS_BOOST)
#define ENABLE_CITY_LIGHTS_BOOST 1
#endif

#if !defined(ENABLE_LUT_EXTRAPOLATION)
#define ENABLE_LUT_EXTRAPOLATION 1
#endif

#if !defined(ENABLE_LUT_EXTRAPOLATION)
#define ENABLE_LUT_EXTRAPOLATION 1
#endif

#if !defined(EXPAND_COLOR_GAMUT)
#define EXPAND_COLOR_GAMUT 1
#endif

#if !defined(FIX_VIDEOS_COLOR_SPACE)
#define FIX_VIDEOS_COLOR_SPACE 1
#endif

#endif // SRC_GAME_SETTINGS_HLSL