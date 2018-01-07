//
//  OBADepartureRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBABaseRow.h>
#import <OBAKit/OBAUpcomingDeparture.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBADepartureRow : OBABaseRow

// abxoxo - next up, start using topLine and get rid of the one-off version in the bookmark controller!

@property(nonatomic,copy,nullable) NSAttributedString *topLine;
@property(nonatomic,copy,nullable) NSAttributedString *middleLine;
@property(nonatomic,copy,nullable) NSAttributedString *bottomLine;

@property(nonatomic,copy,nullable) NSArray<OBAUpcomingDeparture*> *upcomingDepartures;
@property(nonatomic,copy,nullable) void (^showAlertController)(UIView *presentingView);
@property(nonatomic,assign) BOOL bookmarkExists;
@property(nonatomic,assign) BOOL alarmExists;
@property(nonatomic,assign) BOOL hasArrived;

+ (NSAttributedString*)buildAttributedRoute:(NSString*)route destination:(nullable NSString*)destination;
@end

NS_ASSUME_NONNULL_END
