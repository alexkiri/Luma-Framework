#define GAME_DXHRDC 1

#define ENABLE_GAME_PIPELINE_STATE_READBACK 1

#include "..\..\Core\core.hpp"

class GameDeusExHumanRevolutionDC final : public Game
{
public:
   void OnInit(bool async) override
   {
      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12; // ### Update this (find the right value) ###
   }

   // The order of drawing is:
   // Write some LUT (?) from the CPU
   // Clear Normal Maps and Depth
   // Draw Normap Maps and Depth
   // Draw some shadow map, rudimentary AO, possibly from the angles of normal maps and depth (this looks right at any aspect ratio and resolution, though it's got bad screen space noise). This is stored in the alpha of the normal map buffer
   // Clear the new target texture
   // Draw some basic lighting buffer (mesh by mesh?)
   // Clear the new target texture (swapchain) (to beige)
   // Draw the final "composed" scene color (in gamma space), directly on the swapchain, mesh by mesh, starting from lights, to normal meshes (including skinner/characters), to transparency and fog, and then emissive etc. The alpha channel contrains the bloom/emissivness amount
   // Copy the swapchain texture
   // Apply decals
   // Another copy?
   // Apply color filter? Nah
   // Generate bloom (and DoF?)
   // Apply bloom (~additive)
   // Do post process...?
   // Apply grading (e.g. golden filter, contrast etc)
   // Draw UI (directly on swapchain)
   // Present

   void PrintImGuiAbout() override
   {
      ImGui::Text("Deus Ex: Human Revolution - Director's Cut mod - about and credits section", ""); // ### Rename this ###
      // It might work with the non Director's Cut version of the game too
      // This is fully compatible with the Yellow Filter Restored mod, and executes after it
   }
};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
   if (ul_reason_for_call == DLL_PROCESS_ATTACH)
   {
      Globals::SetGlobals(PROJECT_NAME, "Deus Ex: Human Revolution - Director's Cut Luma mod");
      Globals::VERSION = 1;

      enable_swapchain_upgrade = true;
      swapchain_upgrade_type = 1;
      enable_texture_format_upgrades = true;
      // ### Check which of these are needed and remove the rest ###
      texture_upgrade_formats = {
            reshade::api::format::r8g8b8a8_unorm,
            //reshade::api::format::r8g8b8a8_unorm_srgb,
            //reshade::api::format::r8g8b8a8_typeless,
            reshade::api::format::r8g8b8x8_unorm,
            //reshade::api::format::r8g8b8x8_unorm_srgb,
            reshade::api::format::b8g8r8a8_unorm,
            //reshade::api::format::b8g8r8a8_unorm_srgb,
            //reshade::api::format::b8g8r8a8_typeless,
            reshade::api::format::b8g8r8x8_unorm,
            //reshade::api::format::b8g8r8x8_unorm_srgb,
            //reshade::api::format::b8g8r8x8_typeless,

				// Used by for lighting buffers
            reshade::api::format::r10g10b10a2_unorm,

            // Probably unused, but won't hurt
            reshade::api::format::r11g11b10_float,
      };
      // ### Check these if textures are not upgraded ###
      texture_format_upgrades_2d_size_filters = 0 | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio;

      game = new GameDeusExHumanRevolutionDC();
   }

   CoreMain(hModule, ul_reason_for_call, lpReserved);

   return TRUE;
}