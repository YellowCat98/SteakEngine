#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include <dlfcn.h>
#include "utils.hpp"
#include "bypass_dyld_validation.hpp"

int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);

void downloadLoader(NSString* urlString, NSString* outputPath) {
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLSession *session = [NSURLSession sharedSession];

	NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
		if (error) {

			CharlieEngine::utils::log([NSString stringWithFormat:@"Download failed: %@", [error localizedDescription]], @"CharlieEngineInject.log");
			return;
		}

		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSURL *destinationURL = [NSURL fileURLWithPath:outputPath];

		NSError *fileError;
		[fileManager moveItemAtURL:location toURL:destinationURL error:&fileError];
		if (fileError) {
			NSString *error = [fileError localizedDescription];
			CharlieEngine::utils::log([NSString stringWithFormat:@"Error: %@", error], @"CharlieEngineInject.log");
		} else {
			CharlieEngine::utils::log([NSString stringWithFormat:@"Downloaded libCharlieEngineLoader.dylib to: %@", outputPath], @"CharlieEngineInject.log");
		}
	}];

	[downloadTask resume];
}

__attribute__((constructor))
static void initialize() {
	CharlieEngine::utils::log(@"Hello!\n", @"CharlieEngineInject.log");
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];

	NSString* dylibPath = [documentsDirectory stringByAppendingPathComponent:@"libCharlieEngineLoader.dylib"];

	if ([[NSFileManager defaultManager] fileExistsAtPath:dylibPath]) {
		bool hasJIT = CharlieEngine::utils::hasJIT([[NSProcessInfo processInfo] processIdentifier]);
		if (hasJIT) {
			CharlieEngine::dyldBypass::init_bypassDyldLibValidation();
			void *handle = dlopen([dylibPath UTF8String], RTLD_NOW); // ok now i know what that last one do!!!
			if (!handle) {
				CharlieEngine::utils::log([NSString stringWithFormat:@"Error loading libCharlieEngineLoader.dylib: %s", dlerror()], @"CharlieEngineInject.log");
			} else {
				CharlieEngine::utils::log(@"libCharlieEngineLoader.dylib is successfully loaded!", @"CharlieEngineInject.log");
			}
		} else {
			CharlieEngine::utils::log(@"JIT is not enabled!\n", @"CharlieEngineInject.log");
		}

	} else {
			downloadLoader(@"https://github.com/YellowCat98/CharlieEngine/releases/download/nightly/libCharlieEngineLoader.dylib", dylibPath);
    }
}
