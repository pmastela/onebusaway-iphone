//
//  OBACompactRouteBookmarkCell.m
//  OBAKit
//
//  Created by Aaron Brethorst on 12/30/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <OBAKit/OBACompactRouteBookmarkCell.h>
#import <OBAKit/OBABookmarkedRouteRow.h>
#import <OBAKit/OBAMacros.h>
@import Masonry;

@interface OBACompactRouteBookmarkCell ()
@property(nonatomic,copy,readonly) OBABookmarkedRouteRow* bookmarkedRouteRow;
@end

@implementation OBACompactRouteBookmarkCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        [self.titleLabel removeFromSuperview];
    }

    return self;
}

- (void)setupConstraints {
    void (^constraintBlock)(MASConstraintMaker *make) = ^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(self.layoutMargins);
        make.height.greaterThanOrEqualTo(@40);
    };

    [self.departureView mas_makeConstraints:constraintBlock];
    [self.activityIndicatorView mas_makeConstraints:constraintBlock];

}

#pragma mark - OBATableCell

- (OBABookmarkedRouteRow*)bookmarkedRouteRow {
    return (OBABookmarkedRouteRow*)self.tableRow;
}

@end
