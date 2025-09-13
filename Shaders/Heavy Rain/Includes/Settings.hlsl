#ifndef SRC_GAME_SETTINGS_HLSL
#define SRC_GAME_SETTINGS_HLSL

// Include this after the global "Settings.hlsl" file

/////////////////////////////////////////
// Heavy Rain LUMA advanced settings
// (note that the defaults might be mirrored in c++, the shader values will be overridden anyway)
/////////////////////////////////////////

#ifndef ENABLE_LUMA
#define ENABLE_LUMA 1
#endif

#ifndef ENABLE_FILM_GRAIN
#define ENABLE_FILM_GRAIN 1
#endif

#ifndef ENABLE_COLOR_GRADING
#define ENABLE_COLOR_GRADING 1
#endif

#ifndef ENABLE_POST_PROCESS_EFFECTS
#define ENABLE_POST_PROCESS_EFFECTS 1
#endif

#ifndef ENABLE_FAKE_HDR
#define ENABLE_FAKE_HDR 0
#endif

#endif // SRC_GAME_SETTINGS_HLSL