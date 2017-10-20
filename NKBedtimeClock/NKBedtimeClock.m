//
//  NKBedtimeClock.m
//  NKBedtimeClock
//
//  Created by Niko on 2017/10/16.
//  Copyright © 2017年 Niko. All rights reserved.
//

#import "NKBedtimeClock.h"
#import "NKBedDegrees.h"

//typedef NS_ENUM(int, ResizingBehavior) {
//    aspectFit = 0,
//    aspectFill = 1,
//    stretch = 2,
//    center = 3,
//};

#define circleWidth 156.0
#define circleHeight 195.0

@interface NKBedtimeClock ()

// MARK: - Paths
@property (nonatomic, strong) UIBezierPath *wakePointPath;
@property (nonatomic, strong) UIBezierPath *sleepPointPath;
@property (nonatomic, strong) UIBezierPath *trackBackgroundPath;

// MARK: - Properties
@property (nonatomic, assign) BOOL isAnimatingWake;
@property (nonatomic, assign) BOOL isAnimatingSleep;
@property (nonatomic, assign) BOOL isAnimatingTrack;
@property (nonatomic, assign) CGRect watchDimension;
@property (nonatomic, assign) CGFloat angle;

// MARK: - Position variable properties
@property (nonatomic, assign) BOOL isSleepAM;
@property (nonatomic, assign) BOOL isAwakeAM;

@property (nonatomic, assign) CGContextRef context;
@property (nonatomic, assign) CGRect targetFrame;

@property (nonatomic, assign) CGFloat dayRotation;
@property (nonatomic, assign) CGFloat nightRotation;

@property (nonatomic, assign) CGFloat dayRotationModulus;
@property (nonatomic, assign) CGFloat nightRotationModulus;

@property (nonatomic, assign) CGFloat trackEndAngle;
@property (nonatomic, assign) CGFloat trackStartAngle;

@property (nonatomic, assign) CGFloat startPosition;
@property (nonatomic, assign) CGFloat endPosition;

@property (nonatomic, assign) CGFloat startPositionHour;
@property (nonatomic, assign) CGFloat endPositionHour;

@property (nonatomic, assign) CGFloat startPositionMinute;
@property (nonatomic, assign) CGFloat endPositionMinute;

@property (nonatomic, assign) CGFloat startInMinutes;
@property (nonatomic, assign) CGFloat endInMinutes;

@property (nonatomic, assign) CGFloat dayFrameAngle;
@property (nonatomic, assign) CGFloat nightFrameAngle;

@property (nonatomic, assign) CGFloat dayIconAngle;
@property (nonatomic, assign) CGFloat nightIconAngle;

@property (nonatomic, assign) CGFloat difference;
@property (nonatomic, assign) CGFloat minuteDifference;
@property (nonatomic, assign) CGFloat hourDifference;

@property (nonatomic, strong) NSString *sleepHour;
@property (nonatomic, strong) NSString *wakeHour;
@property (nonatomic, strong) NSString *timeDifference;
@property (nonatomic, assign) BOOL equalPositionInCircle;

@property (nonatomic, assign) CGPoint touchStartPoint;
@end

// MARK: - Position properties
CGFloat pointersY = 50;
CGFloat pointers2Y = -54;
CGFloat pointers3Y = 51;
CGFloat pointers4Y = -55;
CGFloat pointer6Y = 51;
CGFloat pointer12Y = -54;
CGFloat rotation = 0;
// MARK: - Layout properties
CGFloat stateCircleDimension = 18;
CGFloat hourPointerWidth = 1;
CGFloat hourPointerHeight = 3;
CGFloat minutePointerWidth = 0.5;
// MARK: - Fixed properties
CGFloat fullRadians = (360 * M_PI) / 180;
CGFloat minutesPerHour = 60;
CGFloat degreesPerHour = 30;
CGFloat degreesInCircle = 360;
// MARK: per move diffX
CGFloat preMoveDiffX = 10086;

@implementation NKBedtimeClock

# pragma mark - init method
- (instancetype)initWithFrame:(CGRect)frame sleepTimeInMinutes:(NSTimeInterval)sleepTimeInMinutes wakeTimeInMinutes:(NSTimeInterval)wakeTimeInMinutes{
    self = [super initWithFrame:frame];
    if (self) {
        if (sleepTimeInMinutes < 0 || sleepTimeInMinutes > 1440) {
            NSLog(@"sleepTimeInMinutes must be between 0 and 1440, which is 24:00.");
            return self;
        }
        if (wakeTimeInMinutes < 0 || wakeTimeInMinutes > 1440) {
            NSLog(@"wakeTimeInMinutes must be between 0 and 1440, which is 24:00.");
            return self;
        }
        
        // set circle count to confirm 12h & 24h
        self.isSleepAM = sleepTimeInMinutes < 720 ? YES : NO;
        self.isAwakeAM = wakeTimeInMinutes < 720 ? YES : NO;
        
        // set rotation
        self.nightRotation = [self calculateNightRotation:sleepTimeInMinutes];
        self.dayRotation = [self calculateDayRotation:wakeTimeInMinutes];
        
        // set target frame
        self.targetFrame = frame;
        
        // set enable
        self.isEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        [self setNeedsDisplay];
    }
    return self;
}

# pragma mark - draw rect
- (void)drawRect:(CGRect)rect{
    [self drawActivity];
}

