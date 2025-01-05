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

	Class targetClass = objc_getClass("RunningMinigameViewController");
	if (!targetClass) {
		SteakEngine::log(@"\nClass not found");
	}

	Method method = class_getInstanceMethod(targetClass, @selector(bonusMeatballsGathered:));
	if (!method) {
		SteakEngine::log(@"\nMethod not found");
	}
	IMP original_imp = method_getImplementation(method);
	SteakEngine::log([NSString stringWithFormat:@"\nOriginal IMP: %p", method_getImplementation(method)]);

    IMP swizzledIMP = (IMP)my_bonusMeatballsGathered;
    method_setImplementation(method, swizzledIMP);

	if (luaL_dostring(L, "Log('\\nHello from lua.')") != LUA_OK) {
		SteakEngine::log([@"Error: " stringByAppendingString:[NSString stringWithUTF8String:lua_tostring(L, -1)]]);
	}
}
