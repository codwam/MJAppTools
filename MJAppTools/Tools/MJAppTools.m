//
//  MJAppTools.m
//  MJAppTools
//
//  Created by MJ Lee on 2018/1/27.
//  Copyright © 2018年 MJ Lee. All rights reserved.
//

#import "MJAppTools.h"
#import "MJMachO.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "LSApplicationWorkspace.h"
#import "LSApplicationProxy.h"
#import "FBApplicationInfo.h"

#define kRevealPath @"/Library/MobileSubstrate/DynamicLibraries/reveal2Loader.plist"

@implementation MJAppTools

+ (BOOL)match:(NSRegularExpression *)exp app:(MJApp *)app
{
    if (!exp) return YES;
    
    if ([exp firstMatchInString:app.displayName options:0 range:NSMakeRange(0, app.displayName.length)]) return YES;
    if ([exp firstMatchInString:app.bundlePath options:0 range:NSMakeRange(0, app.bundlePath.length)]) return YES;
    if ([exp firstMatchInString:app.bundleIdentifier options:0 range:NSMakeRange(0, app.bundleIdentifier.length)]) return YES;
    
    return NO;
}

+ (void)listUserAppsWithType:(MJListAppsType)type regex:(NSString *)regex operation:(void (^)(NSArray *apps))operation
{
    if (!operation) return;
    
    // 正则
    NSRegularExpression *exp = regex ? [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:nil] : nil;
    
    // 数组
    NSMutableArray *apps = [NSMutableArray array];
    NSArray *appInfos = [[LSApplicationWorkspace defaultWorkspace] allApplications];
    
    for (FBApplicationInfo *appInfo in appInfos) {
        if (!appInfo.bundleURL) continue;
        MJApp *app = [MJApp appWithInfo:appInfo];
        // 类型
        if (type != MJListAppsTypeSystem && app.isSystemApp) continue;
        if (type == MJListAppsTypeSystem && !app.isSystemApp) continue;
        
        // 隐藏
        if (app.isHidden) continue;
        
        // 过滤
        if ([app.bundleIdentifier containsString:@"com.apple.webapp"]) continue;
        
        // 正则
        if (![self match:exp app:app]) continue;
        
        // 可执行文件
        [app setupExecutable];
        if (!app.executable) continue;
        
        // 加密
        if (type == MJListAppsTypeUserDecrypted && app.executable.isEncrypted) continue;
        if (type == MJListAppsTypeUserEncrypted && !app.executable.isEncrypted) continue;
        
        [apps addObject:app];
    }
    
    operation(apps);
}

+ (NSError *)checkRevealPlist {
    BOOL flag = [NSFileManager.defaultManager fileExistsAtPath:kRevealPath];
    if (!flag) {
        return [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"找不到文件"}];
    }
    return nil;
}

+ (void)showRevealPlist:(RevealCompletion)completion {
    id obj;
    NSError *error;
    
    error = [self checkRevealPlist];
    if (!error) {
        obj = [NSString stringWithContentsOfFile:kRevealPath encoding:NSUTF8StringEncoding error:&error];
    }
    
    !completion ?: completion(obj, error);
}

+ (void)addItemToRevealPlist:(NSString *)bundleID completion:(RevealCompletion)completion {
    [self addItemsToRevealPlist:@[bundleID] completion:completion];
}

+ (void)addItemsToRevealPlist:(NSArray<NSString *> *)bundleIDS completion:(RevealCompletion)completion {
    id obj;
    NSError *error;
    
    if (bundleIDS.count == 0) {
        error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"没有 bundleID"}];
        goto final;
    }
    
    error = [self checkRevealPlist];
    if (!error) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:kRevealPath];
        NSMutableDictionary *filter = data[@"Filter"];
        NSArray *bundles = filter[@"Bundles"];
        
        obj = [NSMutableArray array];
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithArray:bundles];
        for (NSString *ID in bundleIDS) {
            if (![set containsObject:ID]) {
                [set addObject:ID];
                [obj addObject:ID];
            }
        }
        
        data[@"Filter"][@"Bundles"] = [set array];
        [data writeToFile:kRevealPath atomically:YES];
    }
    
final:
    !completion ?: completion(obj, error);
}


+ (void)removeItemFromRevealPlist:(NSString *)bundleID completion:(RevealCompletion)completion {
    id obj;
    NSError *error;
    
    if (bundleID.length == 0) {
        error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"bundleID.length == 0"}];
        goto final;
    }
    
    error = [self checkRevealPlist];
    if (!error) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:kRevealPath];
        NSMutableDictionary *filter = data[@"Filter"];
        NSArray *bundles = filter[@"Bundles"];
        NSMutableArray *mutable_bundles = [bundles mutableCopy];

        obj = [NSMutableArray array];
        NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:bundleID options:NSRegularExpressionCaseInsensitive error:nil];
        for (NSString *name in bundles) {
            if ([exp firstMatchInString:name options:0 range:NSMakeRange(0, name.length)]) {
                [mutable_bundles removeObject:name];
                [obj addObject:name];
            }
        }
        
        data[@"Filter"][@"Bundles"] = mutable_bundles;
        [data writeToFile:kRevealPath atomically:YES];
    }
    
final:
    !completion ?: completion(obj, error);
}

@end