- (void)drawActivity{
    
    if (self.context == nil) {
        self.context = UIGraphicsGetCurrentContext();
    }
    
    CGContextRef context = self.context;
    if (context) {
        
        // Resize to target frame
        CGContextSaveGState(context);
        CGRect orginalRect = CGRectMake(0, 0, circleWidth, circleHeight);
        CGRect resizeFrame = CGRectStandardize(orginalRect);
        CGSize scales = CGSizeZero;
        scales.width = fabs(self.targetFrame.size.width / orginalRect.size.width);
        scales.height = fabs(self.targetFrame.size.height / orginalRect.size.height);
        scales.width = MAX(scales.width, scales.height);
        scales.height = scales.width;
        resizeFrame.size.width *= scales.width;
        resizeFrame.size.height *= scales.height;
        resizeFrame.origin.x = CGRectGetMinX(self.targetFrame) + (self.targetFrame.size.width - resizeFrame.size.width) / 2;
        resizeFrame.origin.y = CGRectGetMinY(self.targetFrame) + (self.targetFrame.size.height - resizeFrame.size.height) / 2;

        CGContextTranslateCTM(context, CGRectGetMinX(resizeFrame), CGRectGetMinY(resizeFrame));
        CGContextScaleCTM(context, resizeFrame.size.width / 156, resizeFrame.size.height / 195);
        
        [self drawForms];

        [self restoreState:2];
        
        [self drawWakePoint];
        
        [self restoreState:1];
        
        [self drawBellPath];
        
        [self restoreState:2];
        
        [self drawSleepPoint];
        
        [self drawStarsPath];
        
        [self drawMoonPath];
        
        [self restoreState:4];
        
        [self drawHourPointers];
        
        [self restoreState:3];
        
        [self drawMinutePointers];
        
        [self restoreState:3];
        
        [self drawNumbers];
        
        [self drawCenterLabel];
    }
    
}

- (void)restoreState:(int)times{
    for (int i = 0; i < times; i ++) {
        if (self.context) {
            CGContextRestoreGState(self.context);
        }
    }
}

- (void)drawForms{
    // BackgroundsGroup
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, circleWidth * 0.5, circleHeight * 0.5);
    CGContextRotateCTM(self.context, -[self radians:90.0]);
    
    // OffsetBackground drawing
    UIBezierPath *offsetBackgroundPath = [UIBezierPath bezierPathWithOvalInRect:self.watchDimension];
    [self.fixedTrackBackgroundColor setFill];
    [offsetBackgroundPath fill];
    
    // TrackBackground drawing
    CGContextSaveGState(self.context);
    CGContextRotateCTM(self.context, -[self radians:self.angle]);
    
    CGRect trackBackgroundRect = self.watchDimension;
    CGPoint center = CGPointMake(CGRectGetMidX(trackBackgroundRect), CGRectGetMidY(trackBackgroundRect));
    self.trackBackgroundPath = [UIBezierPath new];
    [self.trackBackgroundPath addArcWithCenter:center radius:trackBackgroundRect.size.width * 0.5 startAngle:-[self radians:self.trackStartAngle] endAngle:-[self radians:self.trackEndAngle] clockwise:YES];
    [self.trackBackgroundPath addLineToPoint:CGPointMake(CGRectGetMidX(trackBackgroundRect), CGRectGetMidY(trackBackgroundRect))];
    [self.trackBackgroundPath closePath];
    
    CGContextSaveGState(self.context);
    
    [self.trackBackgroundPath addClip];
    
    CGColorRef fColor[] = {self.trackStartColor.CGColor, self.trackEndColor.CGColor};
    CFArrayRef colorsRef = CFArrayCreate(kCFAllocatorDefault, (void *)fColor, 2,  NULL);
    CGFloat locations[2] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(nil, colorsRef, locations);
    if (gradient) {
        CGFloat sleepAngle = [self radians:fmod(fmod(self.trackStartAngle, degreesInCircle) + 90, degreesInCircle)];
        CGFloat wakeAngle = [self radians:fmod(fmod(self.trackEndAngle, degreesInCircle) + 90, degreesInCircle)];
        
        CGFloat radius = self.frame.size.width * 0.5;
        CGFloat adjust = 0.60;
        
        CGFloat wakeAngleX = (radius * adjust) * sin(wakeAngle);
        CGFloat wakeAngleY = (radius * adjust) * cos(wakeAngle);
        
        CGFloat sleepAngleX = (radius * adjust) * sin(sleepAngle);
        CGFloat sleepAngleY = (radius * adjust) * cos(sleepAngle);
        
        CGPoint wakePoint = CGPointMake(wakeAngleX, wakeAngleY);
        CGPoint sleepPoint = CGPointMake(sleepAngleX, sleepAngleY);

        CGContextDrawLinearGradient(self.context, gradient, wakePoint, sleepPoint, kCGGradientDrawsBeforeStartLocation);
        CGContextDrawLinearGradient(self.context, gradient, wakePoint, sleepPoint, kCGGradientDrawsAfterEndLocation);
    }
    
    CGContextRestoreGState(self.context);
    
    UIBezierPath *timeBackgroundPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-55, -55, 110, 110)];
    [self.centerBackgroundColor setFill];
    [timeBackgroundPath fill];
    [self.centerBackgroundColor setStroke];
    timeBackgroundPath.lineWidth = 1.5;
    [timeBackgroundPath stroke];
}

- (void)drawWakePoint{
    // TimeGroup
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, circleWidth * 0.5, circleHeight * 0.5);
    CGContextRotateCTM(self.context, [self radians:-90.0]);
    
    CGContextSaveGState(self.context);
    CGContextRotateCTM(self.context, -[self radians:self.dayFrameAngle]);
    
    // WakePoint drawing
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, -6.44, 3.28);
    CGContextRotateCTM(self.context, [self radians:-27.0]);
    
    self.wakePointPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-66.78, -9, stateCircleDimension, stateCircleDimension)];
    [self.wakeBackgroundColor setFill];
    [self.wakePointPath fill];
    [self.trackStartColor setStroke];
    self.wakePointPath.lineWidth = 0.5;
    [self.wakePointPath stroke];
}

