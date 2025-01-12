#include <SteakEngine.hpp>

using namespace SteakEngine;

Class SteakEngine::lua::lastBoundClass = Nil;

void lua::init(lua_State* L) {
	lua_register(L, "log", lua::log);
	lua::bindClass(L, "UIView");
	lua::bindClass(L, "UILabel");
	lua::bindClass(L, "UIButton");
	lua::bindClass(L, "UITextField");
	lua::bindClass(L, "UITextView");
	lua::bindClass(L, "UIImageView");
	lua::bindClass(L, "UISlider");
	lua::bindClass(L, "UISwitch");
	lua::bindClass(L, "UITableView");
	lua::bindClass(L, "UICollectionView");
	lua::bindClass(L, "UIStackView");
	lua::bindClass(L, "UIActivityIndicatorView");
	lua::bindClass(L, "UIAlertController");
	lua::bindClass(L, "UIScrollView");
	lua::bindClass(L, "UIDatePicker");
	lua::bindClass(L, "UIPickerView");
	lua::bindClass(L, "UIPageViewController");
	lua::bindClass(L, "UIViewController");
}

void lua::bindMethod(lua_State* L, Class cls, Method method) {
	const char* name = sel_getName(method_getName(method));
	

	//if (strcmp(name, "class") == 0 || strcmp(name, "initialize") == 0) return;
	SteakEngine::log([NSString stringWithFormat:@"\nBinding Method %s\n", name]);

	lua_pushstring(L, name);
	lua_pushlightuserdata(L, method);
	lua_pushcclosure(L, [](lua_State* L) -> int {
		Method method = (Method)lua_touserdata(L, lua_upvalueindex(1));
		SEL selector = method_getName(method);

		if (!selector) {
			SteakEngine::log(@"\nFailed to get selector.");
			lua_pushnil(L);
			return 1;
		}

		SteakEngine::log(@"\nSelector obtained.");

		id target = (__bridge id)lua_touserdata(L, 1);

		if (!target) {
			SteakEngine::log(@"\nFailed to get target.");
			lua_pushnil(L);
			return 1;
		}

		

		if (![target respondsToSelector:selector]) {
            SteakEngine::log([NSString stringWithFormat:@"\nTarget does not respond to selector %@", NSStringFromSelector(selector)]);
            lua_pushnil(L);
            return 1;
        }

		SteakEngine::log(@"\nTarget obtained and responds to selector.");

		NSMethodSignature *signature = [target methodSignatureForSelector:selector];

		if (!signature) {
			SteakEngine::log(@"\nFailed to get signature.");
			lua_pushnil(L);
			return 1;
		}

		SteakEngine::log(@"\nSignature obtained.");

		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

		if (!invocation) {
			SteakEngine::log(@"\nFailed to create invocation.");
			lua_pushnil(L);
			return 1;
		}

		SteakEngine::log(@"\nInvocation created");

		[invocation setSelector:selector];
		[invocation setTarget:target];

		SteakEngine::log(@"\nInvocation set selector and target.");

		NSUInteger numArgs = [signature numberOfArguments];
		for (NSUInteger i = 2; i < numArgs; i++) {
			if (lua_isnumber(L, (int)(i - 1))) {
				CGFloat value = lua_tonumber(L, (int)(i - 1));
				[invocation setArgument:&value atIndex:i];
			} else if (lua_isstring(L, (int)(i - 1))) {
				const char* value = lua_tostring(L, (int)(i - 1));

				if (value) {
					NSString *str = [NSString stringWithUTF8String:value];
                    [invocation setArgument:&str atIndex:i];
				} else {
					SteakEngine::log(@"\nNull string argument passed to method.");
					lua_pushnil(L);
					return 1;
				}
			} else {
				SteakEngine::log([NSString stringWithFormat:@"\nUnsupported argument type at index %lu.", (unsigned long)i]);
				lua_pushnil(L);
				return 1;
			}
		}

		[invocation invoke];

		if ([signature methodReturnLength] > 0) {
			void *returnValue;
			[invocation getReturnValue:&returnValue];
			if (returnValue) {
				lua_pushlightuserdata(L, returnValue);
			} else {
				lua_pushnil(L);
			}
		} else {
			lua_pushnil(L);
		}
		return 1;
	}, 1);
	lua_settable(L, -3);
	SteakEngine::log(@"\nMethod has been bound successfully.\n");
}

