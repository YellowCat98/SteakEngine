#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "SteakEngine.hpp"

static int (*RunningMinigameViewController_bonusMeatballsGathered)(id, SEL);

int my_bonusMeatballsGathered(id self, SEL _cmd) {
    SteakEngine::log(@"I HOOKED THE FUNCTION!!!!!!!!!!!!!!!!!!");

    return 696969;
}

__attribute__((constructor))
static void initialize() {
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);

	SteakEngine::lua::init(L);

	Method method = class_getInstanceMethod(objc_getClass("RunningMinigameViewController"), @selector(bonusMeatballsGathered:param2:));
	IMP original_imp = method_getImplementation(method);

	RunningMinigameViewController_bonusMeatballsGathered = (int (*)(id, SEL))original_imp;

	rebind_symbols((struct rebinding[1]){{"bonusMeatballsGathered:", (void *)my_bonusMeatballsGathered, (void **)&RunningMinigameViewController_bonusMeatballsGathered}}, 1);

	if (luaL_dostring(L, "Log('Hello from lua.')") != LUA_OK) {
		SteakEngine::log([@"Error: " stringByAppendingString:[NSString stringWithUTF8String:lua_tostring(L, -1)]]);
	}
}
