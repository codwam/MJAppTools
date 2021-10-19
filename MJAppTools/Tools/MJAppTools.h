//
//  MJAppTools.h
//  MJAppTools
//
//  Created by MJ Lee on 2018/1/27.
//  Copyright © 2018年 MJ Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJApp.h"

typedef enum {
    MJListAppsTypeUser,
    MJListAppsTypeUserEncrypted,
    MJListAppsTypeUserDecrypted,
    MJListAppsTypeSystem
} MJListAppsType;

typedef void(^RevealCompletion)(id obj, NSError *error);

@interface MJAppTools : NSObject

+ (void)listUserAppsWithType:(MJListAppsType)type regex:(NSString *)regex operation:(void (^)(NSArray *apps))operation;

+ (void)showRevealPlist:(RevealCompletion)completion;

+ (void)addItemToRevealPlist:(NSString *)bundleID completion:(RevealCompletion)completion;
+ (void)addItemsToRevealPlist:(NSArray<NSString *> *)bundleIDS completion:(RevealCompletion)completion;

+ (void)removeItemFromRevealPlist:(NSString *)bundleID completion:(RevealCompletion)completion;

@end
