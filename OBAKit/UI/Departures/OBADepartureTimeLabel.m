//
//  OBADepartureTimeLabel.m
//  org.onebusaway.iphone
//
//  Created by Chad Royal on 9/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBADepartureTimeLabel.h>
#import <OBAKit/OBAAnimation.h>
#import <OBAKit/OBADepartureCellHelpers.h>
#import <OBAKit/OBADepartureStatus.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/UIFont+OBAAdditions.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBADateHelpers.h>
#import <OBAKit/NSDate+DateTools.h>
@import Masonry;

#define kDebugColors NO

@interface OBADepartureTimeLabel ()
@property(nonatomic,copy) NSDate *departureDate;
@property(nonatomic,strong) UILabel *minutesLabel;
@property(nonatomic,strong) UILabel *abbrLabel;
@property(nonatomic,strong) UIStackView *stackView;
@property(nonatomic,copy) NSString *previousMinutesText;
@property(nonatomic,copy) UIColor *previousMinutesColor;
@property(nonatomic,assign) BOOL firstRenderPass;
@end

@implementation OBADepartureTimeLabel

- (instancetype)init {
    self = [super init];

    if (self) {
        self.backgroundColor = UIColor.clearColor;

        _minutesLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _minutesLabel.font = OBATheme.subtitleFont;
        _minutesLabel.textAlignment = NSTextAlignmentCenter;
        [_minutesLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_minutesLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_minutesLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

        _abbrLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _abbrLabel.hidden = YES;
        _abbrLabel.font = OBATheme.footnoteFont.oba_fontWithSmallCaps;
        _abbrLabel.text = OBALocalized(@"departure_time_label.minutes_abbreviation", @"No more than 3 character abbreviation for minutes. In English: min.");
        _abbrLabel.textAlignment = NSTextAlignmentCenter;
        [_abbrLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_abbrLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];

        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_minutesLabel, _abbrLabel]];
        _stackView.axis = UILayoutConstraintAxisVertical;
        _stackView.spacing = 0;
        [self addSubview:_stackView];

        [_stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.equalTo(self);
            make.centerY.equalTo(self);
        }];

        _firstRenderPass = YES;

        if (kDebugColors) {
            _minutesLabel.backgroundColor = [UIColor greenColor];
            _abbrLabel.backgroundColor = [UIColor redColor];
        }
    }

    return self;
}

- (void)prepareForReuse {
    self.minutesLabel.text = nil;
    self.abbrLabel.hidden = YES;
}

#pragma mark - Departure Date

- (void)setUpcomingDeparture:(OBAUpcomingDeparture *)upcomingDeparture {
    _upcomingDeparture = [upcomingDeparture copy];

    self.accessibilityLabel = [OBADateHelpers formatAccessibilityLabelMinutesUntilDate:upcomingDeparture.departureDate];

    double minutesFrom = fabs([upcomingDeparture.departureDate minutesFrom:[NSDate date]]);
    BOOL isNow = minutesFrom < 1.0;
    NSString *minutesText = isNow ? OBALocalized(@"msg_now", @"e.g. 'NOW'. As in right now, with emphasis.") : [NSString stringWithFormat:@"%.0f", minutesFrom];

    self.abbrLabel.hidden = isNow;

    [self setText:minutesText forStatus:upcomingDeparture.departureStatus];
}

#pragma mark - Label Logic

- (void)setText:(NSString *)minutesUntilDeparture forStatus:(OBADepartureStatus)status {
    UIColor *backgroundColor = [OBADepartureCellHelpers colorForStatus:status];

    BOOL textChanged = ![minutesUntilDeparture isEqual:self.previousMinutesText];
    BOOL colorChanged = ![backgroundColor isEqual:self.previousMinutesColor];

    self.previousMinutesText = minutesUntilDeparture;
    self.minutesLabel.text = minutesUntilDeparture;

    self.previousMinutesColor = backgroundColor;
    self.minutesLabel.textColor = backgroundColor;
    self.abbrLabel.textColor = backgroundColor;

    // don't animate the first rendering of the cell.
    if (self.firstRenderPass) {
        self.firstRenderPass = NO;
        return;
    }

    if (textChanged || colorChanged) {
        self.layer.backgroundColor = [OBATheme propertyChangedColor].CGColor;

        [UIView animateWithDuration:OBALongAnimationDuration animations:^{
            self.layer.backgroundColor = [UIColor whiteColor].CGColor;
        }];
    }
}

@end
