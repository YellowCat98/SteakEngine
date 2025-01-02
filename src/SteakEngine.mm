// contains definitions of stuff that im not really sure where to define
#include <SteakEngine.hpp>

void SteakEngine::log(NSString *str) {
    
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