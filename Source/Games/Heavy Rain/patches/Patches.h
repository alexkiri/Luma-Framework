#pragma once

#include <stdint.h>

namespace Patches
{
	void Init(const char* name, uint32_t version = 1);
	void Uninit();

	// Returns true if successfully changed
	bool SetOutputResolution(uint32_t output_res_x, uint32_t output_res_y);
}