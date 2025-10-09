#include "FSR.h"

#if ENABLE_FIDELITY_SK

//#include "../FidelityFX/FidelityFX/host/backends/dx11/ffx_dx11.h"
//#include "../FidelityFX/FidelityFX/host/ffx_fsr3.h"
//#include "../FidelityFX/FidelityFX/host/ffx_fsr3upscaler.h"

#include <cstring>
#include <cassert>
#include <unordered_set>
#include <wrl/client.h>
#include <d3d11.h>

namespace FidelityFX
{
	struct FSRInstanceData : public SR::InstanceData
	{
	};

	bool FidelityFX::FSR::Init(SR::InstanceData*& data, ID3D11Device* device, IDXGIAdapter* adapter)
	{
		return false;
	}

	void FidelityFX::FSR::Deinit(SR::InstanceData*& data, ID3D11Device* optional_device)
	{
	}

	bool FidelityFX::FSR::HasInit(const SR::InstanceData* data) const
	{
		return false;
	}

	bool FidelityFX::FSR::IsSupported(const SR::InstanceData* data) const
	{
		return false;
	}

	bool FidelityFX::FSR::UpdateSettings(SR::InstanceData* data, ID3D11DeviceContext* command_list, const SR::SettingsData& settings_data)
	{
		return false;
	}

	bool FidelityFX::FSR::Draw(const SR::InstanceData* data, ID3D11DeviceContext* command_list, const DrawData& draw_data)
	{
		// TODO: restore the DX11 pipeline state here as DX11 won't do it
		return false;
	}
}

#endif