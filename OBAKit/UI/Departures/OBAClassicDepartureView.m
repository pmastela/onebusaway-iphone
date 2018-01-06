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
@property(nonatomic,strong) UILabel *topLineLabel;
@property(nonatomic,strong) UILabel *middleLineLabel;
@property(nonatomic,strong) UILabel *bottomLineLabel;

@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *leadingLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *centerLabel;
@property(nonatomic,strong,readwrite) OBADepartureTimeLabel *trailingLabel;

@end

@implementation OBAClassicDepartureView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.clipsToBounds = YES;

        _topLineLabel = [[UILabel alloc] init];
        _topLineLabel.numberOfLines = 0;
        [_topLineLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_topLineLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_topLineLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

        _middleLineLabel = [[UILabel alloc] init];
        _middleLineLabel.numberOfLines = 0;
        [_middleLineLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_middleLineLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_middleLineLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

        _bottomLineLabel = [[UILabel alloc] init];
        _bottomLineLabel.numberOfLines = 0;
        [_bottomLineLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_bottomLineLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_bottomLineLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

        _leadingLabel = [[OBADepartureTimeLabel alloc] init];
        [_leadingLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _centerLabel = [[OBADepartureTimeLabel alloc] init];
        [_centerLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _trailingLabel = [[OBADepartureTimeLabel alloc] init];
        [_trailingLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _contextMenuButton = [OBAUIBuilder contextMenuButton];

        if (kUseDebugColors) {
            self.backgroundColor = [UIColor purpleColor];
            _topLineLabel.backgroundColor = [UIColor redColor];
            _middleLineLabel.backgroundColor = [UIColor greenColor];
            _bottomLineLabel.backgroundColor = [UIColor blueColor];

            _leadingLabel.backgroundColor = [UIColor magentaColor];
            _centerLabel.backgroundColor = [UIColor blueColor];
            _trailingLabel.backgroundColor = [UIColor greenColor];

            _contextMenuButton.backgroundColor = [UIColor yellowColor];
        }

        UIStackView *labelStack = [[UIStackView alloc] initWithArrangedSubviews:@[_topLineLabel, _middleLineLabel, _bottomLineLabel]];
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
    self.topLineLabel.text = nil;
    self.middleLineLabel.text = nil;
    self.bottomLineLabel.text = nil;
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
        self.middleLineLabel.text = [NSString stringWithFormat:OBALocalized(@"text_route_to_orientation_newline_params", @"Route formatting string. e.g. 10 to Downtown Seattle"), [self departureRow].routeName, [self departureRow].destination];
    }
    else {
        self.middleLineLabel.text = [self departureRow].routeName;
    }

    NSMutableAttributedString *routeText = [[NSMutableAttributedString alloc] initWithString:self.middleLineLabel.text attributes:@{NSFontAttributeName: kBodyFont}];

    [routeText addAttribute:NSFontAttributeName value:kBoldBodyFont range:NSMakeRange(0, [self departureRow].routeName.length)];
    self.middleLineLabel.attributedText = routeText;
}

- (void)renderDepartureTimeLabel {
    OBAUpcomingDeparture *upcoming = [self departureRow].upcomingDepartures.firstObject;
    NSAttributedString *departureTime = [OBADepartureCellHelpers attributedDepartureTimeWithStatusText:[self departureRow].statusText upcomingDeparture:upcoming];

    self.bottomLineLabel.attributedText = departureTime;
}

@end
