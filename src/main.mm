#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "SteakEngine.hpp"

static bool (*LevelSelectorView_isEnoughMeatballsToUnlockLevel)(id, SEL, long long);

bool my_isEnoughMeatballsToUnlockLevel(id self, SEL _cmd, long long param_3) {
    SteakEngine::log(@"I HOOKED THE FUNCTION!!!!!!!!!!!!!!!!!!");

    return ((bool (*)(id, SEL, long long))LevelSelectorView_isEnoughMeatballsToUnlockLevel)(self, _cmd, param_3);
}

__attribute__((constructor))
static void initialize() {
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);

	SteakEngine::lua::init(L);

	Method method = class_getInstanceMethod(objc_getClass("LevelSelectorView"), @selector(isEnoughMeatballsToUnlockLevel:param2:param3:));
	IMP original_imp = method_getImplementation(method);

	LevelSelectorView_isEnoughMeatballsToUnlockLevel = (bool (*)(id, SEL, long long))original_imp;

	rebind_symbols((struct rebinding[1]){{"isEnoughMeatballsToUnlockLevel:param2:param3:", (bool *)my_isEnoughMeatballsToUnlockLevel, (bool **)&LevelSelectorView_isEnoughMeatballsToUnlockLevel}}, 1);

	if (luaL_dostring(L, "Log('Hello from lua.')") != LUA_OK) {
		SteakEngine::log([@"Error: " stringByAppendingString:[NSString stringWithUTF8String:lua_tostring(L, -1)]]);
	}
}
