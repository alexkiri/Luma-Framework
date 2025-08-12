#define GAME_THIEF 1

#include "..\..\Core\core.hpp"

namespace
{
   ShaderHashesList shader_hashes_FinalPostProcess;
   ShaderHashesList shader_hashes_BlackBars;

	bool remove_black_bars = false;
}

class Thief final : public Game
{
public:
   void OnLoad(std::filesystem::path& file_path, bool failed) override
   {
      if (std::filesystem::is_regular_file(file_path.parent_path().append("d3dcompiler_47.dll")))
      {
         MessageBoxA(game_window, "Please delete \"d3dcompiler_47.dll\" from the game's executable path,\n\"Luma\" works better without it (Windows already includes the latest version).", NAME, MB_SETFOREGROUND);
      }
   }

   // The final swapchain copy is through an sRGB view, whether the swapchain is sRGB or not (we force it to not be sRGB, because sRGB swapchains don't support flip models).
   bool ForceVanillaSwapchainLinear() const { return true; }

   void OnInit(bool async) override
   {
      std::vector<ShaderDefineData> game_shader_defines_data = {
         {"TONEMAP_TYPE", '1', false, false, "0 - SDR: Vanilla\n1 - HDR: Vanilla+"},
      };
      shader_defines_data.append_range(game_shader_defines_data);
      // The game was SDR all along, no gamma applied //TODOFT: verify that... there's sRGB views, but are they mirrored in and out? Because if so, then there's no gamma applied anyway (?)
      GetShaderDefineData(POST_PROCESS_SPACE_TYPE_HASH).SetDefaultValue('0');
      GetShaderDefineData(VANILLA_ENCODING_TYPE_HASH).SetDefaultValue('0');
      GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');
      GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('0');
   }

   bool OnDrawCustom(ID3D11Device* native_device, ID3D11DeviceContext* native_device_context, DeviceData& device_data, reshade::api::shader_stage stages, const ShaderHashesList<OneShaderPerPipeline>& original_shader_hashes, bool is_custom_pass, bool& updated_cbuffers) override
   {
      if (!device_data.has_drawn_main_post_processing && original_shader_hashes.Contains(shader_hashes_FinalPostProcess))
      {
         device_data.has_drawn_main_post_processing = true;
      }
      else if (remove_black_bars && device_data.has_drawn_main_post_processing && original_shader_hashes.Contains(shader_hashes_BlackBars))
      {
         return true;
      }
      return false;
   }

   void OnPresent(ID3D11Device* native_device, DeviceData& device_data) override
   {
      device_data.has_drawn_main_post_processing_previous = device_data.has_drawn_main_post_processing;
      device_data.has_drawn_main_post_processing = false;
   }

   void LoadConfigs() override
   {
      reshade::api::effect_runtime* runtime = nullptr;
      reshade::get_config_value(runtime, NAME, "RemoveBlackBars", remove_black_bars);
   }

   void DrawImGuiSettings(DeviceData& device_data) override
   {
      reshade::api::effect_runtime* runtime = nullptr;

      if (ImGui::Checkbox("Remove Black Bars", &remove_black_bars))
      {
         reshade::set_config_value(runtime, NAME, "RemoveBlackBars", remove_black_bars);
      }
      if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
      {
         ImGui::SetTooltip("At non 16:9 resolutions, the game might display black bars in some scenes, this will remove them.");
      }
   }

