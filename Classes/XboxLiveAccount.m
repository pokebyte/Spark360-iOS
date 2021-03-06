/*
 * Spark 360 for iOS
 * https://github.com/pokebyte/Spark360-iOS
 *
 * Copyright (C) 2011-2014 Akop Karapetyan
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
 *  02111-1307  USA.
 *
 */

#import "XboxLiveAccount.h"
#import "KeychainItemWrapper.h"
#import "XboxLiveParser.h"
#import "TaskController.h"

@interface XboxLiveAccount (Private)

-(NSString*)keyForPreference:(NSString*)preference;
-(void)resetDirtyFlags;

@end

@implementation XboxLiveAccount
{
    NSString *_uuid;
    NSDate *_lastProfileUpdate;
    BOOL _lastProfileUpdateDirty;
    NSDate *_lastGamesUpdate;
    BOOL _lastGamesUpdateDirty;
    NSDate *_lastMessagesUpdate;
    BOOL _lastMessagesUpdateDirty;
    NSDate *_lastFriendsUpdate;
    BOOL _lastFriendsUpdateDirty;
    NSNumber *_stalePeriodInSeconds;
    BOOL _browseRefreshPeriodInSecondsDirty;
    NSString *_emailAddress;
    BOOL _emailAddressDirty;
    NSString *_password;
    BOOL _passwordDirty;
    NSString *_screenName;
    BOOL _screenNameDirty;
    NSInteger _accountTier;
    BOOL _accountTierDirty;
}

NSString * const KeychainPassword = @"com.akop.bach";

NSString * const StalePeriodKey = @"StalePeriod";
NSString * const ScreenNameKey = @"ScreenName";
NSString * const GameLastUpdatedKey = @"GamesLastUpdated";
NSString * const ProfileLastUpdatedKey = @"ProfileLastUpdated";
NSString * const MessagesLastUpdatedKey = @"MessagesLastUpdated";
NSString * const FriendsLastUpdatedKey = @"FriendsLastUpdated";
NSString * const AccountTierKey = @"AccountTier";
NSString * const CookiesKey = @"Cookies";

#ifdef DEBUG
#define DEFAULT_BROWSING_REFRESH_TIMEOUT_SECONDS (60*30) // 30 Minutes
#else
#define DEFAULT_BROWSING_REFRESH_TIMEOUT_SECONDS (60*5) // 5 Minutes
#endif

-(NSString*)uuid
{
    return _uuid;
}

-(void)reload
{
    if (self.uuid)
    {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        // Load pref-based properties
        self.lastGamesUpdate = [prefs objectForKey:[self keyForPreference:GameLastUpdatedKey]];
        self.lastMessagesUpdate = [prefs objectForKey:[self keyForPreference:MessagesLastUpdatedKey]];
        self.lastFriendsUpdate = [prefs objectForKey:[self keyForPreference:FriendsLastUpdatedKey]];
        self.lastProfileUpdate = [prefs objectForKey:[self keyForPreference:ProfileLastUpdatedKey]];
        self.stalePeriodInSeconds = [prefs objectForKey:[self keyForPreference:StalePeriodKey]];
        self.screenName = [prefs objectForKey:[self keyForPreference:ScreenNameKey]];
        self.accountTier = [[prefs objectForKey:[self keyForPreference:AccountTierKey]] integerValue];
        
        // Load Secure properties
        KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:self.uuid
                                                                                serviceName:KeychainPassword
                                                                                accessGroup:nil];
        self.emailAddress = [keychainItem objectForKey:kSecAttrAccount];
        self.password = [keychainItem objectForKey:kSecValueData];
        [keychainItem release];
        
        // Mark the properties 'clean'
        [self resetDirtyFlags];
        
        // Set defaults
        if (!self.stalePeriodInSeconds)
            self.stalePeriodInSeconds = [NSNumber numberWithInt:DEFAULT_BROWSING_REFRESH_TIMEOUT_SECONDS];
        if (!self.lastGamesUpdate)
            self.lastGamesUpdate = [NSDate distantPast];
        if (!self.lastMessagesUpdate)
            self.lastMessagesUpdate = [NSDate distantPast];
        if (!self.lastFriendsUpdate)
            self.lastFriendsUpdate = [NSDate distantPast];
        if (!self.lastProfileUpdate)
            self.lastProfileUpdate = [NSDate distantPast];
    }
}

