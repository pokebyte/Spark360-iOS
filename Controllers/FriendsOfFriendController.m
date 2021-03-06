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

#import "FriendsOfFriendController.h"

#import "TaskController.h"
#import "PlayerCell.h"

#import "ProfileController.h"

@implementation FriendsOfFriendController

@synthesize screenName = _screenName;
@synthesize friendsOfFriend = _friendsOfFriend;
@synthesize lastUpdated = _lastUpdated;

-(id)initWithScreenName:(NSString*)screenName
                account:(XboxLiveAccount*)account;
{
    if (self = [super initWithAccount:account
                              nibName:@"FriendsOfFriendController"])
    {
        self.lastUpdated = nil;
        self.screenName = screenName;
        
        _friendsOfFriend = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    self.friendsOfFriend = nil;
    self.screenName = nil;
    self.lastUpdated = nil;
    
    [super dealloc];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataLoaded:)
                                                 name:BACHFriendsOfFriendLoaded
                                               object:nil];
    
    self.title = NSLocalizedString(@"FriendsOfFriend", nil);
    
    [self synchronizeWithRemote];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BACHFriendsOfFriendLoaded
                                                  object:nil];
}

#pragma mark - GenericTableViewController

-(NSDate*)lastSynchronized
{
    return self.lastUpdated;
}

- (void)mustSynchronizeWithRemote
{
    [super mustSynchronizeWithRemote];
    
    [[TaskController sharedInstance] loadFriendsOfFriendForScreenName:self.screenName
                                                              account:self.account];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

-(BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return [[TaskController sharedInstance] isLoadingRecentPlayersForAccount:self.account];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section 
{
    return [self.friendsOfFriend count];
}

- (UITableViewCell *)tableView:(UITableView *)tv 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    PlayerCell *cell = (PlayerCell*)[self.tableView dequeueReusableCellWithIdentifier:@"playerCell"];
    
    if (indexPath.row < [self.friendsOfFriend count])
    {
        if (!cell)
        {
            UINib *cellNib = [UINib nibWithNibName:@"PlayerCell" 
                                            bundle:nil];
            
            NSArray *topLevelObjects = [cellNib instantiateWithOwner:nil options:nil];
            
            for (id object in topLevelObjects)
            {
                if ([object isKindOfClass:[UITableViewCell class]])
                {
                    cell = (PlayerCell *)object;
                    break;
                }
            }
        }
        
        NSDictionary *player = [self.friendsOfFriend objectAtIndex:indexPath.row];
        
        cell.screenName.text = [player objectForKey:@"screenName"];
        cell.activity.text = [player objectForKey:@"activityText"];
        cell.gamerScore.text = [NSString localizedStringWithFormat:[self.numberFormatter stringFromNumber:[player objectForKey:@"gamerScore"]]];
        
        UIImage *gamerpic = [self tableCellImageFromUrl:[player objectForKey:@"iconUrl"]
                                              indexPath:indexPath];
        
        UIImage *boxArt = [self tableCellImageFromUrl:[player objectForKey:@"activityTitleIconUrl"]
                                             cropRect:CGRectMake(0,16,85,85)
                                            indexPath:indexPath];
        
        cell.gamerpic.image = gamerpic;
        cell.titleIcon.image = boxArt;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *friendOfFriend = [self.friendsOfFriend objectAtIndex:indexPath.row];
    
    [ProfileController showProfileWithScreenName:[friendOfFriend objectForKey:@"screenName"]
                                         account:self.account
                            managedObjectContext:managedObjectContext
                            navigationController:self.navigationController];
}

#pragma mark - Notifications

-(void)dataLoaded:(NSNotification *)notification
{
    BACHLog(@"Got data loaded notification");
    
    XboxLiveAccount *account = [notification.userInfo objectForKey:BACHNotificationAccount];
    NSString *screenName = [notification.userInfo objectForKey:BACHNotificationScreenName];
    
    if ([self.account isEqualToAccount:account] && [self.screenName isEqualToString:screenName])
    {
        [self hideRefreshHeaderTableView];
        
        NSArray *players = [notification.userInfo objectForKey:BACHNotificationData];
        
        [self.friendsOfFriend removeAllObjects];
        [self.friendsOfFriend addObjectsFromArray:players];
        
        self.lastUpdated = [NSDate date];
        [self.tableView reloadData];
        
        [self updateSynchronizationDate];
    }
}

@end
