//
//  RootViewController.h
//  ListTest
//
//  Created by Akop Karapetyan on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "GenericListController.h"

@interface GameListController : GenericListController <NSFetchedResultsControllerDelegate>

@property (nonatomic, assign) IBOutlet UITableViewCell *tvCell;

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

-(id)initWithAccount:(XboxLiveAccount*)account;

@end