- (void)drawBellPath{
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, -58, 29.5);
    CGContextRotateCTM(self.context, -[self radians:self.dayIconAngle]);
    
    UIBezierPath *bellPath = [UIBezierPath new];
    [bellPath moveToPoint:CGPointMake(4.5, 3.07)];
    [bellPath addCurveToPoint:CGPointMake(1.29, 3.9) controlPoint1:CGPointMake(4.5, 3.07) controlPoint2:CGPointMake(2.79, 3.64)];
    [bellPath addCurveToPoint:CGPointMake(0, 5) controlPoint1:CGPointMake(1.19, 4.52) controlPoint2:CGPointMake(0.65, 5)];
    [bellPath addCurveToPoint:CGPointMake(-1.28, 3.89) controlPoint1:CGPointMake(-0.65, 5) controlPoint2:CGPointMake(-1.19, 4.52)];
    [bellPath addCurveToPoint:CGPointMake(-4.5, 3.08) controlPoint1:CGPointMake(-2.79, 3.63) controlPoint2:CGPointMake(-4.5, 3.08)];
    [bellPath addCurveToPoint:CGPointMake(-2.83, 0.56) controlPoint1:CGPointMake(-3.9, 2.34) controlPoint2:CGPointMake(-2.81, 1.35)];
    [bellPath addLineToPoint:CGPointMake(-2.88, -1.04)];
    [bellPath addCurveToPoint:CGPointMake(-0.89, -4.22) controlPoint1:CGPointMake(-2.87, -2.58) controlPoint2:CGPointMake(-2.34, -3.85)];
    [bellPath addCurveToPoint:CGPointMake(0, -5) controlPoint1:CGPointMake(-0.83, -4.66) controlPoint2:CGPointMake(-0.45, -5)];
    [bellPath addCurveToPoint:CGPointMake(0.89, -4.22) controlPoint1:CGPointMake(0.46, -5) controlPoint2:CGPointMake(0.84, -4.66)];
    [bellPath addCurveToPoint:CGPointMake(2.93, -1.03) controlPoint1:CGPointMake(2.33, -3.86) controlPoint2:CGPointMake(2.91, -2.58)];
    [bellPath addLineToPoint:CGPointMake(2.89, 0.56)];
    [bellPath addCurveToPoint:CGPointMake(4.5, 3.07) controlPoint1:CGPointMake(2.87, -1.36) controlPoint2:CGPointMake(3.87, 2.39)];
    [bellPath closePath];
    bellPath.usesEvenOddFillRule = YES;
    [self.wakeColor setFill];
    [bellPath fill];
}

- (void)drawSleepPoint{
    CGContextSaveGState(self.context);
    CGContextRotateCTM(self.context, [self radians:-(self.nightFrameAngle - 720)]);
    
    // SleepPoint drawing
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, -6.25, -3.61);
    CGContextRotateCTM(self.context, [self radians:-510.0]);
    
    self.sleepPointPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(48.78, -9, stateCircleDimension, stateCircleDimension)];
    [self.sleepBackgroundColor setFill];
    [self.sleepPointPath fill];
    [self.trackEndColor setStroke];
    self.sleepPointPath.lineWidth = 0.5;
    [self.sleepPointPath stroke];
    
    [self restoreState:1];
    
    // MoonIcon
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, -51.77, -37.47);
    CGContextRotateCTM(self.context, [self radians:90.0]);
    
    // Sleep
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, 4.99, 4.99);
    CGContextRotateCTM(self.context, [self radians:-self.nightIconAngle]);
}

- (void)drawStarsPath{
    UIBezierPath *starsPath = [UIBezierPath new];
    [starsPath moveToPoint:CGPointMake(2.19, -3.11)];
    [starsPath addCurveToPoint:CGPointMake(1.6, -3.7) controlPoint1:CGPointMake(2.09, -3.35) controlPoint2:CGPointMake(1.83, -3.61)];
    [starsPath addLineToPoint:CGPointMake(1.29, -3.82)];
    [starsPath addLineToPoint:CGPointMake(1.6, -3.95)];
    [starsPath addCurveToPoint:CGPointMake(2.19, -4.53) controlPoint1:CGPointMake(1.83, -4.04) controlPoint2:CGPointMake(2.09, -4.3)];
    [starsPath addLineToPoint:CGPointMake(2.31, -4.85)];
    [starsPath addLineToPoint:CGPointMake(2.43, -4.53)];
    [starsPath addCurveToPoint:CGPointMake(3.02, -3.95) controlPoint1:CGPointMake(2.52, -4.3) controlPoint2:CGPointMake(2.78, -4.04)];
    [starsPath addLineToPoint:CGPointMake(3.33, -3.82)];
    [starsPath addLineToPoint:CGPointMake(3.02, -3.7)];
    [starsPath addCurveToPoint:CGPointMake(2.43, -3.11) controlPoint1:CGPointMake(2.78, -3.61) controlPoint2:CGPointMake(2.52, -3.35)];
    [starsPath addLineToPoint:CGPointMake(2.31, -2.8)];
    [starsPath addLineToPoint:CGPointMake(2.19, -3.11)];
    [starsPath closePath];
    [starsPath moveToPoint:CGPointMake(3.28, -1.27)];
    [starsPath addCurveToPoint:CGPointMake(2.92, -1.64) controlPoint1:CGPointMake(3.23, -1.42) controlPoint2:CGPointMake(3.07, -1.58)];
    [starsPath addLineToPoint:CGPointMake(2.9, -1.65)];
    [starsPath addLineToPoint:CGPointMake(2.92, -1.66)];
    [starsPath addCurveToPoint:CGPointMake(3.28, -2.02) controlPoint1:CGPointMake(3.06, -1.71) controlPoint2:CGPointMake(3.23, -1.88)];
    [starsPath addLineToPoint:CGPointMake(3.29, -2.04)];
    [starsPath addLineToPoint:CGPointMake(3.3, -2.02)];
    [starsPath addCurveToPoint:CGPointMake(3.67, -1.66) controlPoint1:CGPointMake(3.36, -1.88) controlPoint2:CGPointMake(3.52, -1.71)];
    [starsPath addLineToPoint:CGPointMake(3.69, -1.65)];
    [starsPath addLineToPoint:CGPointMake(3.67, -1.64)];
    [starsPath addCurveToPoint:CGPointMake(3.3, -1.27) controlPoint1:CGPointMake(3.52, -1.58) controlPoint2:CGPointMake(3.36, -1.42)];
    [starsPath addLineToPoint:CGPointMake(3.29, -1.25)];
    [starsPath addLineToPoint:CGPointMake(3.28, -1.27)];
    [starsPath closePath];
    [starsPath moveToPoint:CGPointMake(1.3, -0.14)];
    [starsPath addCurveToPoint:CGPointMake(0.93, -0.5) controlPoint1:CGPointMake(1.24, -0.28) controlPoint2:CGPointMake(1.08, -0.45)];
    [starsPath addLineToPoint:CGPointMake(0.91, -0.51)];
    [starsPath addLineToPoint:CGPointMake(0.93, -0.52)];
    [starsPath addCurveToPoint:CGPointMake(1.3, -0.89) controlPoint1:CGPointMake(1.08, -0.58) controlPoint2:CGPointMake(1.24, -0.74)];
    [starsPath addLineToPoint:CGPointMake(1.31, -0.91)];
    [starsPath addLineToPoint:CGPointMake(1.32, -0.89)];
    [starsPath addCurveToPoint:CGPointMake(1.68, -0.52) controlPoint1:CGPointMake(1.37, -0.74) controlPoint2:CGPointMake(1.53, -0.58)];
    [starsPath addLineToPoint:CGPointMake(1.7, -0.51)];
    [starsPath addLineToPoint:CGPointMake(1.68, -0.5)];
    [starsPath addCurveToPoint:CGPointMake(1.32, -0.14) controlPoint1:CGPointMake(1.54, -0.45) controlPoint2:CGPointMake(1.37, -0.29)];
    [starsPath addLineToPoint:CGPointMake(1.31, -0.12)];
    [starsPath addLineToPoint:CGPointMake(1.3, -0.14)];
    [starsPath closePath];
    starsPath.usesEvenOddFillRule = YES;
    [self.sleepColor setFill];
    [starsPath fill];
    
}

