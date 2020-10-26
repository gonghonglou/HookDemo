//
//  NSObject+LibffiHook.h
//  HookDemo_Example
//
//  Created by 与佳期 on 2020/10/13.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (LibffiHook)

- (void)hook_method:(SEL)sel withBlock:(id)block;

@end

NS_ASSUME_NONNULL_END
