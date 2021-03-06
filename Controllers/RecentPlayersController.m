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

#import "RecentPlayersController.h"

#import "TaskController.h"
#import "PlayerCell.h"

#import "ProfileController.h"

@implementation RecentPlayersController

@synthesize players = _players;
@synthesize lastUpdated = _lastUpdated;

-(id)initWithAccount:(XboxLiveAccount*)account;
{
    if (self = [super initWithAccount:account
                              nibName:@"RecentPlayersController"])
    {
        self.lastUpdated = nil;
        
        _players = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    self.players = nil;
    self.lastUpdated = nil;
    
    [super dealloc];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playersLoaded:)
                                                 name:BACHRecentPlayersLoaded
                                               object:nil];
    
    self.title = NSLocalizedString(@"RecentPlayers", nil);
    
    [self synchronizeWithRemote];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BACHRecentPlayersLoaded
                                                  object:nil];
}

#pragma mark - GenericTableViewController

- (NSDate*)lastSynchronized
{
	return self.lastUpdated;
}

- (void)mustSynchronizeWithRemote
{
    [super mustSynchronizeWithRemote];
    
    [[TaskController sharedInstance] loadRecentPlayersForAccount:self.account];
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
    return [self.players count];
}

- (UITableViewCell *)tableView:(UITableView *)tv 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    PlayerCell *playerCell = (PlayerCell*)[self.tableView dequeueReusableCellWithIdentifier:@"playerCell"];
    
    if (indexPath.row < [self.players count])
    {
        if (!playerCell)
        {
            UINib *cellNib = [UINib nibWithNibName:@"PlayerCell" 
                                            bundle:nil];
            
            NSArray *topLevelObjects = [cellNib instantiateWithOwner:nil options:nil];
            
            for (id object in topLevelObjects)
            {
                if ([object isKindOfClass:[UITableViewCell class]])
                {
                    playerCell = (PlayerCell *)object;
                    break;
                }
            }
        }
        
        NSDictionary *player = [self.players objectAtIndex:indexPath.row];
        
        playerCell.screenName.text = [player objectForKey:@"screenName"];
        playerCell.activity.text = [player objectForKey:@"activityText"];
        playerCell.gamerScore.text = [NSString localizedStringWithFormat:[self.numberFormatter stringFromNumber:[player objectForKey:@"gamerScore"]]];
        
        UIImage *gamerpic = [self tableCellImageFromUrl:[player objectForKey:@"iconUrl"]
                                              indexPath:indexPath];
        
        UIImage *boxArt = [self tableCellImageFromUrl:[player objectForKey:@"activityTitleIconUrl"]
                                             cropRect:CGRectMake(0,16,85,85)
                                            indexPath:indexPath];
        
        playerCell.gamerpic.image = gamerpic;
        playerCell.titleIcon.image = boxArt;
    }
    
    return playerCell;
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *player = [self.players objectAtIndex:indexPath.row];
    
    [ProfileController showProfileWithScreenName:[player objectForKey:@"screenName"]
                                         account:self.account
                            managedObjectContext:managedObjectContext
                            navigationController:self.navigationController];
}

#pragma mark - Notifications

-(void)playersLoaded:(NSNotification *)notification
{
    BACHLog(@"Got players loaded notification");
    
    XboxLiveAccount *account = [notification.userInfo objectForKey:BACHNotificationAccount];
    
    if ([self.account isEqualToAccount:account])
    {
        [self hideRefreshHeaderTableView];
        
        NSArray *players = [notification.userInfo objectForKey:BACHNotificationData];
        
        [self.players removeAllObjects];
        [self.players addObjectsFromArray:players];
        
        self.lastUpdated = [NSDate date];
        [self.tableView reloadData];
        
        [self updateSynchronizationDate];
    }
}

@end
