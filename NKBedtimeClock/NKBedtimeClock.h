//
//  NKBedtimeClock.h
//  NKBedtimeClock
//
//  Created by Niko on 2017/10/16.
//  Copyright © 2017年 Niko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKBedtimeClock;

@protocol NKBedtimeClockDelegate <NSObject>

@optional
/**
 *  NKBedtimeClock did update sleeptime or waketime and re-calculate sleepduration (from sleeptime to waketime)
 *  @param bedtimeClock     -> self
 *  @param sleepTime        -> sleep time, format: HH:MM
 *  @param wakeTime         -> wake time, format: HH:MM
 *  @param sleepDuration    -> sleepduation, format: HHhMMmin
 */
- (void)NKBedtimeClock:(NKBedtimeClock *)bedtimeClock didUpdateSleepTime:(NSString *)sleepTime wakeTime:(NSString *)wakeTime sleepDuration:(NSString *)sleepDuration;
@end



@interface NKBedtimeClock : UIView

// MARK: - Accessible properties
@property (nonatomic, assign) BOOL isEnabled;

// MARK: - Color properties
@property (nonatomic, strong) UIColor *trackBackgroundColor;
@property (nonatomic, strong) UIColor *centerBackgroundColor;
@property (nonatomic, strong) UIColor *wakeBackgroundColor;
@property (nonatomic, strong) UIColor *wakeColor;
@property (nonatomic, strong) UIColor *sleepBackgroundColor;
@property (nonatomic, strong) UIColor *sleepColor;
@property (nonatomic, strong) UIColor *trackStartColor;
@property (nonatomic, strong) UIColor *trackEndColor;
@property (nonatomic, strong) UIColor *numberColor;
@property (nonatomic, strong) UIColor *thickPointerColor;
@property (nonatomic, strong) UIColor *thinPointerColor;
@property (nonatomic, strong) UIColor *centerLabelColor;
@property (nonatomic, strong) UIColor *fixedTrackBackgroundColor;

// MARK: - Delegate
@property(nonatomic, assign) id<NKBedtimeClockDelegate> delegate;

/**
 *  init method, better put this view in a content view when the rect setting (CGRect x: >0, y: >0).
 *  @param frame                -> frame (shall be CGRect x: = 0, y: = 0);
 *  @param sleepTimeInMinutes   -> sleep start time in minutes
 *  @param wakeTimeInMinutes    -> wakeup time in miuntes
 */
- (instancetype)initWithFrame:(CGRect)frame sleepTimeInMinutes:(NSTimeInterval)sleepTimeInMinutes wakeTimeInMinutes:(NSTimeInterval)wakeTimeInMinutes;
@end
