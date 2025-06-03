#define CHECK_TARGET
#import <PSHeader/PS.h>
#import <substrate.h>
// #import <os/lock.h>

%config(generator=MobileSubstrate)

#define domain CFSTR("com.apple.UIKit")
#define key CFSTR("NoSwiftAtRuntime")

static BOOL shouldEnableForBundleIdentifier(NSString *bundleIdentifier) {
    if ([bundleIdentifier isEqualToString:@"com.apple.springboard"])
        return NO;
    const void *value = CFPreferencesCopyAppValue(key, domain);
    if (value == NULL)
        value = CFPreferencesCopyValue(key, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    NSArray <NSString *> *nsValue = (__bridge NSArray <NSString *> *)value;
    return [nsValue containsObject:bundleIdentifier];
}

// os_unfair_lock *runtimeLock;
Class (*realizeClassWithoutSwift)(Class, Class);
void (*realizeClassMaybeSwiftMaybeRelock)(Class, bool);

%hookf(Class, realizeClassMaybeSwiftMaybeRelock, Class cls, bool leaveLocked) {
    if (leaveLocked) {
        Class clz = realizeClassWithoutSwift(cls, nil);
        return clz;
    }
    return %orig;
}

%ctor {
    if (!isTarget(TargetTypeApps) || !shouldEnableForBundleIdentifier(NSBundle.mainBundle.bundleIdentifier)) return;
    MSImageRef image = MSGetImageByName(realPath2(@"/usr/lib/libobjc.A.dylib"));
    realizeClassMaybeSwiftMaybeRelock = (void (*)(Class, bool))MSFindSymbol(image, "__ZL33realizeClassMaybeSwiftMaybeRelockP10objc_classR8mutex_ttILb0EEb");
    realizeClassWithoutSwift = (Class (*)(Class, Class))MSFindSymbol(image, "__ZL24realizeClassWithoutSwiftP10objc_classS0_");
    // runtimeLock = (os_unfair_lock *)MSFindSymbol(image, "_runtimeLock");
    NSLog(@"[+] Found realizeClassMaybeSwiftMaybeRelock: %d", realizeClassMaybeSwiftMaybeRelock != NULL);
    NSLog(@"[+] Found realizeClassWithoutSwift: %d", realizeClassWithoutSwift != NULL);
    // NSLog(@"[+] Found runtimeLock: %d", runtimeLock != NULL);
    %init;
}