-(void)purge
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs removeObjectForKey:[self keyForPreference:GameLastUpdatedKey]];
    [prefs removeObjectForKey:[self keyForPreference:MessagesLastUpdatedKey]];
    [prefs removeObjectForKey:[self keyForPreference:FriendsLastUpdatedKey]];
    [prefs removeObjectForKey:[self keyForPreference:StalePeriodKey]];
    [prefs removeObjectForKey:[self keyForPreference:ScreenNameKey]];
    [prefs removeObjectForKey:[self keyForPreference:AccountTierKey]];
    [prefs removeObjectForKey:[self keyForPreference:ProfileLastUpdatedKey]];
    
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:self.uuid
                                                                            serviceName:KeychainPassword
                                                                            accessGroup:nil];
    [keychainItem resetKeychainItem];
    [keychainItem release];
}

-(void)save
{
    if (self.uuid)
    {
        @synchronized([self class])
        {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            
            if (_lastProfileUpdateDirty)
            {
                [prefs setObject:self.lastProfileUpdate
                          forKey:[self keyForPreference:ProfileLastUpdatedKey]];
            }
            
            if (_lastGamesUpdateDirty)
            {
                [prefs setObject:self.lastGamesUpdate 
                          forKey:[self keyForPreference:GameLastUpdatedKey]];
            }
            
            if (_lastMessagesUpdateDirty)
            {
                [prefs setObject:self.lastMessagesUpdate 
                          forKey:[self keyForPreference:MessagesLastUpdatedKey]];
            }
            
            if (_lastFriendsUpdateDirty)
            {
                [prefs setObject:self.lastFriendsUpdate 
                          forKey:[self keyForPreference:FriendsLastUpdatedKey]];
            }
            
            if (_accountTierDirty)
            {
                [prefs setObject:[NSNumber numberWithInteger:self.accountTier]
                          forKey:[self keyForPreference:AccountTierKey]];
            }
            
            if (_browseRefreshPeriodInSecondsDirty)
            {
                [prefs setObject:self.stalePeriodInSeconds 
                          forKey:[self keyForPreference:StalePeriodKey]];
            }
            
            if (_screenNameDirty)
            {
                [prefs setObject:self.screenName 
                          forKey:[self keyForPreference:ScreenNameKey]];
            }
            
            if (_emailAddressDirty || _passwordDirty)
            {
                KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:self.uuid
                                                                                        serviceName:KeychainPassword
                                                                                        accessGroup:nil];
                [keychainItem setObject:self.emailAddress forKey:kSecAttrAccount];
                [keychainItem setObject:self.password forKey:kSecValueData];
                [keychainItem release];
            }
            
            [self resetDirtyFlags];
        }
    }
}

-(void)resetDirtyFlags
{
    _lastGamesUpdateDirty = NO;
    _lastMessagesUpdateDirty = NO;
    _lastFriendsUpdateDirty = NO;
    _lastProfileUpdateDirty = NO;
    _browseRefreshPeriodInSecondsDirty = NO;
    _emailAddressDirty = NO;
    _passwordDirty = NO;
    _screenNameDirty = NO;
    _accountTierDirty = NO;
}

-(BOOL)canSendMessages
{
    return (self.accountTier >= 6);
}

-(NSInteger)accountTier
{
    return _accountTier;
}

-(void)setAccountTier:(NSInteger)accountTier
{
    _accountTier = accountTier;
    _accountTierDirty = YES;
}

-(NSDate*)lastProfileUpdate
{
    return _lastProfileUpdate;
}

-(void)setLastProfileUpdate:(NSDate*)lastUpdate
{
    [lastUpdate retain];
    [_lastProfileUpdate release];
    
    _lastProfileUpdate = lastUpdate;
    _lastProfileUpdateDirty = YES;
}

-(NSDate*)lastGamesUpdate
{
    return _lastGamesUpdate;
}

-(void)setLastGamesUpdate:(NSDate*)lastGamesUpdate
{
    [lastGamesUpdate retain];
    [_lastGamesUpdate release];
    
    _lastGamesUpdate = lastGamesUpdate;
    _lastGamesUpdateDirty = YES;
}

