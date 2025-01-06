#pragma once

#include <SteakEngine.hpp>

namespace SteakEngine {
    template <typename T, typename... Args>
    bool swizzleMethod(Class cls, SEL selector, T (*func)(Args...), T (*myFunc)(Args...)) {
        Method method = class_getInstanceMethod(cls, selector);
        if (!method) {
            SteakEngine::log(@"\nMethod not found");
            return false;
        }

        IMP originalIMP = method_getImplementation(method);

        auto originalFunc = reinterpret_cast<T (*)(Args...)>(originalIMP);

        func = originalFunc;

        IMP swizzledIMP = (IMP)myFunc;
        method_setImplementation(method, swizzledIMP);

        SteakEngine::log([NSString stringWithFormat:@"\nSwizzled method %@::%@", NSStringFromClass(cls), NSStringFromSelector(selector)]);

        return true;
    }
}