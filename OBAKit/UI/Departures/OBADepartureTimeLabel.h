//
//  OBADepartureTimeLabel.h
//  org.onebusaway.iphone
//
//  Created by Chad Royal on 9/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBAUpcomingDeparture.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBADepartureTimeLabel : UIView
@property(nonatomic,copy) OBAUpcomingDeparture *upcomingDeparture;
- (void)prepareForReuse;

@end

NS_ASSUME_NONNULL_END
