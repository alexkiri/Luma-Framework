// -----------------------------------------------------------------------------
// This code is based on work by gir489
// Source: https://bitbucket.org/gir489/bioshock2crashfix/
// -----------------------------------------------------------------------------

// Adds logging and a stack walker
//#define LOGGING_ENABLED

#include "BS2_CrashFix.h"

#include <windows.h>
#include <fstream>
#include <intrin.h>
#include <atomic>

#ifdef LOGGING_ENABLED
#include <string>
#include <dbghelp.h>
#include <sstream>
#include <format>

#pragma comment(lib, "DbgHelp.lib")
#endif

// Luma: the original project disable "4996" but that doesn't seem to be needed
// TODO: find clang equivalent, but it doesn't seem to send any warnings
#pragma warning(disable: 4731)

namespace
{
	HANDLE fix_thread = NULL;
	std::atomic<bool> fix_thread_done{ false };

	DWORD crash_one_failure_return;
	DWORD crash_one_return;
	DWORD crash_three_failure_return;
	DWORD crash_three_return;
	DWORD crash_four_return;
	DWORD crash_five_failure_return;
	DWORD crash_five_return;
	DWORD crash_six_return;
	DWORD crash_seven_return;
	DWORD crash_seven_failure_return;
}

#ifdef LOGGING_ENABLED
static std::string get_stack_trace(const CONTEXT* ctx = nullptr)
{
	const auto process = GetCurrentProcess();
	const auto hThread = GetCurrentThread();

	CONTEXT context{};

	if (ctx) {
		context = *ctx;
	}
	else {
		RtlCaptureContext(&context);
	}

	STACKFRAME frame{};
	frame.AddrPC.Offset = context.Eip;
	frame.AddrPC.Mode = AddrModeFlat;
	frame.AddrStack.Offset = context.Esp;
	frame.AddrStack.Mode = AddrModeFlat;
	frame.AddrFrame.Offset = context.Ebp;
	frame.AddrFrame.Mode = AddrModeFlat;

	const auto handle = ImageNtHeader(GetModuleHandle(nullptr));
	const auto image_type = handle->FileHeader.Machine;

	SymInitialize(process, nullptr, TRUE);
	SymSetOptions(SYMOPT_LOAD_LINES);

	std::stringstream str;

	for (auto i = 0; i < 16; i++)
	{
		if (!StackWalk(image_type, process, hThread, &frame, &context, nullptr, SymFunctionTableAccess, SymGetModuleBase, nullptr))
			break;

		if (frame.AddrPC.Offset == 0)
			break;

		HMODULE module = nullptr;
#ifdef UNICODE // TODO: broken with UNICODE, "frame.AddrPC.Offset" isn't a wchar
		wchar_t buffer[MAX_PATH];
		if (GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, reinterpret_cast<LPCWSTR>(frame.AddrPC.Offset), &module))
#else
		char buffer[MAX_PATH];
		if (GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, reinterpret_cast<LPCSTR>(frame.AddrPC.Offset), &module))
#endif
		{
			GetModuleFileName(module, buffer, MAX_PATH - 1);
		}

		DWORD displacement;
#ifdef UNICODE
		IMAGEHLP_LINEW line;
		if (module && SymGetLineFromAddrW(GetCurrentProcess(), frame.AddrPC.Offset, &displacement, &line))
#else
		IMAGEHLP_LINE line;
		if (module && SymGetLineFromAddr(GetCurrentProcess(), frame.AddrPC.Offset, &displacement, &line))
#endif
		{
			// Do we have symbols?
			str << std::format("{}: Line {}", line.FileName, line.LineNumber) << std::endl;
		}
		// Is the address in a module?
		else if (module) {
			str << std::format("{}+0x{:X} [0x{:X}]", buffer, frame.AddrPC.Offset - reinterpret_cast<DWORD>(module), frame.AddrPC.Offset) << std::endl;
		}
		// No symbols or module, just use address.
		else
		{
			str << std::format("0x{:X} [0x{:X}]", frame.AddrPC.Offset - reinterpret_cast<DWORD>(module), frame.AddrPC.Offset) << std::endl;
		}
	}

	SymCleanup(process);

	return str.str();
};

int crash_one_times{};
int crash_three_times{};
int crash_four_times{};
int crash_five_times{};
int crash_six_times{};
int crash_seven_times{};
#endif

#define HEX_TO_UPPER(value) "0x" << std::hex << std::uppercase << (DWORD)value << std::dec << std::nouppercase

