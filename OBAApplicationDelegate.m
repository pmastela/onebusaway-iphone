/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <SystemConfiguration/SystemConfiguration.h>
#import <OBAKit/OBAModelDAOUserPreferencesImpl.h>
#import "OBAApplicationDelegate.h"
#import "OBANavigationTargetAware.h"
#import "OBALogger.h"

#import "OBASearchController.h"
#import "OBAStopViewController.h"

#import "OBARegionListViewController.h"
#import "OBARegionHelper.h"

#import "OBAAnalytics.h"
#import "NSArray+OBAAdditions.h"
#import <Apptentive/Apptentive.h>

#import "OBAApplicationUI.h"

static NSString *kOBAShowExperimentalRegionsDefaultsKey = @"kOBAShowExperimentalRegionsDefaultsKey";
static NSString *const kTrackingId = @"UA-2423527-17";
static NSString *const kOptOutOfTracking = @"OptOutOfTracking";

static NSString *const kApptentiveKey = @"3363af9a6661c98dec30fedea451a06dd7d7bc9f70ef38378a9d5a15ac7d4926";

@interface OBAApplicationDelegate () <OBABackgroundTaskExecutor>
@property (nonatomic, strong) UINavigationController *regionNavigationController;
@property (nonatomic, strong) OBARegionListViewController *regionListViewController;
@property (nonatomic, readwrite) BOOL active;
@property (nonatomic, strong) OBARegionHelper *regionHelper;
@property (nonatomic, strong) id regionObserver;
@property (nonatomic, strong) id recentStopsObserver;
@property(nonatomic,strong) OBAApplicationUI *applicationUI;
@end

@implementation OBAApplicationDelegate

- (id)init {
    self = [super init];

    if (self) {
        _active = NO;
        _regionHelper = [[OBARegionHelper alloc] init];

        @weakify(self);
        self.regionObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kOBAApplicationSettingsRegionRefreshNotification
                                                                                object:nil
                                                                                 queue:[NSOperationQueue mainQueue]
                                                                            usingBlock:^(NSNotification *note) {
                                                                                @strongify(self);
                                                                                [self writeSetRegionAutomatically:YES];
                                                                                [self.regionHelper updateNearestRegion];
                                                                            }];
        self.recentStopsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:OBAMostRecentStopsChangedNotification
                                                                                     object:nil
                                                                                      queue:[NSOperationQueue mainQueue]
                                                                                 usingBlock:^(NSNotification *note) {
                                                                                     @strongify(self);
                                                                                     [self updateShortcutItemsForRecentStops];
                                                                                 }];
        
        [[OBAApplication sharedApplication] start];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.regionObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.recentStopsObserver];
}

- (void)writeSetRegionAutomatically:(BOOL)setRegionAutomatically {
    [[OBAApplication sharedApplication].modelDao writeSetRegionAutomatically:setRegionAutomatically];

    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:2] value:OBAStringFromBool(setRegionAutomatically)];
}

- (BOOL)readSetRegionAutomatically {
    BOOL readSetRegionAuto = [OBAApplication sharedApplication].modelDao.readSetRegionAutomatically;

    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:2] value:OBAStringFromBool(readSetRegionAuto)];
    return readSetRegionAuto;
}

- (void)navigateToTarget:(OBANavigationTarget *)navigationTarget {
    [self performSelector:@selector(_navigateToTargetInternal:) withObject:navigationTarget afterDelay:0];
}

- (void)_constructUI {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];

    self.applicationUI = [[OBAApplicationUI alloc] init];

    [self.applicationUI updateSelectedTabIndex];

    [OBATheme setAppearanceProxies];

    self.window.rootViewController = self.applicationUI.rootViewController;

    if ([[OBAApplication sharedApplication].modelDao.readCustomApiUrl isEqualToString:@""]) {
        if ([OBAApplication sharedApplication].modelDao.readSetRegionAutomatically && [OBAApplication sharedApplication].locationManager.locationServicesEnabled) {
            [self.regionHelper updateNearestRegion];
        }
        else {
            [self.regionHelper updateRegion];
        }
    }

    [self.window makeKeyAndVisible];
}

#pragma mark - UIApplication Methods

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    return [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:handler];
}

- (UIBackgroundTaskIdentifier)endBackgroundTask:(UIBackgroundTaskIdentifier)task {
    [[UIApplication sharedApplication] endBackgroundTask:task];
    return UIBackgroundTaskInvalid;
}