- (void)drawMoonPath{
    
    UIBezierPath *moonPath = [UIBezierPath new];
    [moonPath moveToPoint:CGPointMake(-1.41, -4.99)];
    [moonPath addCurveToPoint:CGPointMake(-4.99, -0.12) controlPoint1:CGPointMake(-3.48, -4.34) controlPoint2:CGPointMake(-4.99, -2.4)];
    [moonPath addCurveToPoint:CGPointMake(0.12, 4.99) controlPoint1:CGPointMake(-4.99, 2.7) controlPoint2:CGPointMake(-2.7, 4.99)];
    [moonPath addCurveToPoint:CGPointMake(4.99, 1.41) controlPoint1:CGPointMake(2.4, 4.99) controlPoint2:CGPointMake(4.34, 3.48)];
    [moonPath addCurveToPoint:CGPointMake(2.04, 2.49) controlPoint1:CGPointMake(4.2, 2.09) controlPoint2:CGPointMake(3.17, 2.49)];
    [moonPath addCurveToPoint:CGPointMake(-2.49, -2.04) controlPoint1:CGPointMake(-0.46, 2.49) controlPoint2:CGPointMake(-2.49, 0.46)];
    [moonPath addCurveToPoint:CGPointMake(-1.41, -4.99) controlPoint1:CGPointMake(-2.49, -3.17) controlPoint2:CGPointMake(-2.09, -4.2)];
    [moonPath closePath];
    moonPath.usesEvenOddFillRule = YES;
    [self.sleepColor setFill];
    [moonPath fill];
    
}

- (void)drawHourPointers{
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, circleWidth * 0.5, circleHeight * 0.5);
    CGContextRotateCTM(self.context, -fullRadians);
    
    [self drawHourGroup:-90];
    
    [self restoreState:1];
    
    [self drawHourPointer:pointer12Y];
    [self drawHourPointer:pointer6Y];
    
    [self drawHourGroup:-degreesPerHour];
    [self drawHourGroup:-90];
    
    [self restoreState:2];
    
    [self drawHourGroup:-60];
    [self drawHourGroup:-90];
}

- (void)drawHourGroup:(CGFloat)rotate{
    CGContextSaveGState(self.context);
    CGContextRotateCTM(self.context, [self radians:rotate]);
    
    [self drawHourPointer:pointers2Y];
    [self drawHourPointer:pointers3Y];
    
}

- (void)drawHourPointer:(CGFloat)y{
    UIBezierPath *hourPath = [UIBezierPath bezierPathWithRect:CGRectMake(-0.5, y, hourPointerWidth, hourPointerHeight)];
    [self.thickPointerColor setFill];
    [hourPath fill];
}

typedef struct {
    CGPoint translate;
    CGFloat rotate;
}group;

typedef struct {
    CGPoint translate;
    CGPoint position;
}pointer;

typedef struct {
    CGPoint translate;
    CGPoint position;
}opposite;


