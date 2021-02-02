//
//  UIDevice+ext.m
//  MyCommon
//
//  Created by 思无邪 on 15/1/11.
//  Copyright (c) 2015年 思无邪. All rights reserved.
//

#import "TBHelper.h"

@implementation TBHelper

//从UserDefaults得到值
+ (NSString *)getValueFromUserDefaults:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}

//往UserDefaults存值
+ (void)setValueFromUserDefaults:(NSString *)key value:(NSString *)value
{
	[[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

//从UserDefaults删值
+ (void)delValueFromUserDefaults:(NSString *)key
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

//得到UDID(利用苹果的idfv)
+ (NSString *)UDID
{
    return [[NSUUID UUID] UUIDString];
}

+ (NSString *)dictToJson:(NSDictionary *)dict
{
    if(dict.count <= 0)
    {
        return @"";
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    
    if (!jsonData) {
        NSLog(@"%@",error);
    } else {
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    NSRange range = {0,jsonString.length};
    
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
}

+ (NSDictionary *)jsonToDict:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }

    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    
    return dic;
}

+ (NSString *)arrayToJson:(NSArray *)array
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];;
}

+ (NSArray *)jsonToArray:(NSString *)jsonString
{
    if (jsonString == nil)
    {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSArray *arr = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:NSJSONReadingMutableContainers
                                                    error:&err];
    
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    
    return arr;
}

@end
                              
                                                             
                                             
                             
                                                   
                                     
          
                                                                                           
        
