//
//  LibffiHook.h
//  HookDemo_Example
//
//  Created by Honglou Gong on 2020/10/12.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LibffiHook : NSObject

void libffi_hook_func(id obj, SEL sel, id block);

@end

NS_ASSUME_NONNULL_END
