#pragma once

#include <SteakEngine.hpp>

namespace SteakEngine {
    template <typename T, typename... Args>
    bool SteakEngine::swizzleMethod(Class cls, SEL selector, T (*func)(Args...), T (*myFunc)(Args...)) {
        Method method = class_getInstanceMethod(cls, selector);
        if (!method) {
            SteakEngine::log(@"\nMethod not found");
            return false;
        }

        func = (T (*)(Args...))method_getImplementation(method);

        IMP swizzledIMP = (IMP)myFunc;
        method_setImplementation(method, swizzledIMP);

        SteakEngine::log([NSString stringWithFormat:@"Swizzled method %@::%@", NSStringFromClass(cls), NSStringFromSelector(selector)]);
    }
}