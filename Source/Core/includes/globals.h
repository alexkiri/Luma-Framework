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
	static const char* GAME_NAME = "Template";
	static const char* DESCRIPTION = "Template Luma mod";
	static const char* WEBSITE = "";
	static uint32_t VERSION = 1; // Internal version (not public facing, no major/minor/revision versioning yet). Always starts from 1. Remember to manually add a check if you delete shaders in between versions and you want to force remove them from people's installations too.
}