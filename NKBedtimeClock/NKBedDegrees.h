//
//  NKBedDegrees.h
//  NKBedtimeClock
//
//  Created by Niko on 2017/10/19.
//  Copyright © 2017年 Niko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NKBedDegrees : NSObject

@property (nonatomic, assign) CGFloat degrees;
/**
 *  circleChangeDirection
 *  1 -> touch track is clockwise through 0 in clock
 * -1 -> touch track is counterclockwise through 0 in clock
 */
@property (nonatomic, assign) int circleChangeDirection;
@end
