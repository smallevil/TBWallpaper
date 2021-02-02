//
//  UIDevice+ext.h
//  MyCommon
//
//  Created by 思无邪 on 15/1/11.
//  Copyright (c) 2015年 思无邪. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface TBHelper : NSObject

//从UserDefaults得到值
+ (NSString *)getValueFromUserDefaults:(NSString *)key;

//往UserDefaults存值
+ (void)setValueFromUserDefaults:(NSString *)key value:(NSString *)value;

//从UserDefaults删值
+ (void)delValueFromUserDefaults:(NSString *)key;

//得到UDID(利用苹果的idfv)
+ (NSString *)UDID;

+ (NSString *)dictToJson:(NSDictionary *)dict;
+ (NSDictionary *)jsonToDict:(NSString *)jsonString;
+ (NSString *)arrayToJson:(NSArray *)array;
+ (NSMutableArray *)jsonToArray:(NSString *)jsonString;
@end
                              
                                                             
                                             
                             
                                                   
                                     
          
                                                                                           
        
                                                                                                
