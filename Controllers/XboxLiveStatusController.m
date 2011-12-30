//
//  XboxLiveStatusController.m
//  BachZero
//
//  Created by Akop Karapetyan on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "XboxLiveStatusController.h"

#import "TaskController.h"

#import "XboxLiveStatusCell.h"

@implementation XboxLiveStatusController

@synthesize statuses = _statuses;
@synthesize lastUpdated = _lastUpdated;

-(id)initWithAccount:(XboxLiveAccount *)account;
{
    if ((self = [super initWithAccount:account
                               nibName:@"XboxLiveStatusController"]))
    {
        _statuses = [[NSMutableArray alloc] init];
        self.lastUpdated = nil;
    }
    
    return self;
}

-(void)dealloc
{
    self.statuses = nil;
    self.lastUpdated = nil;
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"XboxLiveStatus", nil);
    
	[_refreshHeaderView refreshLastUpdatedDate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusLoaded:)
                                                 name:BACHXboxLiveStatusLoaded
                                               object:nil];
    
    [self refreshUsingRefreshHeaderTableView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BACHXboxLiveStatusLoaded
                                                  object:nil];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

-(void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    [[TaskController sharedInstance] loadXboxLiveStatus:self.account];
}

-(BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return [[TaskController sharedInstance] isLoadingXboxLiveStatus:self.account];
}

-(NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return self.lastUpdated;
}

#pragma mark - UITableViewDataSource

- (NSString*)tableView:(UITableView *)tableView 
titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return NSLocalizedString(@"Services", nil);
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section 
{
    return [self.statuses count];
}

- (UITableViewCell *)tableView:(UITableView *)tv 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    XboxLiveStatusCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (indexPath.row < [self.statuses count])
    {
        if (!cell)
        {
            [[NSBundle mainBundle] loadNibNamed:@"XboxLiveStatusCell"
                                          owner:self
                                        options:nil];
            
            cell = (XboxLiveStatusCell*)self.tableViewCell;
        }
        
        NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
        
        cell.statusName.text = [status objectForKey:@"name"];
        cell.statusDescription.text = [status objectForKey:@"description"];
        
        NSString *statusIconFile;
        if ([[status objectForKey:@"isOk"] boolValue])
            statusIconFile = @"xboxStatusOk";
        else 
            statusIconFile = @"xboxStatusNotOk";
        
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:statusIconFile
                                                              ofType:@"png"];
        
        cell.statusIcon.image = [UIImage imageWithContentsOfFile:imagePath];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[status objectForKey:@"name"] 
                                                        message:[status objectForKey:@"description"]
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil) 
                                              otherButtonTitles:nil];
    
    [alertView show];
    [alertView release];
}

#pragma mark - Notifications

-(void)statusLoaded:(NSNotification *)notification
{
    NSLog(@"Got statusLoaded notification");
    
    NSDictionary *data = [notification.userInfo objectForKey:BACHNotificationData];
    NSArray *statuses = [data objectForKey:@"statusList"];
    
    [self hideRefreshHeaderTableView];
    
    [self.statuses removeAllObjects];
    [self.statuses addObjectsFromArray:statuses];
    
    self.lastUpdated = [NSDate date];
    [self.tableView reloadData];
    
    [_refreshHeaderView refreshLastUpdatedDate];
}

#pragma mark - Actions

-(IBAction)refresh:(id)sender
{
    [self refreshUsingRefreshHeaderTableView];
}

@end
