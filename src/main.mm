#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "SteakEngine.hpp"

static int (*RunningObject_meatballs)(id, SEL);

int my_meatballs(id self, SEL _cmd) {
    SteakEngine::log(@"I HOOKED THE FUNCTION!!!!!!!!!!!!!!!!!!");

    return ((int (*)(id, SEL))RunningObject_meatballs)(self, _cmd);
}

__attribute__((constructor))
static void initialize() {
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);

	SteakEngine::lua::init(L);

	Method method = class_getInstanceMethod(objc_getClass("RunningObject"), @selector(meatballs:param2:));
	IMP original_imp = method_getImplementation(method);

	RunningObject_meatballs = (int (*)(id, SEL))original_imp;

	rebind_symbols((struct rebinding[1]){{"meatballs:param2:", (void *)my_meatballs, (void **)&RunningObject_meatballs}}, 1);

	if (luaL_dostring(L, "Log('Hello from lua.')") != LUA_OK) {
		SteakEngine::log([@"Error: " stringByAppendingString:[NSString stringWithUTF8String:lua_tostring(L, -1)]]);
	}
}
