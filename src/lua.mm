#include <SteakEngine.hpp>

using namespace SteakEngine;

void lua::init(lua_State* L) {
    lua_register(L, "Log", lua::log);
}

int lua::log(lua_State* L) {
    // Check the number of arguments and make sure there's at least one string argument
    if (lua_gettop(L) < 1 || !lua_isstring(L, 1)) {
        lua_pushstring(L, "Expected a string argument to NSLog.");
        lua_error(L);
    }

    // Get the string argument from the Lua stack
    const char* message = lua_tostring(L, 1);

    // Call NSLog from Objective-C (via Foundation framework)
    SteakEngine::log([NSString stringWithUTF8String:message]);

    return 0;
}

int lua::objc_getClass(lua_State* L) {
    if (lua_gettop(L) < 1 || !lua_isstring(L, 1)) {
        lua_pushstring(L, "Expected a string argument to NSLog.");
        lua_error(L);
    }

    const char* clsname = lua_tostring(L, 1);

    Class cls = ::objc_getClass(clsname);

    lua_pushlightuserdata(L, (void *)cls);

    return 1;
}

int lua::objc_selector(lua_State* L) {
    if (lua_gettop(L) < 1 || !lua_isstring(L, 1)) {
        lua_pushstring(L, "Expected a string argument to NSLog.");
        lua_error(L);
    }

    SEL selector = NSSelectorFromString([NSString stringWithUTF8String:lua_tostring(L, 1)]);

    lua_pushlightuserdata(L, (void *)selector);

    return 1;
}