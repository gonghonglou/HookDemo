//
//  HKViewController.m
//  HookDemo
//
//  Created by gonghonglou on 10/27/2020.
//  Copyright (c) 2020 gonghonglou. All rights reserved.
//

#import "HKViewController.h"
#import <objc/runtime.h>
#import "fishhook.h"
#import "SMCallTraceCore.h"
#import <HookDemo/HookDemo.h>
#import "HookDemoObj.h"
#import <Aspects/Aspects.h>
#import "ffi.h"
#import "NSObject+LibffiHook.h"
#import "MHCallTrace.h"
#import "THInterceptor.h"

@interface HKViewController ()

@end

@implementation HKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self layoutUI];
    
    
    // 1、Method Swizzling
//    HookDemoObj *swizzlingObj = [HookDemoObj new];
//    [swizzlingObj loopLogWithCount:3];
    
    
    // 2、Message Forwarding
//    HookDemoObj *forwardingObj = [HookDemoObj new];
//    [forwardingObj aspect_hookSelector:@selector(logString:) withOptions:AspectPositionAfter usingBlock: ^{
//        NSLog(@"Aspects after");
//    } error:nil];
//
//    [forwardingObj aspect_hookSelector:@selector(logString:) withOptions:AspectPositionAfter usingBlock: ^(id<AspectInfo> info, NSString *str){
//        NSLog(@"Aspects after ---:%@", str);
//    } error:nil];
//    [forwardingObj logString:@"aaa"];
    
    
    // 3、libffi
//    [self libffi_call_c_func];
//    [self libffi_call_oc_func];
    
    // hook
//    HookDemoObj *forwardingObj = [HookDemoObj new];
//    [forwardingObj hook_method:@selector(logString:) withBlock: ^{
//        NSLog(@"libffi hook after ---");
//    }];
//    [forwardingObj logString:@"aaa"];
    
    
    // 4、fishhook
//    [self fishhook_nslog];
//    [self fishhook_objc_msgSend];
    
    
    // 5、静态库插桩
//    HookDemo *obj = [HookDemo new];
//    [obj methodTestOne];
//    [obj methodTestTwo];
    
    
    // 6、TrampolineHook
//    [self trampolineHook];
    
    
    // 7、Dobby

    // 8、Frida
}


// MARK: - 3、libffi C

int c_func(int a , int b) {
    int sum = a + b;
    return sum;
}

- (void)libffi_call_c_func {
    ffi_cif cif;
    ffi_type *argTypes[] = {&ffi_type_sint, &ffi_type_sint};
    ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &ffi_type_sint, argTypes);
    
    int a = 1;
    int b = 2;
    void *args[] = {&a, &b};
    int retValue;
    ffi_call(&cif, (void *)c_func, &retValue, args); // retValue = 3
    
    NSLog(@"libffi_call_c_func, retValue:%d", retValue);
}

// MARK: - 3、libffi OC

- (int)oc_func:(int)a b:(int)b {
    int sum = a + b;
    return sum;
}

- (void)libffi_call_oc_func {
    SEL selector = @selector(oc_func:b:);
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    
    ffi_cif cif;
    ffi_type *argTypes[] = {&ffi_type_pointer, &ffi_type_pointer, &ffi_type_sint, &ffi_type_sint};
    ffi_prep_cif(&cif, FFI_DEFAULT_ABI, (uint32_t)signature.numberOfArguments, &ffi_type_sint, argTypes);
    
    int arg1 = 1;
    int arg2 = 2;
    void *args[] = {(__bridge void *)(self), selector, &arg1, &arg2};
    int retValue;
    IMP func = [self methodForSelector:selector];
    ffi_call(&cif, (void *)func, &retValue, args); // retValue = 3
    
    
    NSLog(@"libffi_call_oc_func, retValue:%d", retValue);
}


// MARK: - 4、fishhook NSLog

- (void)fishhook_nslog {
    NSLog(@"fishhook before");
    
    struct rebinding rebindingLog;
    // 需要 hook 的方法名
    rebindingLog.name = "NSLog";
    // 用哪个方法来替换
    rebindingLog.replacement = myLog;
    // 保存原本函数指针
    rebindingLog.replaced = (void **)&sys_nslog;
    
    struct rebinding rebindings[] = {rebindingLog};
    
    rebind_symbols(rebindings, 1);
    
    NSLog(@"fishhook after");
}


// 函数指针，用来保存原来的函数
static void (*sys_nslog)(NSString *format, ...);

// 新函数（注意：不定参数未处理）
void myLog(NSString * _Nonnull format, ...) {
    NSString *message = [format stringByAppendingString:@"---->🍺🍺🍺"];
    (*sys_nslog)(message);
}



// MARK: - 4、fishhook objc_msgSend

- (void)fishhook_objc_msgSend {
    smCallConfigMinTime(0);
    smCallTraceStart();
}

- (void)fishhook_log_objc_msgSend {
    smCallTraceStop();
    
    int num = 0;
    smCallRecord *records = smGetCallRecords(&num);
    for (int i = 0; i < num; i++) {
        smCallRecord *rd = &records[i];
        
        NSMutableString *string = @"".mutableCopy;
        for (int i = 0; i < rd->depth; i++) {
            [string appendString:@"-"];
        }
        NSLog(@"%@[class]:%@, [method]:%@, [time]:%f", string, NSStringFromClass(rd->cls), NSStringFromSelector(rd->sel), (double)rd->time / 1000.0);
    }
}


// MARK: - 5、静态库插桩

- (void)static_pod_log_objc_msgSend {

}


// MARK: - 6、TrampolineHook

void myInterceptor() {
    printf("调用了 myInterceptor\n");
}

- (void)trampolineHook {
    THInterceptor *interceptor = [[THInterceptor alloc] initWithRedirectionFunction:(IMP)myInterceptor];
    Method m = class_getInstanceMethod([HookDemoObj class], @selector(logString:));
    IMP imp = method_getImplementation(m);
    THInterceptorResult *interceptorResult = [interceptor interceptFunction:imp];
    if (interceptorResult.state == THInterceptStateSuccess) {
        method_setImplementation(m, interceptorResult.replacedAddress); // 设置替换的地址
    }
    
    // 执行到这一行时，会调用 myInterceptor 方法
    HookDemoObj *obj = [HookDemoObj new];
    [obj logString:@"aaa"];
}


// MARK: - layoutUI

- (void)layoutUI {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.layer.borderWidth = 1.0;
    button.layer.cornerRadius = 6.0;
    button.layer.borderColor = button.titleLabel.textColor.CGColor;
    [button setTitle:@"viewDidLoad" forState:UIControlStateNormal];
    button.frame = CGRectMake(100, 300, self.view.frame.size.width - 200, 50);
    [button addTarget:self action:@selector(viewDidLoadButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)viewDidLoadButtonAction {
    // 打印方法调用
    [self fishhook_log_objc_msgSend];
}


@end
