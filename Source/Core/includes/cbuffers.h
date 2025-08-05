#pragma once

#include "shader_types.h"
#include "matrix.h"

namespace CB
{
   using namespace Math;

   // In case the per game code had not defined a custom struct, define a generic empty one. This behaviour is matched in hlsl.
#ifndef LUMA_GAME_SETTINGS_CB_STRUCT
#define LUMA_GAME_SETTINGS_CB_STRUCT
   struct LumaGameSettings
   {
      float Dummy; // hlsl doesn't support empty structs
   };
#endif

   struct LumaDevSettings
   {
      static constexpr size_t SettingsNum = 10;

      LumaDevSettings(float Value = 0.f)
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

   // Luma global settings, usually changed a max of once per frame.
   // This is mirrored in shaders (it's described there).
   struct alignas(16) LumaGlobalSettings
   {
      uint DisplayMode;
      float ScenePeakWhite;
      float ScenePaperWhite;
      float UIPaperWhite;
      uint DLSS;
      uint FrameIndex;

      LumaGameSettings GameSettings; // Custom games setting, with a per game struct

#if DEVELOPMENT // In case we disabled the "DEVELOPMENT" shader define while the code is compiled in "DEVELOPMENT" mode, we'll simply push values that aren't read by shaders
      LumaDevSettings DevSettings;
#endif // DEVELOPMENT
   };
   static_assert(sizeof(LumaGlobalSettings) % sizeof(uint32_t) == 0); // ReShade limitation, we probably don't depend on these anymore, still, it's not bad to have 4 bytes alignment, even if cbuffers are seemengly 8 byte aligned?
   static_assert(sizeof(LumaGlobalSettings) % (sizeof(uint32_t) * 4) == 0); // Apparently needed by DX
   static_assert(sizeof(LumaGlobalSettings) >= 16); // Needed by DX (there's a minimum size of 16 bytes)

   // See the hlsl declaration for more context
   struct alignas(16) LumaInstanceData
   {
      uint CustomData1; // Per call/instance data
      uint CustomData2; // Per call/instance data
      float CustomData3; // Per call/instance data
      float CustomData4; // Per call/instance data
      float2 RenderResolutionScale;
      float2 PreviousRenderResolutionScale;
#if GAME_PREY //TODOFT: find a more elegant solution. Like we could do for "LumaGlobalSettings", allow games to have their own struct for cbuffers and append it on top of the base ones.
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

   struct alignas(16) LumaUIData
   {
      uint targeting_swapchain = 0;
      uint fullscreen_menu = 0;
      uint blend_mode = 0;
      float background_tonemapping_amount = 0.f;
   };
   static_assert(sizeof(LumaUIData) % sizeof(uint32_t) == 0);
   static_assert(sizeof(LumaUIData) % (sizeof(uint32_t) * 4) == 0);
   static_assert(sizeof(LumaUIData) >= 16);
}