//
//  OBABookmarkedRouteCell.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBATableCell.h>
#import <OBAKit/OBAClassicDepartureView.h>
#import <OBAKit/OBALabelActivityIndicatorView.h>

@interface OBABookmarkedRouteCell : UITableViewCell<OBATableCell>
@property(nonatomic,strong,readonly) UILabel *titleLabel;
@property(nonatomic,strong,readonly) OBAClassicDepartureView *departureView;
@property(nonatomic,strong,readonly) OBALabelActivityIndicatorView *activityIndicatorView;
@end
