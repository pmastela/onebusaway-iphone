//
//  OBABookmarkedRouteCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABookmarkedRouteCell.h>
#import <OBAKit/OBABookmarkedRouteRow.h>
#import <OBAKit/OBALabelActivityIndicatorView.h>
#import <OBAKit/OBAClassicDepartureView.h>
#import <OBAKit/OBATableRow.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/OBAUIBuilder.h>
#import <OBAKit/OBAMacros.h>

@import Masonry;

@interface OBABookmarkedRouteCell ()
@property(nonatomic,strong,readwrite) OBAClassicDepartureView *departureView;
@property(nonatomic,strong,readwrite) OBALabelActivityIndicatorView *activityIndicatorView;
@end

@implementation OBABookmarkedRouteCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.contentView.clipsToBounds = YES;
        self.contentView.frame = self.bounds;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

        _departureView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
        _departureView.contextMenuButton.hidden = YES;
        [self.contentView addSubview:_departureView];

        _activityIndicatorView = [[OBALabelActivityIndicatorView alloc] initWithFrame:CGRectZero];
        _activityIndicatorView.hidden = YES;
        [self.contentView addSubview:_activityIndicatorView];

        [self setupConstraints];
    }
    return self;
}

- (void)setupConstraints {
    void (^constraintBlock)(MASConstraintMaker *make) = ^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).priorityMedium();
        make.height.greaterThanOrEqualTo(@40).priorityHigh();
    };

    [self.departureView mas_makeConstraints:constraintBlock];
    [self.activityIndicatorView mas_makeConstraints:constraintBlock];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self.departureView prepareForReuse];

    [self.activityIndicatorView prepareForReuse];
}

- (void)setTableRow:(OBATableRow *)tableRow {
    OBAGuardClass(tableRow, OBABookmarkedRouteRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    if ([self tableDataRow].upcomingDepartures.count > 0) {
        self.activityIndicatorView.hidden = YES;
        [self.activityIndicatorView stopAnimating];
        self.departureView.departureRow = [self tableDataRow];
    }
    else if ([self tableDataRow].state == OBABookmarkedRouteRowStateLoading) {
        [self.activityIndicatorView startAnimating];
        self.activityIndicatorView.hidden = NO;
    }
    else { // error state.
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView stopAnimating];
        self.activityIndicatorView.textLabel.text = [self tableDataRow].errorMessage;
    }
}

- (OBABookmarkedRouteRow*)tableDataRow {
    return (OBABookmarkedRouteRow*)self.tableRow;
}

@end
