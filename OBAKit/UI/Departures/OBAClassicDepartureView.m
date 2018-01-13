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
#import <OBAKit/OBABookmarkedRouteRow.h>

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
        _topLineLabel.font = OBATheme.largeTitleFont;
        _topLineLabel.numberOfLines = 1;
        _topLineLabel.adjustsFontSizeToFitWidth = YES;
        _topLineLabel.minimumScaleFactor = 0.8f;
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
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(OBATheme.compactPadding, OBATheme.defaultPadding, OBATheme.compactPadding, OBATheme.defaultPadding));
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

    self.topLineLabel.attributedText = _departureRow.attributedTopLine;
    self.topLineLabel.hidden = self.topLineLabel.attributedText.length == 0;

    self.middleLineLabel.attributedText = _departureRow.attributedMiddleLine;
    self.middleLineLabel.hidden = self.middleLineLabel.attributedText.length == 0;

    self.bottomLineLabel.attributedText = _departureRow.attributedBottomLine;
    self.bottomLineLabel.hidden = self.bottomLineLabel.attributedText.length == 0;

    [self applyUpcomingDeparture:[self departureRow].upcomingDepartures atIndex:0 toLabel:self.leadingLabel];
    [self applyUpcomingDeparture:[self departureRow].upcomingDepartures atIndex:1 toLabel:self.centerLabel];
    [self applyUpcomingDeparture:[self departureRow].upcomingDepartures atIndex:2 toLabel:self.trailingLabel];

    if ([_departureRow isKindOfClass:OBABookmarkedRouteRow.class]) {
        [self loadStateFromBookmarkedRouteRow:(OBABookmarkedRouteRow*)_departureRow];
    }
}

- (void)loadStateFromBookmarkedRouteRow:(OBABookmarkedRouteRow*)bookmarkRow {
    if (bookmarkRow.state == OBABookmarkedRouteRowStateLoading) {

        return;
    }
//
//    if ([self tableDataRow].upcomingDepartures.count > 0) {
//        self.activityIndicatorView.hidden = YES;
//        [self.activityIndicatorView stopAnimating];
//    }
//    else if ([self tableDataRow].state == OBABookmarkedRouteRowStateLoading) {
//        [self.activityIndicatorView startAnimating];
//        self.activityIndicatorView.hidden = NO;
//    }
//    else { // error state.
//        self.activityIndicatorView.hidden = NO;
//        [self.activityIndicatorView stopAnimating];
//        self.activityIndicatorView.textLabel.text = [self tableDataRow].errorMessage;
//    }
}

- (void)applyUpcomingDeparture:(NSArray<OBAUpcomingDeparture*>*)upcomingDepartures atIndex:(NSUInteger)index toLabel:(OBADepartureTimeLabel*)departureTimeLabel {
    if (upcomingDepartures.count > index) {
        departureTimeLabel.hidden = NO;
        departureTimeLabel.upcomingDeparture = upcomingDepartures[index];
    }
    else {
        departureTimeLabel.hidden = YES;
    }
}

@end
