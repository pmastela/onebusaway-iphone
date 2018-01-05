//
//  UIFont+OBAAdditions.m
//  OBAKit
//
//  Created by Aaron Brethorst on 12/30/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <OBAKit/UIFont+OBAAdditions.h>
@import CoreText;

@implementation UIFont (OBAAdditions)

- (UIFont*)oba_fontWithSmallCaps {
    /*
     // Use this to log all of the properties for a particular font
     UIFont *font = [UIFont fontWithName: fontName size: fontSize];
     CFArrayRef  fontProperties  =  CTFontCopyFeatures ( ( __bridge CTFontRef ) font ) ;
     NSLog(@"properties = %@", fontProperties);
     */

    NSArray *fontFeatureSettings = @[@{  UIFontFeatureTypeIdentifierKey: @(kLowerCaseType),
                                         UIFontFeatureSelectorIdentifierKey: @(kLowerCaseSmallCapsSelector) }];

    NSDictionary *fontAttributes = @{ UIFontDescriptorFeatureSettingsAttribute: fontFeatureSettings,
                                      UIFontDescriptorNameAttribute: self.fontDescriptor.postscriptName};

    UIFontDescriptor *fontDescriptor = [[UIFontDescriptor alloc] initWithFontAttributes:fontAttributes];
    return [UIFont fontWithDescriptor:fontDescriptor size:self.pointSize];
}

@end