- (void)drawMinutePointers{
    
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, circleWidth * 0.5, circleHeight * 0.5);
    CGContextRotateCTM(self.context, -fullRadians);
    
    
    group group1 = {CGPointMake(0, 1), -7.5};
    pointer pointer1 = {CGPointMake(0, pointers4Y), CGPointMake(0, 0)};
    opposite opposite1 = {CGPointMake(-0, pointersY), CGPointMake(0, 0)};
    [self drawMinuteGroup:group1 pointer:pointer1 oppsite:opposite1];
    [self restoreState:2];
    
    group group2 = {CGPointMake(0, 1), -15};
    pointer pointer2 = {CGPointMake(-0, pointers4Y), CGPointMake(0, -0)};
    opposite opposite2 = {CGPointMake(-0, pointersY), CGPointMake(0, 0)};
    [self drawMinuteGroup:group2 pointer:pointer2 oppsite:opposite2];
    [self restoreState:2];
    
    group group3 = {CGPointMake(0, 1), -22.5};
    pointer pointer3 = {CGPointMake(-0, pointers4Y), CGPointMake(0, 0)};
    opposite opposite3 = {CGPointMake(-0, pointersY), CGPointMake(0, 0)};
    [self drawMinuteGroup:group3 pointer:pointer3 oppsite:opposite3];
    [self restoreState:2];
    
    group group4 = {CGPointZero, -37.5};
    pointer pointer4 = {CGPointMake(0, pointers2Y), CGPointMake(0, 0)};
    opposite opposite4 = {CGPointMake(0, pointers3Y), CGPointMake(-0, 0)};
    [self drawMinuteGroup:group4 pointer:pointer4 oppsite:opposite4];
    [self restoreState:2];
    
    group group5 = {CGPointZero, -45};
    pointer pointer5 = {CGPointMake(-0, pointers2Y), CGPointMake(-0, 0)};
    opposite opposite5 = {CGPointMake(-0, pointers3Y), CGPointMake(0, 0)};
    [self drawMinuteGroup:group5 pointer:pointer5 oppsite:opposite5];
    [self restoreState:2];
    
    group group6 = {CGPointZero, -52.5};
    pointer pointer6 = {CGPointMake(-0, pointers2Y), CGPointMake(-0, 0)};
    opposite opposite6 = {CGPointMake(-0, pointers3Y), CGPointMake(-0, 0)};
    [self drawMinuteGroup:group6 pointer:pointer6 oppsite:opposite6];
    [self restoreState:2];
    
    group group7 = {CGPointZero, -97.5};
    pointer pointer7 = {CGPointMake(-0, pointers2Y), CGPointMake(0, -0)};
    opposite opposite7 = {CGPointMake(-0, pointers3Y), CGPointMake(0, -0)};
    [self drawMinuteGroup:group7 pointer:pointer7 oppsite:opposite7];
    [self restoreState:2];
    
    group group8 = {CGPointZero, -105};
    pointer pointer8 = {CGPointMake(-0, pointers2Y), CGPointMake(0, -0)};
    opposite opposite8 = {CGPointMake(-0, pointers3Y), CGPointMake(0, 0)};
    [self drawMinuteGroup:group8 pointer:pointer8 oppsite:opposite8];
    [self restoreState:2];
    
    group group9 = {CGPointZero, -112.5};
    pointer pointer9 = {CGPointMake(-0, pointers2Y), CGPointMake(0, 0)};
    opposite opposite9 = {CGPointMake(-0, pointers3Y), CGPointMake(-0, 0)};
    [self drawMinuteGroup:group9 pointer:pointer9 oppsite:opposite9];
    [self restoreState:2];
    
    group group10 = {CGPointZero, -127.5};
    pointer pointer10 = {CGPointMake(-0, pointers2Y), CGPointMake(-0, -0)};
    opposite opposite10 = {CGPointMake(-0, pointers3Y), CGPointMake(-0, -0)};
    [self drawMinuteGroup:group10 pointer:pointer10 oppsite:opposite10];
    [self restoreState:2];
    
    group group11 = {CGPointZero, -135};
    pointer pointer11 = {CGPointMake(-0, pointers2Y), CGPointMake(0, -0)};
    opposite opposite11 = {CGPointMake(-0, pointers3Y), CGPointMake(0, -0)};
    [self drawMinuteGroup:group11 pointer:pointer11 oppsite:opposite11];
    [self restoreState:2];
    
    group group12 = {CGPointZero, -142.5};
    pointer pointer12 = {CGPointMake(-0, pointers2Y), CGPointMake(-0, -0)};
    opposite opposite12 = {CGPointMake(-0, pointers3Y), CGPointMake(-0, -0)};
    [self drawMinuteGroup:group12 pointer:pointer12 oppsite:opposite12];
    [self restoreState:2];
    
    group group13 = {CGPointMake(0.08, -0.05), -157.5};
    pointer pointer13 = {CGPointMake(-0, pointers2Y), CGPointMake(-0, 0)};
    opposite opposite13 = {CGPointMake(-0, pointers3Y), CGPointMake(-0, 0)};
    [self drawMinuteGroup:group13 pointer:pointer13 oppsite:opposite13];
    [self restoreState:2];
    
    group group14 = {CGPointMake(0.08, -0.05), -165};
    pointer pointer14 = {CGPointMake(0, pointers2Y), CGPointMake(0, 0)};
    opposite opposite14 = {CGPointMake(0, pointers3Y), CGPointMake(0, -0)};
    [self drawMinuteGroup:group14 pointer:pointer14 oppsite:opposite14];
    [self restoreState:2];
    
    group group15 = {CGPointMake(0.08, -0.05), -172.5};
    pointer pointer15 = {CGPointMake(0, pointers2Y), CGPointMake(-0, 0)};
    opposite opposite15 = {CGPointMake(0, pointers3Y), CGPointMake(-0, 0)};
    [self drawMinuteGroup:group15 pointer:pointer15 oppsite:opposite15];
    [self restoreState:2];
    
    group group16 = {CGPointMake(-1.05, -0.08), 112.5};
    pointer pointer16 = {CGPointMake(0, pointers4Y), CGPointMake(0, 0)};
    opposite opposite16 = {CGPointMake(0, pointersY), CGPointMake(0, 0)};
    [self drawMinuteGroup:group16 pointer:pointer16 oppsite:opposite16];
    [self restoreState:2];
    
    group group17 = {CGPointMake(-1.05, -0.08), 105};
    pointer pointer17 = {CGPointMake(0, pointers4Y), CGPointMake(0, 0)};
    opposite opposite17 = {CGPointMake(0, pointersY), CGPointMake(0, 0)};
    [self drawMinuteGroup:group17 pointer:pointer17 oppsite:opposite17];
    [self restoreState:2];
    
    group group18 = {CGPointMake(-1.05, -0.08), 97.5};
    pointer pointer18 = {CGPointMake(-0, pointers4Y), CGPointMake(0, -0)};
    opposite opposite18 = {CGPointMake(0, pointersY), CGPointMake(0, 0)};
    [self drawMinuteGroup:group18 pointer:pointer18 oppsite:opposite18];
}

- (void)drawMinuteGroup:(group)group pointer:(pointer)pointer oppsite:(opposite)oppsite{
    
    CGContextSaveGState(self.context);
    
    CGPoint translate = group.translate;
    CGContextTranslateCTM(self.context, translate.x, translate.y);
    CGContextRotateCTM(self.context, [self radians:group.rotate]);
    
    [self drawMinuteWrap:pointer.translate point:pointer.position];
    
    [self restoreState:1];
    
    [self drawMinuteWrap:oppsite.translate point:pointer.position];
    
}

- (void)drawMinuteWrap:(CGPoint)translate point:(CGPoint)point{
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, translate.x, translate.y);
    
    [self drawMinutePointer:point];
}

