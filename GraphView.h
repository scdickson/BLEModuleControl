//
//  GraphView.h
//  BLEModuleControl
//
//  Created by Sam Dickson on 5/29/14.
//  Copyright (c) 2014 Fluke Networks. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kGraphHeight 600
#define kDefaultGraphWidth 900
#define kOffsetX 10
#define kStepX 100
#define kGraphBottom 600
#define kGraphTop 0
#define kStepY 100
#define kOffsetY 10
#define kCircleRadius 4

@interface GraphView : UIView
@property (strong, nonatomic) NSMutableArray *data;
@end