bool __fastcall
#if defined(__clang__)
__attribute__((fastcall))
#endif
isReadableWritablePointer(PVOID p)
{
	MEMORY_BASIC_INFORMATION info;
	if (VirtualQuery(p, &info, sizeof(info)) == sizeof(info)) {
		if (info.State == MEM_COMMIT) {
			DWORD protect = info.Protect;
			if (!(protect & PAGE_GUARD) && !(protect & PAGE_NOACCESS)) {
				if (protect & PAGE_READONLY || protect & PAGE_READWRITE ||
					protect & PAGE_WRITECOPY || protect & PAGE_EXECUTE_READ ||
					protect & PAGE_EXECUTE_READWRITE || protect & PAGE_EXECUTE_WRITECOPY) {
					return true;
				}
			}
		}
	}
	return false;
}

__declspec(naked)
#if defined(__clang__)
__attribute__((naked))
#endif
void crash_one_fix()
{
	__asm
	{
		mov eax, [edi+0x44]
		pushad
		mov ecx, eax
		call isReadableWritablePointer
		test al, al
		popad
		jz crash_one_failure_return_label
		cmp dword ptr[eax], 0
	jmp crash_one_return
crash_one_failure_return_label:
#ifdef LOGGING_ENABLED
		inc crash_one_times
#endif
		jmp crash_one_failure_return
	}
}

__declspec(naked)
#if defined(__clang__)
__attribute__((naked))
#endif
void crash_three_fix()
{
	__asm
	{
		mov eax, [eax+0x44]
		pushad
		mov ecx, eax
		call isReadableWritablePointer
		test al, al
		popad
		jz crash_three_failure_return_label
		mov ecx, [eax]
	jmp crash_three_return
crash_three_failure_return_label:
#ifdef LOGGING_ENABLED
		inc crash_three_times
#endif
		jmp crash_three_failure_return
	}
}

__declspec(naked)
#if defined(__clang__)
__attribute__((naked))
#endif
void crash_four_fix()
{
	__asm
	{
		add ecx, [edi+edx*4+0x208]
		pushad
		call isReadableWritablePointer
		test al, al
		popad
		jz crash_four_failure_return_label
		cmp[ecx+0x10], eax
	jmp crash_four_return
crash_four_failure_return_label:
#ifdef LOGGING_ENABLED
		inc crash_four_times
#endif
		jmp crash_four_return
	}
}

__declspec(naked)
#if defined(__clang__)
__attribute__((naked))
#endif
void crash_five_fix()
{
	__asm
	{
		mov eax, [edi]
		pushad
		mov ecx, eax
		call isReadableWritablePointer
		test al, al
		popad
		mov eax, [esi+0x0C]
		jz crash_five_failure_return_label
		push [edi]
	jmp crash_five_return
crash_five_failure_return_label:
#ifdef LOGGING_ENABLED
		inc crash_five_times
#endif
		jmp crash_five_failure_return
	}
}

__declspec(naked)
#if defined(__clang__)
__attribute__((naked))
#endif
void crash_six_fix()
{
	__asm
	{
		mov eax, [esp+4]
		test eax, eax
		jz crash_six_failure_return_label
		push ebp
		mov ebp, esp
		push -01
		jmp crash_six_return
crash_six_failure_return_label:
#ifdef LOGGING_ENABLED
		inc crash_six_times
#endif
		retn 0x14
	}
}

__declspec(naked)
#if defined(__clang__)
__attribute__((naked))
#endif
void crash_seven_fix()
{
	__asm
	{
		je crash_seven_failure_return_label_no_log
		pushad
		mov ecx, eax
		call isReadableWritablePointer
		test al, al
		popad
		jz crash_seven_failure_return_label
		cmp [eax+0xC], edi
		jmp crash_seven_return
crash_seven_failure_return_label:
#ifdef LOGGING_ENABLED
		inc crash_seven_times
#endif
crash_seven_failure_return_label_no_log:
		jmp crash_seven_failure_return
	}
}

#ifdef LOGGING_ENABLED
void log_crash(std::string crash_type)
{
	static std::ofstream log("CrashFix.log", std::ios::app);

	auto now = std::chrono::system_clock::now();
	auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
	auto timer = std::chrono::system_clock::to_time_t(now);
	auto local_time = *std::localtime(&timer);

	log << "[" << std::put_time(&local_time, "%m/%d/%Y %I:%M:%S") << ":" << std::setfill('0') << std::setw(3) << ms.count() << " " << std::put_time(&local_time, "%p") << "] Caught " << crash_type << " crash." << std::endl;
}
#endif

