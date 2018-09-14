//
//  NSString+Path.h
//  Test
//
//  Created by Lizeyu on 2018/8/28.
//  Copyright © 2018 Rose LZY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Path)
- (NSArray *)pointsFromFont:(UIFont *)font width:(CGFloat)width height:(CGFloat)height shouldRatio:(BOOL)shouldRatio;
@end
