//
//  NSObject+LibffiHook.m
//  HookDemo_Example
//
//  Created by 与佳期 on 2020/10/13.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import "NSObject+LibffiHook.h"
#import "LibffiHook.h"

@implementation NSObject (LibffiHook)

- (void)hook_method:(SEL)sel withBlock:(id)block {
    libffi_hook_func(self, sel, block);
}

@end
