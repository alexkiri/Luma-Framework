#ifndef SRC_GAME_SETTINGS_HLSL
#define SRC_GAME_SETTINGS_HLSL

/////////////////////////////////////////
// Vertigo LUMA advanced settings
// (note that the defaults might be mirrored in cpp, the shader values will be overridden anyway)
/////////////////////////////////////////

// 0 SDR: Vanilla (ACES)
// 1 HDR: Pumbo Advanced AutoHDR
// 2 HDR: Oklab (suggested)
// 3 HDR: Vanilla+
#ifndef TONEMAP_TYPE
#define TONEMAP_TYPE 2
#endif // TONEMAP_TYPE

#endif // SRC_GAME_SETTINGS_HLSL