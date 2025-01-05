#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "SteakEngine.hpp"

static int (*RunningMinigameViewController_bonusMeatballsGathered)();

int my_bonusMeatballsGathered() {
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
			SEL selector = method_getName(methods[i]);
			NSString *methodName = NSStringFromSelector(selector);
			SteakEngine::log([@"\nMethod: " stringByAppendingString:methodName]);

			unsigned int argumentCount = method_getNumberOfArguments(methods[i]);
			for (unsigned int j = 0; j < argumentCount; j++) {
				char argumentType[256];
				method_getArgumentType(methods[i], j, argumentType, sizeof(argumentType));
				SteakEngine::log([@"  Argument " stringByAppendingString:[NSString stringWithFormat:@"%u: %s", j, argumentType]]);
			}
		}

		free(methods);
	}



	Method method = class_getInstanceMethod(targetClass, @selector(bonusMeatballsGathered));
	if (!method) {
		SteakEngine::log(@"\nMethod not found");
	}

	RunningMinigameViewController_bonusMeatballsGathered = (int (*)())method_getImplementation(method);

    IMP swizzledIMP = (IMP)my_bonusMeatballsGathered;
    method_setImplementation(method, swizzledIMP);

	SteakEngine::log([NSString stringWithFormat:@"\nSwizzled IMP: %p", swizzledIMP]);

	if (luaL_dostring(L, "Log('\\nHello from lua.')") != LUA_OK) {
		SteakEngine::log([@"Error: " stringByAppendingString:[NSString stringWithUTF8String:lua_tostring(L, -1)]]);
	}
}