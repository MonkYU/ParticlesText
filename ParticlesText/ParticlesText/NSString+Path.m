//
//  NSString+Path.m
//  Test
//
//  Created by Lizeyu on 2018/8/28.
//  Copyright © 2018 Rose LZY. All rights reserved.
//

#import "NSString+Path.h"
#import <CoreText/CoreText.h>

@implementation NSString (Path)

- (NSArray *)pointsFromFont:(UIFont *)font width:(CGFloat)width height:(CGFloat)height shouldRatio:(BOOL)shouldRatio {
    NSMutableArray *points = [NSMutableArray arrayWithCapacity:1];
    CGMutablePathRef letters = CGPathCreateMutable();
    CGFloat rowHeight = [@"天" boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size.height;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self];
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, self.length)];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    CFArrayRef runArray = CTLineGetGlyphRuns(line);
    for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++)
      {
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        
        for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++)
          {
            CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
            CGGlyph glyph;
            CGPoint position;
            CTRunGetGlyphs(run, thisGlyphRange, &glyph);
            CTRunGetPositions(run, thisGlyphRange, &position);
            CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
            CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
            CGPathAddPath(letters, &t, letter);
            CGPathRelease(letter);
          }
      }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:letters];
    CGRect boundingBox = CGPathGetBoundingBox(letters);
    CGPathRelease(letters);
    CFRelease(line);
    
    // The path is upside down (CG coordinate system)
    [path applyTransform:CGAffineTransformMakeScale(1.0, -1.0)];
    [path applyTransform:CGAffineTransformMakeTranslation(0.0, boundingBox.size.height)];
    
    
    CGRect frame = path.bounds;
    for (CGFloat i = 0; i < frame.origin.x + frame.size.width; i = i + 1) {
        for (CGFloat j = 0; j < frame.origin.y + frame.size.height; j = j + 1) {
            CGPoint point = CGPointMake(i, j);
            if ([path containsPoint:point]) {
                CGFloat widthRation = floorf(point.x / width);
                if (point.x > width) {
                    point.x = point.x - widthRation * width;
                    point.y = point.y + widthRation * rowHeight;
                }
                if (shouldRatio) {
                    point = CGPointMake(point.x / width, point.y / height);
                }
                [points addObject:@(point)];
            }
        }
    }
    return [points copy];
}

@end
