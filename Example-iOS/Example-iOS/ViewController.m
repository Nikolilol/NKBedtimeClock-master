//
//  ViewController.m
//  Example-iOS
//
//  Created by Niko on 2017/10/20.
//  Copyright © 2017年 Niko. All rights reserved.
//

//
//  ViewController.m
//  NKBedtimeClock
//
//  Created by Niko on 2017/10/16.
//  Copyright © 2017年 Niko. All rights reserved.
//

#import "ViewController.h"
#import "NKBedtimeClock.h"

@interface ViewController () <NKBedtimeClockDelegate>
@property (nonatomic, weak) UILabel *sleepValueLabel;
@property (nonatomic, weak) UILabel *wakeValueLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, height - width * 1.4, width, width)];
    [self.view addSubview:contentView];
    
    int sleepTime = 1320;
    int wakeTime = 360;
    NKBedtimeClock *bedtimeClock = [[NKBedtimeClock alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width) sleepTimeInMinutes:sleepTime wakeTimeInMinutes:wakeTime];
    bedtimeClock.delegate = self;
    [contentView addSubview:bedtimeClock];
    
    NSString *sleepValue = [NSString stringWithFormat:@"%02d:%02d", sleepTime / 60, fmod(sleepTime, 60)];
    NSString *wakeValue = [NSString stringWithFormat:@"%02d:%02d", wakeTime / 60, fmod(wakeTime, 60)];
    
    UILabel *sleepLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 160, 20)];
    sleepLabel.text = @"SleepTime:";
    sleepLabel.textColor = [UIColor whiteColor];
    sleepLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:sleepLabel];
    
    UILabel *sleepValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40 + 30, 160, 20)];
    sleepValueLabel.text = sleepValue;
    sleepValueLabel.textColor = [UIColor whiteColor];
    sleepValueLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:sleepValueLabel];
    _sleepValueLabel = sleepValueLabel;
    
    UILabel *wakeLabel = [[UILabel alloc] initWithFrame:CGRectMake((width - 20) * 0.5, 40, 160, 20)];
    wakeLabel.text = @"WakeTime:";
    wakeLabel.textColor = [UIColor whiteColor];
    wakeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:wakeLabel];
    
    UILabel *wakeValueLabel = [[UILabel alloc] initWithFrame:CGRectMake((width - 20) * 0.5, 40 + 30, 160, 20)];
    wakeValueLabel.text = wakeValue;
    wakeValueLabel.textColor = [UIColor whiteColor];
    wakeValueLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:wakeValueLabel];
    _wakeValueLabel = wakeValueLabel;
}

- (void)NKBedtimeClock:(NKBedtimeClock *)bedtimeClock didUpdateSleepTime:(NSString *)sleepTime wakeTime:(NSString *)wakeTime sleepDuration:(NSString *)sleepDuration{
    
    _sleepValueLabel.text = sleepTime;
    _wakeValueLabel.text = wakeTime;
    
    NSLog(@"didUpdateSleepTime:%@, wakeTime:%@, sleepDuration:%@", sleepTime, wakeTime, sleepDuration);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

