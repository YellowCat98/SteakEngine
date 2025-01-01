#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "utils.hpp"

__attribute__((constructor))
static void initialize() {
	SteakEngine::utils::log(@"Hello!\n");
	while (true) {
		NSLog(@"Hello this is a test ot make sure that the application is doing as aexpected,");
	}
}
