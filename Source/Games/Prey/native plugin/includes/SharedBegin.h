#include "..\..\..\..\Core\includes\globals.h"
#include <string_view>

// DKUtil re-defines a lot of random defines (from our code or ReShade's), so we need to back them up and restore them later
#ifdef DEBUG
#define DEBUG_ALT DEBUG
#undef DEBUG
#endif
#ifdef ERROR
#define ERROR_ALT ERROR
#undef ERROR
#endif

#define PLUGIN_MODE

namespace Plugin
{
    inline std::string_view NAME = Globals::GAME_NAME;
}

// This define, with this specific value, is required by DKUtil logger
#ifndef PROJECT_NAME
#define PROJECT_NAME Plugin::NAME.data()
#endif