#pragma once

#include "shaders.h"

using namespace Shader;

// "Sub" device data per game, subclassable.
// Make sure all variables are default initialized.
struct GameDeviceData
{
   // Empty by default
};

struct GameInfo
{
   std::string title; // Public title (e.g., "Prey (2017)")
   std::string internal_name; // Internal short name (e.g. "White Knuckle"->"WK"), can be used by shaders etc
   uint32_t id = 0; // Internal ID (enum like). 0 is unknown/generic
   std::string shader_define;
   std::vector<std::string> mod_authors; // List of authors, in importance or arbitrary order
};

// Macro to take the "id" variable name and store it as a shader define name (to avoid defining them twice)
#define MAKE_GAME_INFO(title, internal_name, id, mod_authors) { title, internal_name, id, #id, mod_authors }

// Per game implementation
class Game
{
public:
   virtual ~Game() = default; // Avoids warnings. Using the destructor is not suggested if not to clear up persistently allocated memory.

   // The mod dll loaded (before init)
   virtual void OnLoad(std::filesystem::path& file_path, bool failed = false) {}
   // The mod initialized
   virtual void OnInit(bool async) {}
   virtual void OnInitDevice(ID3D11Device* native_device, DeviceData& device_data) {}
   virtual void OnInitSwapchain(reshade::api::swapchain* swapchain) {}
   // You can create and "append" your custom device data here
   virtual void OnCreateDevice(ID3D11Device* native_device, DeviceData& device_data)
   {
      // Example data
      device_data.game = new GameDeviceData;
   }
   // You can destroy your custom device data here
   virtual void OnDestroyDeviceData(DeviceData& device_data)
   {
      delete device_data.game;
      device_data.game = nullptr;
   }
   virtual void CreateShaderObjects(DeviceData& native_device, const std::optional<std::set<std::string>>& shader_names_filter) {}
   // TODO: call OnDrawOrComputeCustom?
   // Called for every game's valid draw call (any type),
   // this is where you can override passes, add new ones, cancel other ones etc.
   // Return true to cancel the call.
   virtual bool OnDrawCustom(ID3D11Device* native_device, ID3D11DeviceContext* native_device_context, CommandListData& cmd_list_data, DeviceData& device_data, reshade::api::shader_stage stages, const ShaderHashesList<OneShaderPerPipeline>& original_shader_hashes, bool is_custom_pass, bool& updated_cbuffers) { return false; }
   // This is called every frame just before sending out the final image to the display (the swapchain).
   // You can reliable reset any per frame setting here.
   virtual void OnPresent(ID3D11Device* native_device, DeviceData& device_data) {}
   virtual void UpdateLumaInstanceDataCB(CB::LumaInstanceDataPadded& data, CommandListData& cmd_list_data, DeviceData& device_data) {}
   // Retrieves the game's "global" (main, per view, ...) cbuffer data
   virtual bool UpdateGlobalCB(const void* global_buffer_data_ptr, reshade::api::device* device) { return false; }

   // Load ReShade configs on boot
   virtual void LoadConfigs() {}
   // Triggered when the user swaps between SDR and HDR output (in the game settings, not the display state)
   virtual void OnDisplayModeChanged() {}
   // Called when users change the "advanced" settings shader defines (e.g. you can grey out certain settings based on other settings here)
   virtual void OnShaderDefinesChanged() {}
   // Draw and save your settings here
   virtual void DrawImGuiSettings(DeviceData& device_data) {}
#if DEVELOPMENT
   // Same as "DrawImGuiSettings()" but for development settings
   virtual void DrawImGuiDevSettings(DeviceData& device_data) {}
#endif // DEVELOPMENT
#if DEVELOPMENT || TEST
   // You can print game specific information here (e.g. the weapon FOV, once you got access to the projection matrix)
   virtual void PrintImGuiInfo(const DeviceData& device_data) {}
#endif
   // About and Credits section
   virtual void PrintImGuiAbout() {}

   // In case you knew, you can specify whether the game was paused here
   virtual bool IsGamePaused(const DeviceData& device_data) const { return false; }
   // Values between 0 and 0.25 are usually good
   virtual float GetTonemapUIBackgroundAmount(const DeviceData& device_data) const { return 0.f; }
   // In case your DLSS implementation had any extra resources, you can clean them up here
   virtual void CleanExtraDLSSResources(DeviceData& device_data) {}
	// Some games use a non linear swapchain, but always write to it through sRGB view, so we should essentially treat it as linear
   virtual bool ForceVanillaSwapchainLinear() const { return false; }
};