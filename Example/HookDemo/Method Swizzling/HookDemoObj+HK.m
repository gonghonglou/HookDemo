//
//  HookDemoObj+HK.m
//  HookDemo_Example
//
//  Created by Honglou Gong on 2020/10/7.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import "HookDemoObj+HK.h"
#import <objc/runtime.h>
#import <JRSwizzle/JRSwizzle.h>

@implementation HookDemoObj (HK)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(loopLogWithCount:);
        SEL swizzledSelector = @selector(hook_loopLogWithCount:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
                
        
//        NSError *error;
//        [self jr_swizzleMethod:originalSelector withMethod:swizzledSelector error:&error];
//        if (error) {
//            NSLog(@"---error: %@", error);
//        }
    });
}


- (void)hook_loopLogWithCount:(NSInteger)count {
    NSLog(@"[hook before] count: %d", count);
    
    // 本类方法不存在时，执行 hook_loopLogWithCount: 会造成无限循环调用
    // JRSwizzle 的处理：若本类方法不存在时，未执行 class_addMethod，则会有直接崩溃的问题
    [self hook_loopLogWithCount:count];
    NSLog(@"[hook after] count: %d", count);
}

@end
