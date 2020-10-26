//
//  LibffiHook.m
//  HookDemo_Example
//
//  Created by Honglou Gong on 2020/10/12.
//  Copyright © 2020 gonghonglou. All rights reserved.
//

#import "LibffiHook.h"
#import <objc/runtime.h>
#import "ffi.h"

// =================== LibffiHookInfo

@interface LibffiHookInfo : NSObject {
    @public
    
    Class cls;
    SEL sel;
    void *_originalIMP;
    NSMethodSignature *_signature;
    
    id _block;
    ffi_cif *_block_cif;
    void *_block_IMP;
}

@end

@implementation LibffiHookInfo

@end

// =================== LibffiHook


typedef void *LibffiHookBlockIMP;
typedef struct LibffiHookBlock_layout LibffiHookBlock;

struct LibffiHookBlock_layout {
    void *isa;  // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    volatile int flags; // contains ref count
    int reserved;
    void (*invoke)(void *, ...);
    struct Block_descriptor_1 *descriptor;
    // imported variables
};


@implementation LibffiHook

void libffi_hook_func(id obj, SEL sel, id block) {
    NSString *selStr = [@"libffi_hook_" stringByAppendingString:NSStringFromSelector(sel)];
    const SEL key = NSSelectorFromString(selStr);
    if (objc_getAssociatedObject(obj, key)) {
        return;
    }
    
    LibffiHookInfo *info = [LibffiHookInfo new];
    info->cls = [obj class];
    info->sel = sel;
    info->_block = block;
    
    objc_setAssociatedObject(obj, key, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    Method method = class_getInstanceMethod([obj class], sel);
    const char *typeEncoding = method_getTypeEncoding(method);
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
    
    info->_signature = signature;
    
    const unsigned int argsCount = method_getNumberOfArguments(method);
    
    // 1、构造参数类型列表
    ffi_type **argTypes = calloc(argsCount, sizeof(ffi_type *));
    for (int i = 0; i < argsCount; ++i) {
        const char *argType = [signature getArgumentTypeAtIndex:i];
        ffi_type *arg_ffi_type = libffi_hook_ffi_type(argType);
        NSCAssert(arg_ffi_type, @"LibffiHook: can't find a ffi_type: %s", argType);
        argTypes[i] = arg_ffi_type;
    }
    
    // 2、返回值类型
    ffi_type *retType = libffi_hook_ffi_type(signature.methodReturnType);
    
    // 3、准备 cif
    // 需要在堆上开辟内存，否则会出现内存问题 (LibffiHookInfo 释放时会 free 掉)
    ffi_cif *cif = calloc(1, sizeof(ffi_cif));
    // 生成 ffi_cfi 模版对象，保存函数参数个数、类型等信息，相当于一个函数原型
    ffi_status prepCifStatus = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argsCount, retType, argTypes);
    if (prepCifStatus != FFI_OK) {
        NSCAssert(NO, @"LibffiHook: ffi_prep_cif failed: %d", prepCifStatus);
        return;
    }
    
    // 4、生成新的 IMP
    void *newIMP = NULL;
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&newIMP);
    ffi_status prepClosureStatus = ffi_prep_closure_loc(closure, cif, libffi_hook_ffi_closure_func, (__bridge void *)info, newIMP);
    if (prepClosureStatus != FFI_OK) {
        NSCAssert(NO, @"LibffiHook: ffi_prep_closure_loc failed: %d", prepClosureStatus);
        return;
    }
    
    // 5、替换 IMP 实现
    Class hookClass = [obj class];
    SEL aSelector = method_getName(method);
    if (!class_addMethod(hookClass, aSelector, newIMP, typeEncoding)) {
        IMP originIMP = method_setImplementation(method, newIMP);
        if (info->_originalIMP != originIMP) {
            info->_originalIMP = originIMP;
        }
    }
    
    
    // 收集 block 信息（hook 的时候准备好，执行的时候会快点）
    // block 没有 SEL，所以比普通方法少一个参数
    uint blockArgsCount = argsCount - 1;
    ffi_type **blockArgTypes = calloc(blockArgsCount, sizeof(ffi_type *));
    
    // 1、构造参数类型列表
    // 第一个参数是 block 自己，肯定为指针类型
    blockArgTypes[0] = &ffi_type_pointer;
    for (NSInteger i = 2; i < argsCount; ++i) {
        blockArgTypes[i - 1] = libffi_hook_ffi_type([info->_signature getArgumentTypeAtIndex:i]);
    }
    
    // 2、准备 cif
    ffi_cif *callbackCif = calloc(1, sizeof(ffi_cif));
    if (ffi_prep_cif(callbackCif, FFI_DEFAULT_ABI, blockArgsCount, &ffi_type_void, blockArgTypes) == FFI_OK) {
        info->_block_cif = callbackCif;
    } else {
        NSCAssert(NO, @"ffi_prep_cif failed");
    }
    
    // 3、获取 block IMP
    LibffiHookBlock *blockRef = (__bridge LibffiHookBlock *)block;
    info->_block_IMP = blockRef->invoke;
}

