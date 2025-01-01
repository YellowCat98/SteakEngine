// Taken from https://github.com/pengubow/geode-inject-ios/blob/c7b0ab92e813ca4f7ba12600ba04bb7028b22eee/dyld_bypass_validation.m
// and modified a bit in order to get it compiling
// because I quite literally couldn't figure it out without copying the whole code

// Based on: https://blog.xpnsec.com/restoring-dyld-memory-loading
// https://github.com/xpn/DyldDeNeuralyzer/blob/main/DyldDeNeuralyzer/DyldPatch/dyldpatch.m
#pragma once
#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <sys/syscall.h>

#define ASM(...) __asm__(#__VA_ARGS__)

extern "C" void* __mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
extern "C" int __fcntl(int fildes, int cmd, void* param);
extern "C" kern_return_t builtin_vm_protect(mach_port_t target_task, vm_address_t address, vm_size_t size, bool set_maximum, vm_prot_t new_protection);

namespace CharlieEngine {
	namespace dyldBypass {

		static unsigned char patch[] = {0x88,0x00,0x00,0x58,0x00,0x01,0x1f,0xd6,0x1f,0x20,0x03,0xd5,0x1f,0x20,0x03,0xd5,0x41,0x41,0x41,0x41,0x41,0x41,0x41,0x41};
		static unsigned char mmapSig[] = {0xB0, 0x18, 0x80, 0xD2, 0x01, 0x10, 0x00, 0xD4};
		static unsigned char fcntlSig[] = {0x90, 0x0B, 0x80, 0xD2, 0x01, 0x10, 0x00, 0xD4};

		static void builtin_memcpy(char *target, const unsigned char *source, size_t size) {
			for (int i = 0; i < size; i++) {
				target[i] = source[i];
			}
		}

		ASM(
		.global _builtin_vm_protect \n
		_builtin_vm_protect:     \n
			mov x16, #-0xe       \n
			svc #0x80            \n
			ret
		);

		static bool redirectFunction(const char *name, void *patchAddr, void *target) {
			kern_return_t kret = builtin_vm_protect(mach_task_self(), (vm_address_t)patchAddr, sizeof(patch), false, PROT_READ | PROT_WRITE | VM_PROT_COPY);
			if (kret != KERN_SUCCESS) {
				CharlieEngine::utils::log([NSString stringWithFormat:@"vm_protect(RW) fails at line %d\n", __LINE__], @"DyldLVBypass.log");
				return FALSE;
			}

			builtin_memcpy((char *)patchAddr, patch, sizeof(patch));
			*(void **)((char*)patchAddr + 16) = target;

			kret = builtin_vm_protect(mach_task_self(), (vm_address_t)patchAddr, sizeof(patch), false, PROT_READ | PROT_EXEC);
			if (kret != KERN_SUCCESS) {
				CharlieEngine::utils::log([NSString stringWithFormat:@"vm_protect(RX) fails at line %d\n", __LINE__], @"DyldLVBypass.log");
				return FALSE;
			}

			CharlieEngine::utils::log([NSString stringWithFormat:@"hook %s succeed!\n", name], @"DyldLVBypass.log");
			return TRUE;
		}

		static bool searchAndPatch(const char *name, const char *base, const char *signature, int length, void *target) {
			char *patchAddr = NULL;

			for(int i = 0; i < 0x100000; i++) {
				if (base[i] == signature[0] && memcmp(base + i, signature, length) == 0) {
					patchAddr = (char*)(base + i);
					break;
				}
			}

			if (patchAddr == NULL) {
				CharlieEngine::utils::log([NSString stringWithFormat:@"hook fails line %d\n", __LINE__], @"DyldLVBypass.log");
				return FALSE;
			}

			CharlieEngine::utils::log([NSString stringWithFormat:@"found %s at %p\n", name, patchAddr], @"DyldLVBypass.log");
			return redirectFunction(name, patchAddr, target);
		}

		static void *getDyldBase(void) {
			return (void *)dyld_all_image_infos().dyldImageLoadAddress;
		}

		static void* hooked_mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset) {
			void *map = __mmap(addr, len, prot, flags, fd, offset);
			if (map == MAP_FAILED && fd && (prot & PROT_EXEC)) {
				map = __mmap(addr, len, PROT_READ | PROT_WRITE, flags | MAP_PRIVATE | MAP_ANON, 0, 0);
				void *memoryLoadedFile = __mmap(NULL, len, PROT_READ, MAP_PRIVATE, fd, offset);
				memcpy(map, memoryLoadedFile, len);
				munmap(memoryLoadedFile, len);
				mprotect(map, len, prot);
			}
			return map;
		}

		static int hooked___fcntl(int fildes, int cmd, void *param) {
			if (cmd == F_ADDFILESIGS_RETURN) {
				char filePath[PATH_MAX];
				bzero(filePath, PATH_MAX);

				if (__fcntl(fildes, F_GETPATH, filePath) != -1) {
					const char *homeDir = [NSHomeDirectory() UTF8String];
					if (!strncmp(filePath, homeDir, strlen(homeDir))) {
						fsignatures_t *fsig = (fsignatures_t*)param;
						fsig->fs_file_start = 0xFFFFFFFF;
						return 0;
					}
				}
			} else if (cmd == F_CHECK_LV) {
				return 0;
			}
			return __fcntl(fildes, cmd, param);
		}

		static int hooked_fcntl(int fildes, int cmd, ...) {
			va_list ap;
			va_start(ap, cmd);
			void *param = va_arg(ap, void *);
			va_end(ap);
			return hooked___fcntl(fildes, cmd, param);
		}

		void init_bypassDyldLibValidation() {
			static BOOL bypassed;
			if (bypassed) return;
			bypassed = YES;

			CharlieEngine::utils::log(@"init\n", @"DyldLVBypass.log");

			const char *dyldBase = (const char*)getDyldBase();
			redirectFunction("mmap", (void*)mmap, (void*)hooked_mmap);
			redirectFunction("fcntl", (void*)fcntl, (void*)hooked_fcntl);
			searchAndPatch("dyld_mmap", dyldBase, (const char*)mmapSig, sizeof(mmapSig), (void*)hooked_mmap);
			searchAndPatch("dyld_fcntl", dyldBase, (const char*)fcntlSig, sizeof(fcntlSig), (void*)hooked___fcntl);
		}
	}
}
