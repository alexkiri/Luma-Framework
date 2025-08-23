#pragma once

#include <stdint.h>

constexpr float srgb_white_level = 80;
constexpr float default_paper_white = 203; // ITU White Level
constexpr float default_peak_white = 1000;

namespace Globals
{
	// Don't change this unless you have a reason to. There might be some other references to this name hardcoded in other strings.
	static const char* MOD_NAME = "Luma";
	// The following are meant to be replaced per game:
	static char GAME_NAME[64] = "Template";
	static char DESCRIPTION[256] = "Template Luma mod";
	static char WEBSITE[256] = "";
	static uint32_t VERSION = 1; // Internal version (not public facing, no major/minor/revision versioning yet). Always starts from 1. Remember to manually add a check if you delete shaders in between versions and you want to force remove them from people's installations too.
	static bool EXPERIMENTAL = false; // Set to true if the mod is still in development/testing etc

	__forceinline void SetGlobals(const char* game_name, const char* mod_description = "", const char* mod_website = "", uint32_t mod_version = 0)
	{
		// We should complain if the attempted written size is greater but whatever
		strncpy(GAME_NAME, game_name, sizeof(GAME_NAME));
		GAME_NAME[sizeof(GAME_NAME) - 1] = '\0'; // ensure null-termination
		strncpy(DESCRIPTION, mod_description, sizeof(DESCRIPTION));
		DESCRIPTION[sizeof(DESCRIPTION) - 1] = '\0';
		strncpy(WEBSITE, mod_website, sizeof(WEBSITE));
		WEBSITE[sizeof(WEBSITE) - 1] = '\0';

		if (mod_version != 0 && mod_version != uint32_t(-1))
		{
			VERSION = mod_version;
		}
	}
}