- (void)drawMinutePointer:(CGPoint)point{
    
    UIBezierPath *minutePath = [UIBezierPath new];
    [minutePath moveToPoint:point];
    [minutePath addLineToPoint:CGPointMake(0, hourPointerHeight)];
    [minutePath addLineToPoint:CGPointMake(0, hourPointerHeight)];
    [self.thinPointerColor setFill];
    [minutePath fill];
    [self.thinPointerColor setStroke];
    minutePath.lineWidth = minutePointerWidth;
    [minutePath stroke];
    
}

- (void)drawNumbers{
    CGContextSaveGState(self.context);
    CGContextTranslateCTM(self.context, circleWidth * 0.5, circleHeight * 0.5);
    CGContextRotateCTM(self.context, -fullRadians);
    
    [self drawNumber:@"12" position:CGPointMake(-5, -47.5)];
    [self restoreState:1];
    
    [self drawNumber:@"2" position:CGPointMake(34, -26)];
    [self restoreState:1];
    
    [self drawNumber:@"3" position:CGPointMake(40, -5)];
    [self restoreState:1];
    
    [self drawNumber:@"4" position:CGPointMake(34, 16)];
    [self restoreState:1];
    
    [self drawNumber:@"5" position:CGPointMake(18, 32)];
    [self restoreState:1];
    
    [self drawNumber:@"6" position:CGPointMake(-5, 39)];
    [self restoreState:1];
    
    [self drawNumber:@"7" position:CGPointMake(-26, 32)];
    [self restoreState:1];
    
    [self drawNumber:@"8" position:CGPointMake(-43, 16)];
    [self restoreState:1];
    
    [self drawNumber:@"9" position:CGPointMake(-50, -5)];
    [self restoreState:1];
    
    [self drawNumber:@"10" position:CGPointMake(-42, -26)];
    [self restoreState:1];
    
    [self drawNumber:@"1" position:CGPointMake(16, -43)];
    [self restoreState:1];
    
    [self drawNumber:@"11" position:CGPointMake(-24, -43)];
    [self restoreState:2];
}

- (void)drawNumber:(NSString *)text position:(CGPoint)position{
    CGRect rect = CGRectMake(position.x, position.y, 10, 10);
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSTextAlignmentCenter;
    
    NSDictionary *fontAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"Arial" size:8], NSForegroundColorAttributeName:self.numberColor, NSParagraphStyleAttributeName:style};
    CGFloat height = [text boundingRectWithSize:CGSizeMake(rect.size.width, INFINITY) options:NSStringDrawingUsesLineFragmentOrigin attributes:fontAttributes context:nil].size.height;
    
    CGContextSaveGState(self.context);
    CGContextClipToRect(self.context, rect);
    
    [text drawInRect:CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect) + (rect.size.height - height) * 0.5, rect.size.width, height) withAttributes:fontAttributes];
}

- (void)drawCenterLabel{
    CGRect durationRect = CGRectMake(44, 82, 69, degreesPerHour);
    NSMutableParagraphStyle *durationStyle = [NSMutableParagraphStyle new];
    durationStyle.alignment = NSTextAlignmentCenter;
    
    //+ (UIFont *)systemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight
    NSDictionary *durationFontAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont smallSystemFontSize] weight: UIFontWeightLight], NSForegroundColorAttributeName: self.centerLabelColor, NSParagraphStyleAttributeName: durationStyle};
    
    CGFloat durationTextHeight = [self.timeDifference boundingRectWithSize:CGSizeMake(durationRect.size.width, INFINITY) options:NSStringDrawingUsesLineFragmentOrigin attributes:durationFontAttributes context:nil].size.height;
    
    CGContextSaveGState(self.context);
    CGContextClipToRect(self.context, durationRect);
    
    [self.timeDifference drawInRect:CGRectMake(CGRectGetMinX(durationRect), CGRectGetMinY(durationRect) + (durationRect.size.height - durationTextHeight) * 0.5, durationRect.size.width, durationTextHeight) withAttributes:durationFontAttributes];
    
    [self restoreState:2];
}

# pragma mark - touch method
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];

    if (self.isEnabled) {
        
        if ([touches allObjects] == nil) {
            return;
        }
        UITouch *touch = [touches anyObject];
        
        CGPoint location = [touch locationInView:self];
        
        CGFloat diffX = location.x - self.frame.size.width * 0.5;
        CGFloat diffY = location.y - self.frame.size.height * 0.5;
        CGFloat tan = atan2(diffY, diffX);
        CGFloat degress = fmod(degreesInCircle - [self degress:tan], degreesInCircle);
        
        CGFloat clickAngle = [self radians:degress];
        CGFloat sleepAngle = [self radians:fmod(fmod(self.trackStartAngle, degreesInCircle) + 90, degreesInCircle)];
        CGFloat wakeAngle = [self radians:fmod(fmod(self.trackEndAngle, degreesInCircle) + 90, degreesInCircle)];
        
        CGFloat radius = self.frame.size.width * 0.5;
        
        CGFloat clickAngleX = radius * sin(clickAngle);
        CGFloat clickAngleY = radius * cos(clickAngle);
        
        CGFloat wakeAngleX = radius * sin(wakeAngle);
        CGFloat wakeAngleY = radius * cos(wakeAngle);
        
        CGFloat sleepAngleX = radius * sin(sleepAngle);
        CGFloat sleepAngleY = radius * cos(sleepAngle);
        
        CGPoint clickPoint = CGPointMake(clickAngleX, clickAngleY);
        CGPoint wakePoint = CGPointMake(wakeAngleX, wakeAngleY);
        CGPoint sleepPoint = CGPointMake(sleepAngleX, sleepAngleY);
        
        CGFloat distanceClickWake = hypot(clickPoint.x - wakePoint.x, clickPoint.y - wakePoint.y);
        CGFloat distanceClickSleep = hypot(clickPoint.x - sleepPoint.x, clickPoint.y - sleepPoint.y);
        
        CGFloat distanceWakeToCenter = hypot(diffX, diffY);
        
        if (distanceWakeToCenter <= 180 && distanceWakeToCenter >= 130) {
            self.isAnimatingSleep = distanceClickSleep <= 35 && distanceClickSleep <= distanceClickWake;
            
            if (!self.isAnimatingSleep) {
                self.isAnimatingWake = distanceClickWake <= 35 && distanceClickWake < distanceClickSleep;
            }
            
            if (!self.isAnimatingSleep && !self.isAnimatingWake) {
                NSLog(@"No touch point!");
            }
        }
        self.touchStartPoint = CGPointMake(diffX, diffY);
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    
    if ([touches allObjects] == nil) {
        return;
    }
    UITouch *touch = [touches anyObject];
    
    NKBedDegrees *bedDegrees = [self calculateDegress:[touch locationInView:self] counterClockWise:NO];
    CGFloat degreesInMinutes = [self calculateFullTimeFromDegress:bedDegrees.degrees];
    
    if (bedDegrees.circleChangeDirection > 0) {
        NSLog(@"Clockwise add one circle");
    }
    
    if (bedDegrees.circleChangeDirection < 0) {
        NSLog(@"Counterclockwise minus one circle");
    }
    
    if (self.isAnimatingSleep) {
        self.isSleepAM = bedDegrees.circleChangeDirection == 0 ? self.isSleepAM : !self.isSleepAM;
        self.nightRotation = [self calculateNightRotation:degreesInMinutes];
    }
    if (self.isAnimatingWake) {
        self.isAwakeAM = bedDegrees.circleChangeDirection == 0 ? self.isAwakeAM : !self.isAwakeAM;
        self.dayRotation = [self calculateDayRotation:degreesInMinutes];
    }
    if (self.isAnimatingTrack) {
        self.dayRotation = [self calculateDayRotation:degreesInMinutes];
        self.nightRotation = [self calculateDayRotation:degreesInMinutes];
    }
    
    [self updateLayout];
}