void error_logger_function(const wchar_t* a1, ...)
{
#ifdef LOGGING_ENABLED
	wchar_t Buffer[4096];
	va_list ArgList;

	va_start(ArgList, a1);
	vswprintf(Buffer, 4096, a1, ArgList);
	va_end(ArgList);

	std::wstring wstr(Buffer);
	std::wstring_convert<std::codecvt_utf8<wchar_t>, wchar_t> converter;
	std::string str = converter.to_bytes(wstr);

	std::ostringstream o;
	o << "[ERROR_LOGGER]: message " << str << std::endl <<" Stack Trace: " << std::endl << get_stack_trace();
	log_crash(o.str());
#endif
}

// Call this on "DLL_PROCESS_ATTACH". Once the fix has applied, there's nothing else to be done and it can't be de-applied.
void ApplyCrashFix()
{
	fix_thread = CreateThread(nullptr, 0, [](PVOID) -> DWORD {
		// TODO: These are probably Steam build specific, add support for Epic store? Or is it identical there?
		const auto Bioshock2HDEXE = reinterpret_cast<DWORD>(GetModuleHandle(NULL));
		crash_one_failure_return = Bioshock2HDEXE + 0xC1CADB;
		crash_one_return = Bioshock2HDEXE + 0xC1C96D;
		crash_three_failure_return = Bioshock2HDEXE + 0x4FF1C8;
		crash_three_return = Bioshock2HDEXE + 0x4FF100;
		crash_four_return = Bioshock2HDEXE + 0x3087B2;
		crash_five_failure_return = Bioshock2HDEXE + 0xBE17DB;
		crash_five_return = Bioshock2HDEXE + 0xBE17D5;
		crash_six_return = Bioshock2HDEXE + 0xBF3035;
		crash_seven_return = Bioshock2HDEXE + 0x73739A;
		crash_seven_failure_return = Bioshock2HDEXE + 0x7373C0;

		DWORD oldProtect;
		DWORD relativeAddress;

		PVOID crash_one_location = reinterpret_cast<PVOID>(Bioshock2HDEXE + 0xC1C967);
		BYTE crash_one_array[] = { 0xE9, 0x00, 0x00, 0x00, 0x00, 0x90 };
		VirtualProtect(crash_one_location, sizeof(crash_one_array), PAGE_EXECUTE_READWRITE, &oldProtect);
		relativeAddress = ((((DWORD)&crash_one_fix)) - (DWORD)crash_one_location) - 5;
		*(DWORD*)(crash_one_array + 1) = relativeAddress;
		memcpy(crash_one_location, crash_one_array, sizeof(crash_one_array));
		VirtualProtect(crash_one_location, sizeof(crash_one_array), oldProtect, &oldProtect);

		PVOID crash_three_location = reinterpret_cast<PVOID>(Bioshock2HDEXE + 0x4FF0FB);
		BYTE crash_three_array[] = { 0xE9, 0x00, 0x00, 0x00, 0x00 };
		VirtualProtect(crash_three_location, sizeof(crash_three_array), PAGE_EXECUTE_READWRITE, &oldProtect);
		relativeAddress = ((((DWORD)&crash_three_fix)) - (DWORD)crash_three_location) - 5;
		*(DWORD*)(crash_three_array + 1) = relativeAddress;
		memcpy(crash_three_location, crash_three_array, sizeof(crash_three_array));
		VirtualProtect(crash_three_location, sizeof(crash_three_array), oldProtect, &oldProtect);

		PVOID crash_four_location = reinterpret_cast<PVOID>(Bioshock2HDEXE + 0x3087A8);
		BYTE crash_four_array[] = { 0xE9, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x1F, 0x44, 0x00, 0x00 };
		VirtualProtect(crash_four_location, sizeof(crash_four_array), PAGE_EXECUTE_READWRITE, &oldProtect);
		relativeAddress = ((((DWORD)&crash_four_fix)) - (DWORD)crash_four_location) - 5;
		*(DWORD*)(crash_four_array + 1) = relativeAddress;
		memcpy(crash_four_location, crash_four_array, sizeof(crash_four_array));
		VirtualProtect(crash_four_location, sizeof(crash_four_array), oldProtect, &oldProtect);

		PVOID crash_five_location = reinterpret_cast<PVOID>(Bioshock2HDEXE + 0xBE17D0);
		BYTE crash_five_array[] = { 0xE9, 0x00, 0x00, 0x00, 0x00 };
		VirtualProtect(crash_five_location, sizeof(crash_five_array), PAGE_EXECUTE_READWRITE, &oldProtect);
		relativeAddress = ((((DWORD)&crash_five_fix)) - (DWORD)crash_five_location) - 5;
		*(DWORD*)(crash_five_array + 1) = relativeAddress;
		memcpy(crash_five_location, crash_five_array, sizeof(crash_five_array));
		VirtualProtect(crash_five_location, sizeof(crash_five_array), oldProtect, &oldProtect);

		PVOID reverb_bytes_location = reinterpret_cast<PVOID>(Bioshock2HDEXE + 0xC2EE5D);
		BYTE reverb_bytes_array[] = { 0x90, 0xE9 };
		VirtualProtect(reverb_bytes_location, sizeof(reverb_bytes_array), PAGE_EXECUTE_READWRITE, &oldProtect);
		memcpy(reverb_bytes_location, reverb_bytes_array, sizeof(reverb_bytes_array));
		VirtualProtect(reverb_bytes_location, sizeof(reverb_bytes_array), oldProtect, &oldProtect);

		PVOID app_error_location = reinterpret_cast<PVOID>(Bioshock2HDEXE + 0xB55970);
		BYTE app_error_array[] = { 0xE9, 0x00, 0x00, 0x00, 0x00 };
		VirtualProtect(app_error_location, sizeof(app_error_array), PAGE_EXECUTE_READWRITE, &oldProtect);
		relativeAddress = (((DWORD)&error_logger_function) - (DWORD)app_error_location) - 5;
		*(DWORD*)(app_error_array + 1) = relativeAddress;
		memcpy(app_error_location, app_error_array, sizeof(app_error_array));
		VirtualProtect(app_error_location, sizeof(app_error_array), oldProtect, &oldProtect);

		PVOID crash_six_location = reinterpret_cast<PVOID>(Bioshock2HDEXE + 0xBF3030);
		BYTE crash_six_array[] = { 0xE9, 0x00, 0x00, 0x00, 0x00 };
		VirtualProtect(crash_six_location, sizeof(crash_six_array), PAGE_EXECUTE_READWRITE, &oldProtect);
		relativeAddress = ((((DWORD)&crash_six_fix)) - (DWORD)crash_six_location) - 5;
		*(DWORD*)(crash_six_array + 1) = relativeAddress;
		memcpy(crash_six_location, crash_six_array, sizeof(crash_six_array));
		VirtualProtect(crash_six_location, sizeof(crash_six_array), oldProtect, &oldProtect);

		PVOID crash_seven_location = reinterpret_cast<PVOID>(Bioshock2HDEXE + 0x737395);
		BYTE crash_seven_array[] = { 0xE9, 0x00, 0x00, 0x00, 0x00 };
		VirtualProtect(crash_seven_location, sizeof(crash_seven_array), PAGE_EXECUTE_READWRITE, &oldProtect);
		relativeAddress = ((((DWORD)&crash_seven_fix)) - (DWORD)crash_seven_location) - 5;
		*(DWORD*)(crash_seven_array + 1) = relativeAddress;
		memcpy(crash_seven_location, crash_seven_array, sizeof(crash_seven_array));
		VirtualProtect(crash_seven_location, sizeof(crash_seven_array), oldProtect, &oldProtect);

#ifdef LOGGING_ENABLED
		while (TRUE)
		{
			static int last_crash_one_times{}, last_crash_three_times{}, last_crash_four_times{}, last_crash_five_times{},
				last_crash_six_times, last_crash_seven_times{};

			if (last_crash_one_times != crash_one_times)
			{
				log_crash("FMOD");
				last_crash_one_times = crash_one_times;
			}

			if (last_crash_three_times != crash_three_times)
			{
				log_crash("ALT+TAB");
				last_crash_three_times = crash_three_times;
			}

			if (last_crash_four_times != crash_four_times)
			{
				log_crash("Memory release");
				last_crash_four_times = crash_four_times;
			}

			if (last_crash_five_times != crash_five_times)
			{
				log_crash("D3D11DeviceContext_End");
				last_crash_five_times = crash_five_times;
			}

			if (last_crash_six_times != crash_six_times)
			{
				log_crash("BinkCopyToBuffer");
				last_crash_six_times = crash_six_times;
			}

			if (last_crash_seven_times != crash_seven_times)
			{
				log_crash("FMOD::EventGroupI::getEventByIndex crash");
				last_crash_seven_times = crash_seven_times;
			}

			Sleep(100);
		}
#endif

		fix_thread_done = true;

		ExitThread(0);
		}, nullptr, 0, nullptr);
}

// This does not de-apply the fix, it simply makes sure the thread has stopped. Call on "DLL_PROCESS_DETACH"
void CloseCrashFix()
{
	if (fix_thread != NULL)
	{
		while (!fix_thread_done) { }
		fix_thread = NULL;
	}
}