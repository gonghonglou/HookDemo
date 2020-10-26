//
//  HookDemoObj.m
//  HookDemo_Example
//
//  Created by Honglou Gong on 2020/10/7.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import "HookDemoObj.h"

@implementation HookDemoObj

- (void)loopLogWithCount:(NSInteger)count {
    for (NSInteger i = 0; i < count; i++) {
        NSLog(@"loopLogWithCount: %ld", i);
    }
}


- (void)logString:(NSString *)string {
    NSLog(@"logString: %@", string);
    
    // Thread 1: EXC_BAD_ACCESS (code=1, address=0x10)
//    self.testBlock();
}

//+ (BOOL)resolveInstanceMethod:(SEL)sel {
//    NSLog(@"----%@", NSStringFromSelector(_cmd));
//    return [super resolveInstanceMethod:sel];
//}
//
//- (id)forwardingTargetForSelector:(SEL)aSelector {
//    NSLog(@"----%@", NSStringFromSelector(_cmd));
//    return [super forwardingTargetForSelector:aSelector];
//}
//
//- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
//    NSLog(@"----%@", NSStringFromSelector(_cmd));
//    return [super methodSignatureForSelector:aSelector];
//}
//
//- (void)forwardInvocation:(NSInvocation *)anInvocation {
//    NSLog(@"----%@", NSStringFromSelector(_cmd));
//    [super forwardInvocation:anInvocation];
//}

@end