#pragma mark UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Register a background handler with the model service
    [OBAModelService addBackgroundExecutor:self];

    // Configure the Apptentive feedback system
    [Apptentive sharedConnection].APIKey = kApptentiveKey;

    // Set up Google Analytics
    NSDictionary *appDefaults = @{ kOptOutOfTracking: @(NO), kSetRegionAutomaticallyKey: @(YES)};
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];

    // User must be able to opt out of tracking
    [GAI sharedInstance].optOut = ![[NSUserDefaults standardUserDefaults] boolForKey:kOptOutOfTracking];

    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelWarning];

    //don't report to Google Analytics when developing
#ifdef DEBUG
    [[GAI sharedInstance] setDryRun:YES];
#endif

    self.tracker = [[GAI sharedInstance] trackerWithTrackingId:kTrackingId];

    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:1] value:[OBAApplication sharedApplication].modelDao.region.regionName];

    [OBAAnalytics configureVoiceOverStatus];

    [self _constructUI];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    CLLocation *location = [OBAApplication sharedApplication].locationManager.currentLocation;

    if (location) {
        [OBAApplication sharedApplication].modelDao.mostRecentLocation = location;
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.active = YES;

    [self.applicationUI applicationDidBecomeActive];

    [GAI sharedInstance].optOut = [[NSUserDefaults standardUserDefaults] boolForKey:kOptOutOfTracking];

    NSString *label = nil;
    if ([[OBAApplication sharedApplication].modelDao.readCustomApiUrl isEqualToString:@""]) {
        label = [NSString stringWithFormat:@"API Region: %@", [OBAApplication sharedApplication].modelDao.region.regionName];
    }
    else {
        label = @"API Region: Custom URL";
    }
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"configured_region" label:label value:nil];

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"general" label:[NSString stringWithFormat:@"Set Region Automatically: %@", OBAStringFromBool([OBAApplication sharedApplication].modelDao.readSetRegionAutomatically)] value:nil];

    BOOL _showExperimentalRegions = NO;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"kOBAShowExperimentalRegionsDefaultsKey"]) {
        _showExperimentalRegions = [[NSUserDefaults standardUserDefaults] boolForKey:@"kOBAShowExperimentalRegionsDefaultsKey"];
    }

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"general" label:[NSString stringWithFormat:@"Show Experimental Regions: %@", OBAStringFromBool(_showExperimentalRegions)] value:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    self.active = NO;
}

#pragma mark Shortcut Items

- (void)application:(UIApplication *)application performActionForShortcutItem:(nonnull UIApplicationShortcutItem *)shortcutItem completionHandler:(nonnull void (^)(BOOL))completionHandler {

    [self.applicationUI performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler];
}

- (void)updateShortcutItemsForRecentStops {
    NSMutableArray *dynamicShortcuts = [NSMutableArray array];
    UIApplicationShortcutIcon *clockIcon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeTime];

    for (OBAStopAccessEventV2 *stopEvent in [OBAApplication sharedApplication].modelDao.mostRecentStops) {
        UIApplicationShortcutItem *shortcutItem =
                [[UIApplicationShortcutItem alloc] initWithType:kApplicationShortcutRecents
                                                 localizedTitle:stopEvent.title
                                              localizedSubtitle:nil
                                                           icon:clockIcon
                                                       userInfo:@{ @"stopIds": stopEvent.stopIds }];
        [dynamicShortcuts addObject:shortcutItem];
    }

    [UIApplication sharedApplication].shortcutItems = [dynamicShortcuts oba_pickFirst:4];
}

- (void)_navigateToTargetInternal:(OBANavigationTarget *)navigationTarget {
    [[OBAApplication sharedApplication].references clear];

    [self.applicationUI navigateToTargetInternal:navigationTarget];
}

- (void)regionSelected {
    [_regionNavigationController removeFromParentViewController];
    _regionNavigationController = nil;
    _regionListViewController = nil;

    [[OBAApplication sharedApplication] refreshSettings];

    self.window.rootViewController = self.applicationUI.rootViewController;
    [self.window makeKeyAndVisible];
}

- (void)showRegionListViewController {
    _regionListViewController = [[OBARegionListViewController alloc] init];
    _regionNavigationController = [[UINavigationController alloc] initWithRootViewController:_regionListViewController];

    self.window.rootViewController = _regionNavigationController;
}

@end