-(NSDate*)lastMessagesUpdate
{
    return _lastMessagesUpdate;
}

-(void)setLastMessagesUpdate:(NSDate *)lastUpdate
{
    [lastUpdate retain];
    [_lastMessagesUpdate release];
    
    _lastMessagesUpdate = lastUpdate;
    _lastMessagesUpdateDirty = YES;
}

-(NSDate*)lastFriendsUpdate
{
    return _lastFriendsUpdate;
}

-(void)setLastFriendsUpdate:(NSDate *)lastUpdate
{
    [lastUpdate retain];
    [_lastFriendsUpdate release];
    
    _lastFriendsUpdate = lastUpdate;
    _lastFriendsUpdateDirty = YES;
}

-(NSString*)screenName
{
    return _screenName;
}

-(void)setScreenName:(NSString *)screenName
{
    [screenName retain];
    [_screenName release];
    
    _screenName = screenName;
    _screenNameDirty = YES;
}

-(NSNumber*)stalePeriodInSeconds
{
    return _stalePeriodInSeconds;
}

-(void)setStalePeriodInSeconds:(NSNumber*)browseRefreshPeriodInSeconds
{
    [browseRefreshPeriodInSeconds retain];
    [_stalePeriodInSeconds release];
    
    _stalePeriodInSeconds = browseRefreshPeriodInSeconds;
    _browseRefreshPeriodInSecondsDirty = YES;
}

-(NSString*)emailAddress
{
    return _emailAddress;
}

-(void)setEmailAddress:(NSString*)emailAddress
{
    [emailAddress retain];
    [_emailAddress release];
    
    _emailAddress = emailAddress;
    _emailAddressDirty = YES;
}

-(NSString*)password
{
    return _password;
}

-(void)setPassword:(NSString*)password
{
    [password retain];
    [_password release];
    
    _password = password;
    _passwordDirty = YES;
}

-(BOOL)isDataStale:(NSDate*)lastRefreshed
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setSecond:-[self.stalePeriodInSeconds intValue]];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *refreshDate = [gregorian dateByAddingComponents:comps 
                                                     toDate:[NSDate date] 
                                                    options:0];
    
    BOOL stale = ([lastRefreshed compare:refreshDate] == NSOrderedAscending);
    
    [comps release];
    [gregorian release];
    
    return stale;
}

-(BOOL)areGamesStale
{
    return [self isDataStale:self.lastGamesUpdate];
}

-(BOOL)areMessagesStale
{
    return [self isDataStale:self.lastMessagesUpdate];
}

-(BOOL)areFriendsStale
{
    return [self isDataStale:self.lastFriendsUpdate];
}

-(BOOL)isProfileStale
{
    return [self isDataStale:self.lastProfileUpdate];
}

-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[XboxLiveAccount class]])
        return NO;
    
    return [self isEqualToAccount:object];
}

-(BOOL)isEqualToAccount:(XboxLiveAccount*)account
{
    return [self.uuid isEqualToString:account.uuid];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"%@ (UUID %@)", 
            self.emailAddress, self.uuid];
}

#pragma mark Helpers

-(NSString*)keyForPreference:(NSString*)preference
{
    return [NSString stringWithFormat:@"%@.%@", self.uuid, preference];
}

#pragma mark Constructor, destructor

+(id)preferencesForUuid:(NSString*)uuid 
{
    return [[[XboxLiveAccount alloc] initWithUuid:uuid] autorelease];
}

-(id)initWithUuid:(NSString*)uuid 
{
    if (self = [super init]) 
    {
        _uuid = [uuid copy];
        [self reload];
    }
    
    return self;
}

-(id)init 
{
    if (self = [self initWithUuid:nil]) 
    {
    }
    
    return self;
}

-(void)dealloc 
{
    [self resetDirtyFlags];
    
    [_uuid release];
    _uuid = nil;
    
    self.lastGamesUpdate = nil;
    self.lastMessagesUpdate = nil;
    self.lastFriendsUpdate = nil;
    self.lastProfileUpdate = nil;
    self.stalePeriodInSeconds = nil;
    self.emailAddress = nil;
    self.password = nil;
    self.screenName = nil;
    
    [super dealloc];
}

@end
