#pragma once
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <errno.h>
#include <stdbool.h>

extern "C" int csops(pid_t pid, int ops, void *useraddr, size_t usersize);

namespace CharlieEngine {
    namespace utils {
        NSString *log(NSString *str, NSString* logName) {
            // Get the path to the Documents directory
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];

            // Create the full path to the log file
            NSString* logPath = [documentsDirectory stringByAppendingPathComponent:logName];
            NSError *error = nil;

            // Read the current content of the log file, if it exists
            NSString *wholeLog = [NSString stringWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                NSLog(@"Error reading log file: %@", error.localizedDescription);
                wholeLog = @""; // Initialize to empty string if file doesn't exist
            }

            // Append the new log entry
            NSString *newLog = [wholeLog stringByAppendingString:str];
            BOOL success = [newLog writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            if (!success) {
                NSLog(@"Error writing to log file: %@", error.localizedDescription);
            }

            return str;
        }

        bool hasJIT(int pid) {
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

    }
}