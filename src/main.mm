#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "SteakEngine.hpp"

static void (*KnifeGameLogic_addMeatballs)(id, SEL, long long);

void my_addMeatballs(id self, SEL _cmd, long long param_3) {
    SteakEngine::log(@"I HOOKED THE FUNCTION!!!!!!!!!!!!!!!!!!");
    // Call the original function if needed
    ((void (*)(id, SEL, long long))original_addMeatballs)(self, _cmd, param_3);
}

__attribute__((constructor))
static void initialize() {
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);

	SteakEngine::lua::init(L);

	Method method = class_getInstanceMethod(objc_getClass("KnifeGameLogic"), @selector(addMeatballs:param2:param3:));
	IMP original_imp = method_getImplementation(method);

	original_addMeatballs = (void (*)(id, SEL, long long))original_imp;

	rebind_symbols((struct rebinding[1]){{"addMeatballs:param2:param3:", (void *)my_addMeatballs, (void **)&KnifeGameLogic_addMeatballs}}, 1);

	if (luaL_dostring(L, "Log('Hello from lua.')") != LUA_OK) {
		SteakEngine::log([@"Error: " stringByAppendingString:[NSString stringWithUTF8String:lua_tostring(L, -1)]]);
	}
}