- (void)updateLayout{
    [self setNeedsDisplay];
    
    if ([self.delegate respondsToSelector:@selector(NKBedtimeClock:didUpdateSleepTime:wakeTime:sleepDuration:)]) {
        [self.delegate NKBedtimeClock:self didUpdateSleepTime:self.sleepHour wakeTime:self.wakeHour sleepDuration:self.timeDifference];
    }
}

- (double)angle:(CGPoint)start end:(CGPoint)end{
    
    CGFloat dx = end.x - start.x;
    CGFloat dy = end.y - start.y;
    CGFloat abs_dy = fabs(dy);
    
    // calculate radians
    CGFloat theta = atan(abs_dy/dx);
    CGFloat mmmm_pie = 3.1415927;
    
    // calculate to degress, some API use degress, some use raidans
    CGFloat degrees = (theta * 350 / (2 * mmmm_pie)) + (dx < 0 ? 100 : 0);
    
    //transmogrify to negative for upside down angles
    double negafied = dy > 0 ? degrees * -1 : degrees;
    return negafied;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    
    _isAnimatingWake = NO;
    _isAnimatingSleep = NO;
    _isAnimatingTrack = NO;
}

# pragma mark - calculate functions
- (CGFloat)calculateFullTimeFromDegress:(CGFloat)degrees{
    CGFloat degressHours = floor(degrees / degreesPerHour);
    CGFloat degressMinutes = floor(fmod(floor(degrees), degreesPerHour) * 2 * 0.2) * 5;
    return degressHours * minutesPerHour + degressMinutes;
}

- (CGFloat)calculateNightRotation:(CGFloat)number{
    CGFloat modNight = fmod(number, 10);
    CGFloat nightRotation = (720 - (modNight > 5 ? ceil(number / 2) : floor(number / 2)));
    return nightRotation;
}

- (CGFloat)calculateDayRotation:(CGFloat)number{
    CGFloat modDay = fmodf(number, 10);
    CGFloat dayRotation = (540 - (modDay > 5 ? floor(number / 2) : ceil(number / 2)));
    return dayRotation;
}

- (NKBedDegrees *)calculateDegress:(CGPoint)location counterClockWise:(BOOL)counterClockWise{
    
    NKBedDegrees *bedDegrees = [NKBedDegrees new];
    CGFloat diffX = location.x - self.frame.size.width * 0.5;
    CGFloat diffY = location.y - self.frame.size.height * 0.5;
    
    bedDegrees.circleChangeDirection = 0;
    if (diffY < 0) {
        if (preMoveDiffX == 10086) {
            preMoveDiffX = diffX;
        }else{
            
            if (preMoveDiffX >= 0) {
                if (diffX < 0) {
                    bedDegrees.circleChangeDirection = -1;
                    preMoveDiffX = 10086;
                }else{
                    preMoveDiffX = diffX;
                }
            }else{
                if (diffX >= 0) {
                    bedDegrees.circleChangeDirection = 1;
                    preMoveDiffX = 10086;
                }else{
                    preMoveDiffX = diffX;
                }
            }
        }
    }else{
        preMoveDiffX = 10086;
    }

    CGFloat radians = counterClockWise ? atan2(diffY, diffX) : atan2(-diffX, -diffY);
    CGFloat degrees = [self degress:radians];
    
    bedDegrees.degrees = abs(-degrees < 0 ? degreesInCircle - degrees : - degrees);
    return bedDegrees;
}

# pragma mark - init propertys
- (void)setIsEnabled:(BOOL)isEnabled{
    _isEnabled = isEnabled;
    if (!isEnabled) {
        _isAnimatingWake = NO;
        _isAnimatingSleep = NO;
        _isAnimatingTrack = NO;
    }
}

- (void)setDayRotation:(CGFloat)dayRotation{
    _dayRotation = dayRotation;
    [self updateLayout];
}

- (void)setNightRotation:(CGFloat)nightRotation{
    _nightRotation = nightRotation;
    [self updateLayout];
}

- (CGRect)watchDimension{
    return CGRectMake(-74.28, -74.28, 148.5, 148.5);
}

- (CGFloat)angle{
    return -720 * rotation;
}

- (UIColor *)trackBackgroundColor{
    return [UIColor colorWithRed:0.087 green:0.088 blue:0.087 alpha:1.000];
}

- (UIColor *)centerBackgroundColor{
    return [UIColor colorWithRed:0.049 green:0.049 blue:0.049 alpha:1.000];
}

- (UIColor *)wakeBackgroundColor{
    return [UIColor colorWithRed:0.049 green:0.049 blue:0.049 alpha:1.000];
}

