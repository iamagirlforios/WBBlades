//
//  WBBladesTool.m
//  WBBlades
//
//  Created by 邓竹立 on 2019/12/30.
//  Copyright © 2019 邓竹立. All rights reserved.
//

#import "WBBladesTool.h"
#import "WBBladesDefines.h"

@implementation WBBladesTool
+ (NSArray *)read_strings:(NSRange &)range fixlen:(NSUInteger)len fromFile:(NSData *)fileData{
    range = NSMakeRange(NSMaxRange(range),len);
    NSMutableArray *strings = [NSMutableArray array];
    
    unsigned long size = 0;
    uint8_t * buffer = (uint8_t *)malloc(len + 1); buffer[len] = '\0';
    [fileData getBytes:buffer range:range];
    uint8_t *p = buffer;
    while (size < len) {
        NSString * str = NSSTRING(p);
        str = [self replaceEscapeCharsInString:str];
        if (str) {
            [strings addObject:str];
            //            NSLog(@"%@",str);
            //+1 是为了留出'\0'的位置
            size = [str length] + size + 1;
            p = p + [str length] + 1;
        }
    }
    free (buffer);
    return [strings copy];
}

+ (NSString *)read_string:(NSRange &)range fixlen:(NSUInteger)len fromFile:(NSData *)fileData{
    range = NSMakeRange(NSMaxRange(range),len);
    uint8_t * buffer = (uint8_t *)malloc(len + 1); buffer[len] = '\0';
    [fileData getBytes:buffer range:range];
    NSString * str = NSSTRING(buffer);
    free (buffer);
    return [self replaceEscapeCharsInString:str];
}

+ (NSData *)read_bytes:(NSRange &)range length:(NSUInteger)length fromFile:(NSData *)fileData{
    range = NSMakeRange(NSMaxRange(range),length);
    uint8_t * buffer = (uint8_t *)malloc(length);
    [fileData getBytes:buffer range:range];
    NSData * ret = [NSData dataWithBytes:buffer length:length];
    free (buffer);
    return ret;
}

+ (NSString *) replaceEscapeCharsInString: (NSString *)orig{
    NSUInteger len = [orig length];
    NSMutableString * str = [[NSMutableString alloc] init];
    SEL sel = @selector(characterAtIndex:);
    unichar (*charAtIdx)(id, SEL, NSUInteger) = (typeof(charAtIdx)) [orig methodForSelector:sel];
    for (NSUInteger i = 0; i < len; i++)
    {
        unichar c = charAtIdx(orig, sel, i);
        switch (c)
        {
            default:    [str appendFormat:@"%C",c]; break;
            case L'\f': [str appendString:@"\\f"]; break; // form feed - new page (byte 0x0c)
            case L'\n': [str appendString:@"\\n"]; break; // line feed - new line (byte 0x0a)
            case L'\r': [str appendString:@"\\r"]; break; // carriage return (byte 0x0d)
            case L'\t': [str appendString:@"\\t"]; break; // horizontal tab (byte 0x09)
            case L'\v': [str appendString:@"\\v"]; break; // vertical tab (byte 0x0b)
        }
    }
    return str;
}

+ (cs_insn * )scanAllASMWithfileData:(NSData *)fileData  begin:(unsigned long long)begin size:(unsigned long long )size vmBase:(unsigned long long)vmAddress{
    
    //获取汇编
    char * ot_sect = (char *)[fileData bytes] + begin - vmAddress;
    uint64_t ot_addr = begin ;
    csh cs_handle = 0;
    cs_insn *cs_insn = NULL;
    cs_err cserr;
    if ((cserr = cs_open(CS_ARCH_ARM64, CS_MODE_ARM, &cs_handle)) != CS_ERR_OK ){
        NSLog(@"Failed to initialize Capstone: %d, %s.", cserr, cs_strerror(cs_errno(cs_handle)));
        return NULL;
    }
    //设置解析模式
    cs_option(cs_handle, CS_OPT_MODE, CS_MODE_ARM);
    //        cs_option(cs_handle, CS_OPT_DETAIL, CS_OPT_ON);
    cs_option(cs_handle, CS_OPT_SKIPDATA, CS_OPT_ON);
    
    //进行反汇编
    size_t disasm_count = cs_disasm(cs_handle, (const uint8_t *)ot_sect, size, ot_addr, 0, &cs_insn);
    if (disasm_count < 1 ) {
        NSLog(@"汇编指令解析不符合预期！");
        return NULL;
    }
    return cs_insn;
}

@end