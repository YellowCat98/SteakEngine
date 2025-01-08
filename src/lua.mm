#include <SteakEngine.hpp>

using namespace SteakEngine;

void lua::init(lua_State* L) {
	lua_register(L, "Log", lua::log);
	lua::bindObjc(L);
}

void lua::bindMethod(lua_State* L, Class cls, Method method) {
	char* badName = sel_getName(method_getName(method));
	SteakEngine::log([NSString stringWithFormat:@"\nBinding Method %s\n", badName]);

	size_t nameLen = strlen(badName);

	if (nameLen > 0 && name[nameLen - 1] == ':') {
		SteakEngine::log(@"\nInvalid method name found in method name, will remove it.");
		char* goodName = (char*)malloc(nameLen);

		if (goodName) {
			strncpy(goodName, name, nameLen - 1);
			goodName[nameLen - 1] = '\0';

			badName = goodName;
		}
	}

	const char* name = badName;
	free(badName);

	lua_pushstring(L, name);
	lua_pushlightuserdata(L, method);
	lua_pushcclosure(L, [](lua_State* L) -> int {
		Method method = (Method)lua_touserdata(L, lua_upvalueindex(1));
		SEL selector = method_getName(method);
		id target = (__bridge id)lua_touserdata(L, 1);
		NSMethodSignature *signature = [target methodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:selector];
		[invocation setTarget:target];

		NSUInteger numArgs = [signature numberOfArguments];
		for (NSUInteger i = 2; i < numArgs; i++) {
			if (lua_isnumber(L, (int)(i - 1))) {
				CGFloat value = lua_tonumber(L, (int)(i - 1));
				[invocation setArgument:&value atIndex:i];
			} else if (lua_isstring(L, (int)(i - 1))) {
				const char* value = lua_tostring(L, (int)(i - 1));
				NSString *str = [NSString stringWithUTF8String:value];
				[invocation setArgument:&str atIndex:i];
			}
		}

		[invocation invoke];

		if ([signature methodReturnLength] > 0) {
			void *returnValue;
			[invocation getReturnValue:&returnValue];
			lua_pushlightuserdata(L, returnValue);
		} else {
			lua_pushnil(L);
		}
		return 1;
	}, 1);
	lua_settable(L, -3);
}

void lua::bindObjc(lua_State* L) {
	SteakEngine::log(@"\nBinding Objective C and UI thigns");
	unsigned int numClasses;
	Class *classes = objc_copyClassList(&numClasses);

	for (unsigned int i = 0; i < numClasses; i++) {
		Class cls = classes[i];
		if (!cls) {
			SteakEngine::log(@"\nUnable to find class");
		}
		const char* className = class_getName(cls);
		if ((strncmp(className, "__", 2) == 0 || (className[0] == '_' && className[1] != '_')) || strcmp(className, "Object") == 0) continue;

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
	}
	free(classes);
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