- (UIColor *)wakeColor{
    return [UIColor colorWithRed:0.976 green:0.645 blue:0.068 alpha:1.000];
}

- (UIColor *)sleepBackgroundColor{
    return [UIColor colorWithRed:0.049 green:0.049 blue:0.049 alpha:1.000];
}

- (UIColor *)sleepColor{
    return [UIColor colorWithRed:0.976 green:0.645 blue:0.068 alpha:1.000];
}

- (UIColor *)trackStartColor{
    return [UIColor colorWithRed:0.976 green:0.645 blue:0.068 alpha:1.000];
}

- (UIColor *)trackEndColor{
    return [UIColor orangeColor];
}

- (UIColor *)numberColor{
    return [UIColor colorWithRed:0.557 green:0.554 blue:0.576 alpha:1.000];
}

- (UIColor *)thickPointerColor{
    return [UIColor colorWithRed:0.557 green:0.554 blue:0.576 alpha:1.000];
}

- (UIColor *)thinPointerColor{
    return [UIColor colorWithRed:0.329 green:0.329 blue:0.329 alpha:1.000];
}

- (UIColor *)centerLabelColor{
    return [UIColor whiteColor];
}

- (CGFloat)dayRotationModulus{
    return fmod(self.dayRotation, 720);
}

- (CGFloat)nightRotationModulus{
    return fmod(self.nightRotation, 720);
}

- (CGFloat)trackEndAngle{
    return abs(self.dayRotationModulus + 540);
}

- (CGFloat)trackStartAngle{
    return self.nightRotationModulus;
}

- (UIColor *)fixedTrackBackgroundColor{
    return self.equalPositionInCircle ? self.trackStartColor : self.trackBackgroundColor;
}

- (CGFloat)startPosition{
    return fmod((720 - fmod((180 + self.dayRotationModulus), 720)), 720);
}

- (CGFloat)endPosition{
    return fmod((720 - self.nightRotationModulus), 720);
}

- (CGFloat)startPositionHour{
    return floor(self.startPosition / degreesPerHour);
}

- (CGFloat)endPositionHour{
    return floor(self.endPosition / degreesPerHour);
}

- (CGFloat)startPositionMinute{
    return floor(fmod(floor(self.startPosition), degreesPerHour) * 2 / 5.0) * 5;
}

- (CGFloat)endPositionMinute{
    return ceil(fmod(floor(self.endPosition), degreesPerHour) * 2 / 5.0) * 5;
}
- (CGFloat)startInMinutes{
    return self.startPositionHour * minutesPerHour + self.startPositionMinute;
}

- (CGFloat)endInMinutes{
    return self.endPositionHour * minutesPerHour + self.endPositionMinute;
}

- (CGFloat)dayFrameAngle{
    return self.dayRotation - 27;
}

- (CGFloat)nightFrameAngle{
    return self.nightRotation + 210;
}

- (CGFloat)dayIconAngle{
    return -(self.dayRotation + 64.5);
}

- (CGFloat)nightIconAngle{
    return -(self.nightRotation + 220);
}

- (CGFloat)difference{
    return self.endInMinutes > self.startInMinutes ? 1440 - self.endInMinutes + self.startInMinutes : abs(self.endInMinutes - self.startInMinutes);
}

- (CGFloat)minuteDifference{
    return fmod(self.difference, minutesPerHour);
}

- (CGFloat)hourDifference{
    return self.startPosition == self.endPosition ? 0 : floor(fmod(self.difference / minutesPerHour, minutesPerHour));
}

- (NSString *)sleepHour{
    int hour = self.endInMinutes / minutesPerHour;
    hour = self.isSleepAM ? hour : (hour + 12 > 23 ? hour : hour + 12);
    int minutes = fmod(self.endInMinutes, minutesPerHour);
    return [NSString stringWithFormat:@"%02d:%02d", hour, minutes];
}

- (NSString *)wakeHour{
    int hour = self.startInMinutes / minutesPerHour;
    hour = self.isAwakeAM ? hour : (hour + 12 > 23 ? hour : hour + 12);
    int minutes = fmod(self.startInMinutes, minutesPerHour);
    return [NSString stringWithFormat:@"%02d:%02d", hour, minutes];
}

- (NSString *)timeDifference{
    
    int sleepHour = self.endInMinutes / minutesPerHour;
    sleepHour = self.isSleepAM ? sleepHour : (sleepHour + 12 > 23 ? sleepHour : sleepHour + 12);
    int sleepMinutes = fmod(self.endInMinutes, minutesPerHour);
    int wakeHour = self.startInMinutes / minutesPerHour;
    wakeHour = self.isAwakeAM ? wakeHour : (wakeHour + 12 > 23 ? wakeHour : wakeHour + 12);
    int wakeMinutes = fmod(self.startInMinutes, minutesPerHour);
    
    int diffHour = 0;
    
    if (wakeHour > sleepHour) {
        diffHour = wakeMinutes >= sleepMinutes ? wakeHour - sleepHour : wakeHour - sleepHour - 1;
    }else if (wakeHour < sleepHour) {
        diffHour = wakeMinutes >= sleepMinutes ? wakeHour + 24 - sleepHour : wakeHour + 24 - sleepHour - 1;
    }else if (wakeHour == sleepHour) {
        diffHour = wakeMinutes >= sleepMinutes ? 0 : 23;
    }
    
//    int hour = round(self.hourDifference);
    int minutes = round(self.minuteDifference);
//    NSString *sHour = self.hourDifference > 0 ? [NSString stringWithFormat:@"%dh", hour] : (self.minuteDifference > 0 ? @"" : @"24h");
    NSString *sMinutes = self.minuteDifference > 0 ? [NSString stringWithFormat:@"%dmin", minutes] : @"";
    return [NSString stringWithFormat:@"%dh%@", diffHour, sMinutes];
}

- (BOOL)equalPositionInCircle{
    return fmod(self.startPosition, degreesInCircle) == fmod(self.endPosition, degreesInCircle);
}

- (CGFloat)degress:(CGFloat)degress{
    return degress * 180 / M_PI;
}

- (CGFloat)radians:(CGFloat)value{
    return (value * M_PI) / 180;
}
@end
