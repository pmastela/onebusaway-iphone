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

#import "OBAArrivalsAndDeparturesForStop.h"


@interface OBAModelFactory : NSObject {
	NSManagedObjectContext * _context;
	NSMutableDictionary * _entityIdMappings;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (NSArray*) getStopsFromJSONArray:(NSArray*)jsonArray error:(NSError**)error;
- (NSArray*) getRoutesFromJSONArray:(NSArray*)jsonArray error:(NSError**)error;
- (NSArray*) getPlacemarksFromJSONObject:(id)jsonObject error:(NSError**)error;
- (NSArray*) getAgenciesWithCoverageFromJson:(id)jsonArray error:(NSError**)error;

- (OBAArrivalsAndDeparturesForStop*) getArrivalsAndDeparturesForStopFromJSON:(NSDictionary*)jsonDictionary error:(NSError**)error;

@end