static void libffi_hook_ffi_closure_func(ffi_cif *cif, void *ret, void **args, void *userdata) {
    LibffiHookInfo *info = (__bridge LibffiHookInfo *)userdata;
    
    // 1、before
    
//    NSLog(@"LibffiHook before, class: %@, sel: %@", NSStringFromClass(info->cls), NSStringFromSelector(info->sel));
    
    
    // 2、call original IMP
    
    ffi_call(cif, info->_originalIMP, ret, args);
    
    
    // 3、after 回调 block
    
    // block 没有 SEL，所以比普通方法少一个参数
    void **callbackArgs = calloc(info->_signature.numberOfArguments - 1, sizeof(void *));
    // 第一个参数是 block 自己
    callbackArgs[0] = (__bridge void *)(info->_block);
    // 从 index = 2 位置开始把 args 中的数据拷贝到 callbackArgs中 (从 index = 1 开始，第 0 个位置留给 block 自己)
    memcpy(callbackArgs + 1, args + 2, sizeof(*args)*(info->_signature.numberOfArguments - 2));
//    for (NSInteger i = 2; i < info->_signature.numberOfArguments; ++i) {
//        callbackArgs[i - 1] = args[i];
//    }
    ffi_call(info->_block_cif, info->_block_IMP, NULL, callbackArgs);
    free(callbackArgs);
}


NS_INLINE ffi_type *libffi_hook_ffi_type(const char *c) {
    switch (c[0]) {
        case 'v':
            return &ffi_type_void;
        case 'c':
            return &ffi_type_schar;
        case 'C':
            return &ffi_type_uchar;
        case 's':
            return &ffi_type_sshort;
        case 'S':
            return &ffi_type_ushort;
        case 'i':
            return &ffi_type_sint;
        case 'I':
            return &ffi_type_uint;
        case 'l':
            return &ffi_type_slong;
        case 'L':
            return &ffi_type_ulong;
        case 'q':
            return &ffi_type_sint64;
        case 'Q':
            return &ffi_type_uint64;
        case 'f':
            return &ffi_type_float;
        case 'd':
            return &ffi_type_double;
        case 'F':
#if CGFLOAT_IS_DOUBLE
            return &ffi_type_double;
#else
            return &ffi_type_float;
#endif
        case 'B':
            return &ffi_type_uint8;
        case '^':
            return &ffi_type_pointer;
        case '@':
            return &ffi_type_pointer;
        case '#':
            return &ffi_type_pointer;
        case ':':
            return &ffi_type_pointer;
        case '{': {
            // http://www.chiark.greenend.org.uk/doc/libffi-dev/html/Type-Example.html
            ffi_type *type = malloc(sizeof(ffi_type));
            type->type = FFI_TYPE_STRUCT;
            NSUInteger size = 0;
            NSUInteger alignment = 0;
            NSGetSizeAndAlignment(c, &size, &alignment);
            type->alignment = alignment;
            type->size = size;
            while (c[0] != '=') ++c; ++c;
            
            NSPointerArray *pointArray = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsOpaqueMemory];
            while (c[0] != '}') {
                ffi_type *elementType = NULL;
                elementType = libffi_hook_ffi_type(c);
                if (elementType) {
                    [pointArray addPointer:elementType];
                    c = NSGetSizeAndAlignment(c, NULL, NULL);
                } else {
                    return NULL;
                }
            }
            NSInteger count = pointArray.count;
            ffi_type **types = malloc(sizeof(ffi_type *) * (count + 1));
            for (NSInteger i = 0; i < count; i++) {
                types[i] = [pointArray pointerAtIndex:i];
            }
            types[count] = NULL; // terminated element is NULL
            
            type->elements = types;
            return type;
        }
    }
    return NULL;
}

@end
