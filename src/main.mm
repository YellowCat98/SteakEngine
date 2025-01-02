#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "SteakEngine.hpp"

__attribute__((constructor))
static void initialize() {
	lua_State* L = luaL_newstate();
	luaL_openLibs(L);

	if (luaL_dostring(L, "print('Hello from lua.')") != LUA_OK) {
		SteakEngine::utils::log([@"Error: " stringByAppendingString:[NSString stringWithUTF8String:lua_tostring(L, -1)]]);
	}
}