   void PrintImGuiAbout() override
   {
      ImGui::Text("Luma for \"Thief\" is developed by Pumbo and is open source and free.\nIf you enjoy it, consider donating.", "");

      const auto button_color = ImGui::GetStyleColorVec4(ImGuiCol_Button);
      const auto button_hovered_color = ImGui::GetStyleColorVec4(ImGuiCol_ButtonHovered);
      const auto button_active_color = ImGui::GetStyleColorVec4(ImGuiCol_ButtonActive);
      ImGui::PushStyleColor(ImGuiCol_Button, IM_COL32(70, 134, 0, 255));
      ImGui::PushStyleColor(ImGuiCol_ButtonHovered, IM_COL32(70 + 9, 134 + 9, 0, 255));
      ImGui::PushStyleColor(ImGuiCol_ButtonActive, IM_COL32(70 + 18, 134 + 18, 0, 255));
      static const std::string donation_link_pumbo = std::string("Buy Pumbo a Coffee ") + std::string(ICON_FK_OK);
      if (ImGui::Button(donation_link_pumbo.c_str()))
      {
         system("start https://buymeacoffee.com/realfiloppi");
      }
      ImGui::PopStyleColor(3);

      ImGui::NewLine();
      // Restore the previous color, otherwise the state we set would persist even if we popped it
      ImGui::PushStyleColor(ImGuiCol_Button, button_color);
      ImGui::PushStyleColor(ImGuiCol_ButtonHovered, button_hovered_color);
      ImGui::PushStyleColor(ImGuiCol_ButtonActive, button_active_color);
#if 0
      static const std::string mod_link = std::string("Nexus Mods Page ") + std::string(ICON_FK_SEARCH);
      if (ImGui::Button(mod_link.c_str()))
      {
         system("start https://www.nexusmods.com/prey2017/mods/149");
      }
#endif
      static const std::string social_link = std::string("Join our \"HDR Den\" Discord ") + std::string(ICON_FK_SEARCH);
      if (ImGui::Button(social_link.c_str()))
      {
         // Unique link for Luma by Pumbo (to track the origin of people joining), do not share for other purposes
         static const std::string obfuscated_link = std::string("start https://discord.gg/J9fM") + std::string("3EVuEZ");
         system(obfuscated_link.c_str());
      }
      static const std::string contributing_link = std::string("Contribute on Github ") + std::string(ICON_FK_FILE_CODE);
      if (ImGui::Button(contributing_link.c_str()))
      {
         system("start https://github.com/Filoppi/Luma");
      }
      ImGui::PopStyleColor(3);

      ImGui::NewLine();
      ImGui::Text("Credits:"
         "\n\nMain:"
         "\nPumbo"

         "\n\nThird Party:"
         "\nReShade"
         "\nImGui"
         "\nRenoDX"
         "\n3Dmigoto"
         "\nOklab"
         "\nDICE (HDR tonemapper)"
         , "");
   }
};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
   if (ul_reason_for_call == DLL_PROCESS_ATTACH)
   {
      Globals::GAME_NAME = PROJECT_NAME;
      Globals::DESCRIPTION = "Thief (2014) Luma mod";
      Globals::WEBSITE = "";
      Globals::VERSION = 1;

      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12;

      // Needed as the UI can both generate NaNs (I think) and also do subtractive blends that result in colors with invalid (or overly low) luminances,
      // thus drawing it separately and composing it on top, is better.
      // The game also casts a TYPELESS texture as UNORM, while it was previously cast as UNORM_SRGB (linear) (float textures can't preserve this behaviour)
      enable_separate_ui_drawing = false; //TODOFT

      enable_swapchain_upgrade = true;
      swapchain_upgrade_type = 1;
      enable_texture_format_upgrades = true;
      texture_upgrade_formats = {
            reshade::api::format::r8g8b8a8_unorm,
            reshade::api::format::r8g8b8a8_unorm_srgb,
            reshade::api::format::r8g8b8a8_typeless,

            // For some reason thief used these as high quality SDR buffers (it seems like a mistake, but possibly the intention was to have higher quality in post processing)
            reshade::api::format::r16g16b16a16_unorm,

            reshade::api::format::r11g11b10_float,
      };

      shader_hashes_FinalPostProcess.pixel_shaders.emplace(std::stoul("CDC104C3", nullptr, 16)); // Final order is Tonemap->FXAA(optional)->PP(optional)
      shader_hashes_UI_excluded.pixel_shaders = { std::stoul("47FB9170", nullptr, 16), std::stoul("A394022E", nullptr, 16), std::stoul("1EAE8451", nullptr, 16), std::stoul("CDC104C3", nullptr, 16) };
      shader_hashes_BlackBars.pixel_shaders.emplace(std::stoul("E9255521", nullptr, 16));

      game = new Thief();
   }

   CoreMain(hModule, ul_reason_for_call, lpReserved);

   return TRUE;
}