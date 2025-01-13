#pragma once
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <errno.h>
#include <stdbool.h>
#include <objc/runtime.h>
#include <objc/objc.h>
#include <objc/message.h>
#include <string>
extern "C" {
    #include <lua.h>
    #include <lualib.h>
    #include <lauxlib.h>
    int csops(pid_t pid, int ops, void *useraddr, size_t usersize);
}


namespace SteakEngine {
    void log(NSString *str);

    bool hasJIT(int pid);

    //template <typename T, typename... Args>
    //bool swizzleMethod(Class cls, SEL selector, T (*func)(Args...), T (*myFunc)(Args...));

    // bindings and general stuff related to lua
    namespace lua {
        void init(lua_State* L); // unrelated to bindings, this initializes all lua bindings.
        void bindMethod(lua_State* L, Class cls, Method method); // this binds all methods of a specific class
        void bindClass(lua_State* L, const char* className); // bind Thingies...
        void bindIVar(lua_State* L, Class cls, Ivar ivar);


        int log(lua_State* L);

        extern Class lastBoundClass;
    }
}