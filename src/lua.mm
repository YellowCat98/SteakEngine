#include <SteakEngine.hpp>

using namespace SteakEngine;

void lua::init(lua_State* L) {
	lua_register(L, "log", lua::log);
	lua::bindObjc(L);
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

void lua::bindObjc(lua_State* L) {
	SteakEngine::log(@"\nBinding Objective C and UI thigns");
	unsigned int numClasses;
	Class *classes = objc_copyClassList(&numClasses);
	SteakEngine::log([NSString stringWithFormat:@"\nClasses found: %d", numClasses]);

	for (unsigned int i = 0; i < numClasses; i++) {
		SteakEngine::log(@"\nThe.");
		Class cls = classes[i];
		if (!cls) {
			SteakEngine::log(@"\nUnable to find class");
		}
		const char* className = class_getName(cls);
		if ((strncmp(className, "__", 2) == 0 || (className[0] == '_' && className[1] != '_')) || strcmp(className, "Object") == 0 || strncmp(className, "CK", 2) == 0 || strncmp(className, "Test", 4) == 0 || strncmp(className, "JS", 2) == 0) continue;

		SteakEngine::log([NSString stringWithFormat:@"\nBinding class %s", className]);
		lua_pushstring(L, className);
		lua_newtable(L);

		unsigned int numMethods;
		Method *methods = class_copyMethodList(object_getClass(cls), &numMethods);
		if (!methods) {
			SteakEngine::log([NSString stringWithFormat:@"\nCouldn't bind %s methods.", className]);
			continue;
		}
		for (unsigned int j = 0; j < numMethods; j++) {
			if (methods[j])
				lua::bindMethod(L, cls, methods[j]);
			else
				SteakEngine::log([NSString stringWithFormat:@"\nCouldn't bind method %s.", sel_getName(method_getName(methods[j]))]);
		}
		free(methods);

		lua_settable(L, -3);
		SteakEngine::log(@"\nClass has been bound successfully.");
	}
	free(classes);
	SteakEngine::log(@"\nAll of OBJC has been bound to lua (this was a terrible idea)");
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

int lua::objc_selector(lua_State* L) {
	if (lua_gettop(L) < 1 || !lua_isstring(L, 1)) {
		lua_pushstring(L, "Expected a string argument.");
		lua_error(L);
	}

	SEL selector = NSSelectorFromString([NSString stringWithUTF8String:lua_tostring(L, 1)]);

	lua_pushlightuserdata(L, (void *)selector);

	return 1;
}