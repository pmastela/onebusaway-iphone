//
//  OBAClassicDepartureView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/26/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAClassicDepartureView.h>
@import Masonry;
#import <OBAKit/OBAAnimation.h>
#import <OBAKit/OBADepartureTimeLabel.h>
#import <OBAKit/OBAUIBuilder.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/OBADateHelpers.h>
#import <OBAKit/OBADepartureCellHelpers.h>
#import <OBAKit/OBAMacros.h>

#define kUseDebugColors NO
#define kBodyFont OBATheme.bodyFont
#define kBoldBodyFont OBATheme.boldBodyFont
#define kSmallFont OBATheme.subheadFont

@interface OBAClassicDepartureView ()
@property(nonatomic,strong,readwrite) UIButton *contextMenuButton;
@property(nonatomic,strong) UILabel *routeLabel;
@property(nonatomic,strong) UILabel *departureTimeLabel;

@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *leadingLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *centerLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *trailingLabel;

@end

@implementation OBAClassicDepartureView

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithLabelAlignment:OBAClassicDepartureViewLabelAlignmentCenter];
}

- (instancetype)initWithLabelAlignment:(OBAClassicDepartureViewLabelAlignment)labelAlignment {
    self = [super initWithFrame:CGRectZero];

    if (self) {
        self.clipsToBounds = YES;

        _labelAlignment = OBAClassicDepartureViewLabelAlignmentCenter;

        _routeLabel = [[UILabel alloc] init];
        _routeLabel.numberOfLines = 0;
        [_routeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_routeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_routeLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

        _departureTimeLabel = [[UILabel alloc] init];
        _departureTimeLabel.numberOfLines = 0;
        [_departureTimeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_departureTimeLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_departureTimeLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

        _leadingLabel = [[OBADepartureTimeLabel alloc] init];
        [_leadingLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _centerLabel = [[OBADepartureTimeLabel alloc] init];
        [_centerLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _trailingLabel = [[OBADepartureTimeLabel alloc] init];
        [_trailingLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _contextMenuButton = [OBAUIBuilder contextMenuButton];

        if (kUseDebugColors) {
            self.backgroundColor = [UIColor purpleColor];
            _routeLabel.backgroundColor = [UIColor greenColor];
            _departureTimeLabel.backgroundColor = [UIColor blueColor];

            _leadingLabel.backgroundColor = [UIColor magentaColor];
            _centerLabel.backgroundColor = [UIColor blueColor];
            _trailingLabel.backgroundColor = [UIColor greenColor];

            _contextMenuButton.backgroundColor = [UIColor yellowColor];
        }

        UIStackView *labelStack = [[UIStackView alloc] initWithArrangedSubviews:@[_routeLabel, _departureTimeLabel]];
        labelStack.axis = UILayoutConstraintAxisVertical;
        labelStack.distribution = UIStackViewDistributionFill;
        labelStack.spacing = 0;

        UIStackView *horizontalStack = ({
            UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[labelStack, _leadingLabel, _centerLabel, _trailingLabel, _contextMenuButton]];
            stack.axis = UILayoutConstraintAxisHorizontal;
            stack.distribution = UIStackViewDistributionFill;
            stack.spacing = OBATheme.compactPadding;
            stack;
        });
        [self addSubview:horizontalStack];

        [horizontalStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        [_contextMenuButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@40);
            make.height.greaterThanOrEqualTo(@40);
        }];
    }
    return self;
}

#pragma mark - Reuse

- (void)prepareForReuse {
    self.routeLabel.text = nil;
    self.departureTimeLabel.text = nil;
    [self.leadingLabel prepareForReuse];
    [self.centerLabel prepareForReuse];
    [self.trailingLabel prepareForReuse];
}

#pragma mark - Row Logic

- (void)setDepartureRow:(OBADepartureRow *)departureRow {
    if (_departureRow == departureRow) {
        return;
    }

    _departureRow = [departureRow copy];

    [self renderRouteLabel];
    [self renderDepartureTimeLabel];

    if ([self departureRow].upcomingDepartures.count > 0) {
        self.leadingLabel.hidden = NO;
        self.leadingLabel.upcomingDeparture = [self departureRow].upcomingDepartures[0];
    }
    else {
        self.leadingLabel.hidden = YES;
    }

    if ([self departureRow].upcomingDepartures.count > 1) {
        self.centerLabel.hidden = NO;
        self.centerLabel.upcomingDeparture = [self departureRow].upcomingDepartures[1];
    }
    else {
        self.centerLabel.hidden = YES;
    }

    if ([self departureRow].upcomingDepartures.count > 2) {
        self.trailingLabel.hidden = NO;
        self.trailingLabel.upcomingDeparture = [self departureRow].upcomingDepartures[2];
    }
    else {
        self.trailingLabel.hidden = YES;
    }
}

#pragma mark - Label Logic

- (void)renderRouteLabel {
    if ([self departureRow].destination) {
        self.routeLabel.text = [NSString stringWithFormat:OBALocalized(@"text_route_to_orientation_newline_params", @"Route formatting string. e.g. 10 to Downtown Seattle"), [self departureRow].routeName, [self departureRow].destination];
    }
    else {
        self.routeLabel.text = [self departureRow].routeName;
    }

    NSMutableAttributedString *routeText = [[NSMutableAttributedString alloc] initWithString:self.routeLabel.text attributes:@{NSFontAttributeName: kBodyFont}];

    [routeText addAttribute:NSFontAttributeName value:kBoldBodyFont range:NSMakeRange(0, [self departureRow].routeName.length)];
    self.routeLabel.attributedText = routeText;
}

- (void)renderDepartureTimeLabel {
    OBAUpcomingDeparture *upcoming = [self departureRow].upcomingDepartures.firstObject;
    NSAttributedString *departureTime = [OBADepartureCellHelpers attributedDepartureTimeWithStatusText:[self departureRow].statusText upcomingDeparture:upcoming];

    self.departureTimeLabel.attributedText = departureTime;
}

@end