void lua::bindClass(lua_State* L, const char* className) {
	Class cls = objc_getClass(className);

	if (!cls) {
		SteakEngine::log(@"\nUnable to find class");
		return;
	}

	lua::lastBoundClass = cls;
	//if ((strncmp(className, "__", 2) == 0 || (className[0] == '_' && className[1] != '_')) || strcmp(className, "Object") == 0 || strncmp(className, "CK", 2) == 0 || strncmp(className, "Test", 4) == 0 || strncmp(className, "JS", 2) == 0 || strncmp(className, "Foundation", 10) == 0 || strncmp(className, "ChartboostSDK", 13) == 0 || strncmp(className, "AppProtection", 13) == 0) continue;

	//if (!(strncmp(className, "UI", 2) == 0 || strncmp(className, "objc", 4) == 0 || strncmp(className, "UIKit", 5))) continue;

	//SteakEngine::log([NSString stringWithFormat:@"\nBinding class %s", className]);
	//lua_pushstring(L, className);
	luaL_newmetatable(L, className);

	lua_pushstring(L, "__index");
	lua_pushcfunction(L, [](lua_State* L) -> int {
		id instance = (__bridge id)lua_touserdata(L, 1);

		const char* key = lua_tostring(L, 2);

		if (key) {

			SEL selector = sel_registerName(key);
			if ([instance respondsToSelector:selector]) {
				NSMethodSignature *signature = [instance methodSignatureForSelector:selector];
				NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
				[invocation setSelector:selector];
				[invocation setTarget:instance];
				[invocation invoke];

				if ([signature methodReturnLength] > 0) {
					void *returnValue;
					[invocation getReturnValue:&returnValue];
					lua_pushlightuserdata(L, returnValue);
					return 1;
				} else {
					lua_pushnil(L);
					return 1;
				}
			}
		}
		lua_pushnil(L);
		return 1;
	});
	lua_settable(L, -3);

    lua_pushstring(L, "create");
    lua_pushcfunction(L, [](lua_State* L) -> int {
        //Class cls = (__bridge Class)lua_touserdata(L, 1);
		if (!lua::lastBoundClass) {
			SteakEngine::log(@"\nCreate method: class is nil.");
			lua_pushnil(L);
			return 1;
		}
        id instance = [[lua::lastBoundClass alloc] init];  // alloc + init
        if (instance) {
            lua_pushlightuserdata(L, (__bridge void*)instance);
        } else {
			SteakEngine::log(@"\nCreate method: instance is nil.");
            lua_pushnil(L);
        }
        return 1;
    });
    lua_settable(L, -3);

	unsigned int numMethods;
	Method *methods = class_copyMethodList(object_getClass(cls), &numMethods);
	if (!methods) {
		SteakEngine::log([NSString stringWithFormat:@"\nCouldn't bind %s methods.", className]);
	}
	for (unsigned int j = 0; j < numMethods; j++) {
		if (methods[j])
			lua::bindMethod(L, cls, methods[j]);
		else
			SteakEngine::log([NSString stringWithFormat:@"\nCouldn't bind method %s.", sel_getName(method_getName(methods[j]))]);
	}
	free(methods);

	//lua_settable(L, -1);
	lua_setglobal(L, className);

	lua_getglobal(L, className);
	if (!lua_isnil(L, -1)) {
		SteakEngine::log(@"\nClass has been bound successfully.");
	} else {
		SteakEngine::log(@"\nClass is nil...");
	}
	lua_pop(L, 1);
}

int lua::log(lua_State* L) {
	if (lua_gettop(L) < 1 || !lua_isstring(L, 1)) {
		lua_pushstring(L, "Expected a string argument.");
		lua_error(L);
	}

	const char* message = lua_tostring(L, 1);

	SteakEngine::log([NSString stringWithUTF8String:message]);

	return 0;
}
