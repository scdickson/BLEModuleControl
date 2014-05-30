//
//  GraphView.m
//  BLEModuleControl
//
//  Created by Sam Dickson on 5/29/14.
//  Copyright (c) 2014 Fluke Networks. All rights reserved.
//

#import "GraphView.h"

@implementation GraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    //NSLog(@"Draw Rect");
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    CGContextSetLineWidth(context, 0.6);
    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
    CGFloat dash[] = {2.0, 2.0};
    CGContextSetLineDash(context, 0.0, dash, 2);
    // How many lines?
    int howMany = (kDefaultGraphWidth - kOffsetX) / kStepX;
    
    // Here the lines go
    for (int i = 0; i < howMany; i++)
    {
        CGContextMoveToPoint(context, kOffsetX + i * kStepX, kGraphTop);
        CGContextAddLineToPoint(context, kOffsetX + i * kStepX, kGraphBottom);
    }
    
    int howManyHorizontal = (kGraphBottom - kGraphTop - kOffsetY) / kStepY;
    for (int i = 0; i <= howManyHorizontal; i++)
    {
        CGContextMoveToPoint(context, kOffsetX, kGraphBottom - kOffsetY - i * kStepY);
        CGContextAddLineToPoint(context, kDefaultGraphWidth, kGraphBottom - kOffsetY - i * kStepY);
    }
    CGContextSetLineDash(context, 0, NULL, 0); // Remove the dash
    CGContextStrokePath(context);
    [self drawLineGraphWithContext:context];
}

- (void)drawLineGraphWithContext:(CGContextRef)ctx
{
    //NSLog(@"Redrawing! Count is %d", [self.data count]);
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetStrokeColorWithColor(ctx, [[UIColor colorWithRed:1.0 green:0.5 blue:0 alpha:1.0] CGColor]);
    int maxGraphHeight = kGraphHeight - kOffsetY;
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, kOffsetX, kGraphHeight - maxGraphHeight * [(NSNumber *)[self.data objectAtIndex:0] floatValue]); //here
    
    for (int i = 1; i < [self.data count]; i++) //here
    {
        float f = [(NSNumber *)[self.data objectAtIndex:i] floatValue];
        //NSLog(@"Point :%f", f);
        CGContextAddLineToPoint(ctx, kOffsetX + i * kStepX, kGraphHeight - maxGraphHeight * f); //here
    }
    
    CGContextDrawPath(ctx, kCGPathStroke);
    CGContextSetFillColorWithColor(ctx, [[UIColor colorWithRed:1.0 green:0.5 blue:0 alpha:1.0] CGColor]);
    for (int i = 1; i < [self.data count] - 1; i++)
    {
        float x = kOffsetX + i * kStepX;
        float y = kGraphHeight - maxGraphHeight * [(NSNumber *)[self.data objectAtIndex:i] floatValue];
        CGRect rect = CGRectMake(x - kCircleRadius, y - kCircleRadius, 2 * kCircleRadius, 2 * kCircleRadius);
        CGContextAddEllipseInRect(ctx, rect);
    }
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
}


@end
