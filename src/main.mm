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
	} else {
		SteakEngine::log(@"Class found, getting all methods...\n");
		
		unsigned int allMethods;
		Method* methods = class_copyMethodList(targetClass, &allMethods);
		for (unsigned int i = 0; i < allMethods; i++) {
			SteakEngine::log([@"\n" stringByAppendingString:NSStringFromSelector(method_getName(methods[i]))]);
		}

		free(methods);
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
