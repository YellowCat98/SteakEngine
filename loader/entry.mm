#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include "utils.hpp"

using namespace CharlieEngine;

__attribute__((constructor))
static void initialize() {
    NSURL *url = [NSURL URLWithString:@"https://google.com"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}
