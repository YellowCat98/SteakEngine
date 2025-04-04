#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "SteakEngine.hpp"
#include "swizzleMethod.hpp"

static bool (*LevelSelectorView_canSelectLevel)(id, SEL, unsigned long long);
static long long (*GameUser_meatsCount)(id, SEL);
static bool (*GameUser_isFullGameUnlocked)(id, SEL);

bool my_canSelectLevel(id self, SEL _cmd, unsigned long long p0) {
    SteakEngine::log(@"\nI HOOKED THE FUNCTION!!!!!!!!!!!!!!!!!!");

    bool result = LevelSelectorView_canSelectLevel(self, _cmd, p0);

	auto keyWindow = [UIApplication sharedApplication].keyWindow;

	if (!keyWindow) return result;

	auto rootVC = keyWindow.rootViewController;
	while (rootVC.presentedViewController) {
		rootVC = rootVC.presentedViewController;
	}

	SteakEngine::log([@"\n" stringByAppendingString:[NSString stringWithUTF8String:std::to_string(static_cast<int>(result)).c_str()]]);

	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hello"
																message:@"the"
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"oK Vro.."
											style:UIAlertActionStyleDefault
											handler:nil];

	[alert addAction:okAction];

	[rootVC presentViewController:alert animated:YES completion:nil];
    return result;
}

long long my_meatsCount(id self, SEL _cmd) {
	long long result = GameUser_meatsCount(self, _cmd);

	SteakEngine::log([@"\n" stringByAppendingString:[NSString stringWithUTF8String:std::to_string(result).c_str()]]);

	return 10000000;
}

bool my_isFullGameUnlocked(id self, SEL _cmd) {

	bool result = GameUser_isFullGameUnlocked(self, _cmd);

	SteakEngine::log([@"\n" stringByAppendingString:[NSString stringWithUTF8String:std::to_string(static_cast<int>(result)).c_str()]]);

	return true;
}

__attribute__((constructor))
static void initialize() {
	/*
	SteakEngine::log(@"Hello, world...");
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);

	SteakEngine::lua::init(L);
	*/
	Class targetClass = objc_getClass("LevelSelectorView");
	/*
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
	*/
	

	SteakEngine::swizzleMethod<bool, id, SEL, unsigned long long>(targetClass, @selector(canSelectLevel:), LevelSelectorView_canSelectLevel, my_canSelectLevel);
	//SteakEngine::swizzleMethod<long long, id, SEL>(objc_getClass("GameUser"), @selector(meatsCount), GameUser_meatsCount, my_meatsCount);
	//SteakEngine::swizzleMethod<bool, id, SEL>(objc_getClass("GameUser"), @selector(isFullGameUnlocked), GameUser_isFullGameUnlocked, my_isFullGameUnlocked);
/*
	if (luaL_dostring(L, R"(
local view = UIView:create()

if not view then
	log("\nView is nil")
end

local label = UILabel:labelWithString("Hoeiaoisjdoijasdoiajsd")
if not label then
	log("\nLabel is nil")
end

-- label:setFrame(10, 10, 300, 50)
-- view:addSubview(label)
)") != LUA_OK) {
		SteakEngine::log([@"\nError: " stringByAppendingString:[NSString stringWithUTF8String:lua_tostring(L, -1)]]);
	}

	lua_close(L);
*/
}