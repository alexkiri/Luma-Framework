#pragma once

#include "math.h"
#include "matrix.h"

namespace
{
   using namespace Math;

   struct LumaFrameDevSettings
   {
      static constexpr size_t SettingsNum = 10;

      LumaFrameDevSettings(float Value = 0.f)
      {
         for (size_t i = 0; i < SettingsNum; i++)
         {
            Settings[i] = Value;
         }
      }
      float& operator[](const size_t i)
      {
         return Settings[i];
      }
      float Settings[SettingsNum];
   };

   struct LumaFrameSettings
   {
      uint DisplayMode;
      float ScenePeakWhite;
      float ScenePaperWhite;
      float UIPaperWhite;
      uint DLSS;
// TODO: instead of defining game settings with defines, allow each game class to define its own settings struct (possibly even a dynamically generated vector with 32bit elements that can be of any type (float/uint, through a uniform), and append it at the end of this struct live when sending it to the GPU.
// In shaders code we could then add an include that appends a new "per game" struct at the bottom of the luma global settings cbuffer.
// There's a couple other alternative designs we could go for, but none of them are nice, and we want to automate it as much as possible.
#ifdef LUMA_GAME_SETTING_01
      LUMA_GAME_SETTING_01;
#endif
#ifdef LUMA_GAME_SETTING_02
      LUMA_GAME_SETTING_02;
#endif
#ifdef LUMA_GAME_SETTING_03
      LUMA_GAME_SETTING_03;
#endif
#ifdef LUMA_GAME_SETTING_04
      LUMA_GAME_SETTING_04;
#endif
#ifdef LUMA_GAME_SETTING_05
      LUMA_GAME_SETTING_05;
#endif
#if DEVELOPMENT // In case we disabled the "DEVELOPMENT" shader define while the code is compiled in "DEVELOPMENT" mode, we'll simply push values that aren't read by shaders
      LumaFrameDevSettings DevSettings;
// TODO: instead of doing this ugly stuff to make sure we are a multiple of 128 bits, append some padding live in the cbuffer allocation code.
#if LUMA_GAME_SETTINGS_NUM == 0
      float Padding = 0;
#elif LUMA_GAME_SETTINGS_NUM == 2
      float3 Padding = { 0, 0, 0 };
#elif LUMA_GAME_SETTINGS_NUM == 3
      float2 Padding = { 0, 0 };
#elif LUMA_GAME_SETTINGS_NUM == 4
      float Padding = 0;
#elif LUMA_GAME_SETTINGS_NUM != 1
      static_assert(false);
#endif
#else // !DEVELOPMENT
#if LUMA_GAME_SETTINGS_NUM == 0 || LUMA_GAME_SETTINGS_NUM == 4
      float3 Padding = { 0, 0, 0 };
#elif LUMA_GAME_SETTINGS_NUM == 1 || LUMA_GAME_SETTINGS_NUM == 5
      float2 Padding = { 0, 0 };
#elif LUMA_GAME_SETTINGS_NUM == 2
      float Padding = 0;
#else
      static_assert(false);
#endif
#endif // DEVELOPMENT
   };
   static_assert(sizeof(LumaFrameSettings) % sizeof(uint32_t) == 0); // ReShade limitation, we probably don't depend on these anymore, still, it's not bad to have 4 bytes alignment, even if cbuffers are seemengly 8 byte aligned?
   static_assert(sizeof(LumaFrameSettings) % (sizeof(uint32_t) * 4) == 0); // Apparently needed by DX
   static_assert(sizeof(LumaFrameSettings) >= 16); // Needed by DX (there's a minimum size of 16 byte)

   // See the hlsl declaration for more context
   struct LumaInstanceData
   {
      uint CustomData1; // Per call/instance data
      uint CustomData2; // Per call/instance data
      uint CustomData3; // Per call/instance data
      uint FrameIndex;
      float2 RenderResolutionScale;
      float2 PreviousRenderResolutionScale;
#if GAME_PREY //TODOFT: find a more elegant solution. Like we could do for "LumaFrameSettings", allow games to have their own struct for cbuffers and append it on top of the base ones.
      float2 CameraJitters;
      float2 PreviousCameraJitters;
#if 0 // Disabled in shaders too as they are currently unused
      Matrix44F ViewProjectionMatrix;
      Matrix44F PreviousViewProjectionMatrix;
#endif
      Matrix44F ReprojectionMatrix;
#endif // GAME_PREY
   };
   static_assert(sizeof(LumaInstanceData) % sizeof(uint32_t) == 0);
   static_assert(sizeof(LumaInstanceData) % (sizeof(uint32_t) * 4) == 0);
   static_assert(sizeof(LumaInstanceData) >= 16);

   struct LumaUIData
   {
      uint32_t targeting_swapchain = 0;
      uint32_t fullscreen_menu = 0;
      uint32_t blend_mode = 0;
      float background_tonemapping_amount = 0.f;
   };
   static_assert(sizeof(LumaUIData) % sizeof(uint32_t) == 0);
   static_assert(sizeof(LumaUIData) % (sizeof(uint32_t) * 4) == 0);
   static_assert(sizeof(LumaUIData) >= 16);
}