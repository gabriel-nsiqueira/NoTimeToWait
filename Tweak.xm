#include <substrate.h>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
void* (*il2cpp_class_from_name)(const void * image, const char* namespaze, const char *name);
void* (*il2cpp_domain_get)();
void* (*il2cpp_assembly_get_image)(const void* assembly);
void* (*il2cpp_class_get_method_from_name)(const void *klass, const char* name, int argsCount);
void** (*il2cpp_domain_get_assemblies)(void* domain, size_t* size);

bool initialized = false;

const char* GetRealIl2CppFrameworkAddress() {
    NSString *appParentDirectory = [[NSBundle mainBundle] bundlePath];
    return [[NSString stringWithFormat:@"%@/Frameworks/UnityFramework.framework/UnityFramework", [appParentDirectory substringFromIndex:8]] UTF8String];
}

bool InitializeIl2CppApi() {
    auto image = MSGetImageByName(GetRealIl2CppFrameworkAddress());
    #define FIND_API(a) *(void**)&a = MSFindSymbol(image, "_"#a); if(!a) return false
    FIND_API(il2cpp_class_from_name);
    FIND_API(il2cpp_domain_get);
    FIND_API(il2cpp_assembly_get_image);
    FIND_API(il2cpp_class_get_method_from_name);
    FIND_API(il2cpp_domain_get_assemblies);
    #undef FIND_API
    return true;
}

void* GetClassByName(const char* namezpace, const char* name) {
    auto domain = il2cpp_domain_get();
    if(!domain) return nullptr;
    size_t assemblyCount;
    auto assemblies = il2cpp_domain_get_assemblies(domain, &assemblyCount);
    if(!assemblies) return nullptr;
    for(auto i = 0; i < assemblyCount; i++) {
        auto assembly = assemblies[i];
        if(!assembly) return nullptr;
        auto image = il2cpp_assembly_get_image(assembly);
        if(!image) return nullptr;
        auto klass = il2cpp_class_from_name(image, namezpace, name);
        return klass;
    }
    return nullptr;
}

void* FindMethod(const void* klass, const char* name, int argsCount) {
    return il2cpp_class_get_method_from_name(klass, name, argsCount);
}

bool RetFalse() {
    return false;
}

// Entry point for the mod
static void onLaunchApp(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef info) {
    if(!initialized) {
        if(!InitializeIl2CppApi()) return;
        auto klass = GetClassByName("", "StatsManager");
        if(!klass) return;
        auto method = (void**)FindMethod(klass, "get_AmBanned", 0);
        if(!method) return;
        *method = (void*)&RetFalse;
        initialized = true;
    }
}

%ctor {
    if(!initialized) CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), nullptr, &onLaunchApp, (CFStringRef)UIApplicationDidFinishLaunchingNotification, nullptr, CFNotificationSuspensionBehaviorDeliverImmediately);
}