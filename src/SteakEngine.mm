// contains definitions of stuff that im not really sure where to define
#include <SteakEngine.hpp>

void SteakEngine::log(NSString *str) {
    
    NSLog(@"%@", str);

    NSString *logName = @"SteakEngine.log";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString* logPath = [documentsDirectory stringByAppendingPathComponent:logName];
    NSError *error = nil;

    NSString *wholeLog = [NSString stringWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error reading log file: %@, Will initialize wholeLog as an empty string.", error.localizedDescription);
        wholeLog = @"";
        }
    // Append the new log entry
    NSString *newLog = [wholeLog stringByAppendingString:str];
    BOOL success = [newLog writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (!success) {
        NSLog(@"Error writing to log file: %@", error.localizedDescription);
    }
}

bool SteakEngine::hasJIT(int pid) {
    int flags = 0;
    while (true) {
        int ret = csops(pid, 0x00000000, &flags, sizeof(flags));
        if (ret != 0) {
            perror("csops failed");
            return false;
        }

        bool actuallyhasJIT = (flags & 0x10000000) != 0;

        if (actuallyhasJIT) {
            return true;  // JIT is enabled, exit the loop and return true
            }

        sleep(1);  // Wait for 1 second before checking again
    }
}

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