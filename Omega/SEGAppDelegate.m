//
//  SEGAppDelegate.m
//  Omega
//
//  Created by Samuel E. Giddins on 6/3/13.
//  Copyright (c) 2013 Samuel E. Giddins. All rights reserved.
//

#import "SEGAppDelegate.h"

#import <ITSidebar/ITSidebar.h>
#import <ITSidebar/ITSidebarItemCell.h>

@interface SEGAppDelegate () <NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate>
@property (weak) IBOutlet NSMenuItem *refreshMenu;

@property (assign) IBOutlet ITSidebar *sidebar;
@property (assign) IBOutlet NSTextField *label;
@property (assign) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) NSArray *channels;

@property (nonatomic, strong) NSArray *messages;

@end

@implementation SEGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [[ANKClient sharedClient] setAccessToken:ADN_ACCESS_TOKEN];
    [self.refreshMenu setEnabled:YES];
    [self refreshChannels:nil];

    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
}

- (IBAction)sidebarChanged:(ITSidebar *)sender {
    ANKChannel *channel = self.channels[sender.selectedIndex];
    [[ANKClient sharedClient] fetchMessagesInChannel:channel completion:^(id responseObject, ANKAPIResponseMeta *meta, NSError *error) {
        if (error) {
            return;
        }
        NSLog(@"responseObject: %@\nmeta: %@\nerror: %@", responseObject, meta, error);
        self.messages = responseObject;
        ANKMessage *lastMessage = [self.messages lastObject];
        self.label.stringValue = lastMessage.text;
        [self.tableView reloadData];
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.messages.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // the return value is typed as (id) because it will return a string in all cases with the exception of the
    id returnValue=nil;

    // The column identifier string is the easiest way to identify a table column. Much easier
    // than keeping a reference to the table column object.
    NSString *columnIdentifer = [tableColumn identifier];

    // Get the name at the specified row in the namesArray
    ANKMessage *message = [self.messages objectAtIndex:row];
    NSString *theName = [[message user] name];


    // Compare each column identifier and set the return value to
    // the Person field value appropriate for the column.
    if ([columnIdentifer isEqualToString:@"Username"]) {
        returnValue = theName;
    } else {
        returnValue = message.text;
    }

    return returnValue;
}
- (IBAction)refreshChannels:(id)sender {
    [self.refreshMenu setEnabled:NO];
    [[ANKClient sharedClient] fetchCurrentUserSubscribedChannelsWithCompletion:^(id responseObject, ANKAPIResponseMeta *meta, NSError *error) {
        [self.refreshMenu setEnabled:YES];
        NSLog(@"responseObject: %@\nmeta: %@\nerror: %@", responseObject, meta, error);
        if (error) {
            return;
        }
        
        self.channels = responseObject;
        
        [self.sidebar setTarget:self];
        [self.sidebar setAction:@selector(sidebarChanged:)];
        while (self.sidebar.matrix.numberOfRows > 0) {
            [self.sidebar removeRow:0];
        }
        CGSize size = self.sidebar.cellSize;
        size.width *= .9;
        size.height *= .9;
        [self.channels enumerateObjectsUsingBlock:^(ANKChannel *channel, NSUInteger idx, BOOL *stop) {
            ITSidebarItemCell *cell = [self.sidebar addItemWithImage:[[NSImage alloc] initWithContentsOfURL:[channel.latestMessage.user.avatarImage URLForSize: size]] alternateImage:nil];
            [cell setTag:idx + 1];
        }];
    }];
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        ANKMessage *message = [[ANKMessage alloc] init];
        message.text = textView.string;
        [[ANKClient sharedClient] createMessage:message inChannelWithID:[[self.messages lastObject] channelID] completion:^(id responseObject, ANKAPIResponseMeta *meta, NSError *error) {
            NSLog(@"responseObject: %@\nmeta: %@\nerror: %@", responseObject, meta, error);
            if (!error) {
                textView.string = @"";
                [self refresh];
            }
        }];
        return YES;
    }
    return NO;
}

- (void)refresh {
    [self sidebarChanged:self.sidebar];
}

@end
