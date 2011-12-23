//
//  CFImageRetrievalOperation.m
//  ListTest
//
//  Created by Akop Karapetyan on 8/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageCacheOperation.h"

@implementation ImageCacheOperation

@synthesize outputFile;

- (id)initWithURL:(NSString*)imageUrl
       outputFile:(NSString*)writeTo
     notifyObject:(id)notifyObject
   notifySelector:(SEL)notifySelector
         cropRect:(CGRect)rect
{
    if (self = [super init]) 
    {
        self->url = [imageUrl copy];
        self.outputFile = writeTo;
        self->notifyObj = [notifyObject retain];
        self->notifySel = notifySelector;
        self->cropRect = rect;
    }
    
    return self;
}

- (void)dealloc
{
    [self->url release];
    [self->notifyObj release];
    
    self.outputFile = nil;
    
    [super dealloc];
}

- (void)main
{
    if ([self isCancelled])
        return;
    
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self->url]];
    
    if (!CGRectIsNull(self->cropRect))
    {
        UIImage *image = [UIImage imageWithData:data];
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], self->cropRect);
        UIImage *cropped = [UIImage imageWithCGImage:imageRef];
        
        CGImageRelease(imageRef);
        
        data = UIImagePNGRepresentation(cropped);
    }
    
    [data writeToFile:self.outputFile 
           atomically:YES];
    
#ifdef CF_LOGV
    NSLog(@"Downloaded %@ to %@", self->url, self->outputFile);
#endif
    
    if (![self isCancelled])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ImageLoadedFromWeb"
                                                            object:self];
    }
}

- (void)notifyDone
{
    if (self->notifySel != nil && self->notifyObj != nil)
    {
        [self->notifyObj performSelector:self->notifySel 
                              withObject:self->url];
    }
}

@end