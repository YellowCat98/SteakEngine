#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "SteakEngine.hpp"
#include "swizzleMethod.hpp"

static bool (*LevelSelectorView_canSelectLevel)(id, SEL, unsigned long long);
static long long (*GameUser_meatsCount)(id, SEL);

bool my_canSelectLevel(id self, SEL _cmd, unsigned long long p0) {
    SteakEngine::log(@"\nI HOOKED THE FUNCTION!!!!!!!!!!!!!!!!!!");

    bool result = LevelSelectorView_canSelectLevel(self, _cmd, p0);

	SteakEngine::log([@"\n" stringByAppendingString:[NSString stringWithUTF8String:std::to_string(static_cast<int>(result)).c_str()]]);

    return true;
}

long long my_meatsCount(id self, SEL _cmd) {
	long long result = RunningObject_meatballs(self, _cmd);

	SteakEngine::log([@"\n" stringByAppendingString:[NSString stringWithUTF8String:std::to_string(result).c_str()]]);

	return 696969;
}

__attribute__((constructor))
static void initialize() {
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);

	SteakEngine::lua::init(L);

	Class targetClass = objc_getClass("LevelSelectorView");
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
	

	SteakEngine::swizzleMethod<bool, id, SEL, unsigned long long>(targetClass, @selector(canSelectLevel:), LevelSelectorView_canSelectLevel, my_canSelectLevel);
	SteakEngine::swizzleMethod<long long, id, SEL>(objc_getClass("GameUser"), @selector(meatsCount), GameUser_meatsCount, my_meatsCount);

	if (luaL_dostring(L, "Log('\\nHello from lua.')") != LUA_OK) {
		SteakEngine::log([@"Error: " stringByAppendingString:[NSString stringWithUTF8String:lua_tostring(L, -1)]]);
	}
}