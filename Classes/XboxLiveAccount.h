//
//  XboxLiveAccountPreferences.h
//  BachZero
//
//  Created by Akop Karapetyan on 11/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XboxLiveAccount : NSObject

-(id)initWithUuid:(NSString*)uuid;
+(id)preferencesForUuid:(NSString*)uuid;

-(void)refresh;
-(void)save;
-(void)purge;

-(NSString*)uuid;

-(NSDate*)lastGamesUpdate;
-(void)setLastGamesUpdate:(NSDate*)lastUpdate;

-(NSNumber*)browseRefreshPeriodInSeconds;
-(void)setBrowseRefreshPeriodInSeconds:(NSNumber*)browseRefreshPeriodInSeconds;

-(NSString*)emailAddress;
-(void)setEmailAddress:(NSString*)emailAddress;

-(NSString*)password;
-(void)setPassword:(NSString*)password;

-(BOOL)isEqualToAccount:(XboxLiveAccount*)account;

-(BOOL)areGamesStale;

@end