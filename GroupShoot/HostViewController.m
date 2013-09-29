//
//  HostViewController.m
//  GKSession
//
//  Created by Huizhe Xiao on 13-9-28.
//  Copyright (c) 2013年 Huizhe Xiao. All rights reserved.
//

#import "HostViewController.h"
#import "Const.h"
@interface HostViewController ()<GKSessionDelegate>{
	GKSession* session;
	GKSession* broadcaseTakeActionSession;
	GKSession* broadcaseSettingsSession;
}

@end

@implementation HostViewController
@synthesize serverAddress, clients, imageQuality;
-(void)load{
	
	session = [[GKSession alloc] initWithSessionID:nil displayName:SERVER_DISPLAY_NAME sessionMode:GKSessionModePeer];
	
	self.title = @"Host";
	[session setDataReceiveHandler:self withContext:nil];
	session.delegate = self;
	session.disconnectTimeout = 5;
	session.available = YES;
}
-(void)unload{
	session.delegate = nil;
	[session disconnectFromAllPeers];
	session.available = NO;
	session = nil;
	[self shutdownBoardcaseSession];
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (NSString *)uuidString {
    // Returns a UUID
	
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
	
	uuidStr = [uuidStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return uuidStr;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	[self load];
	[[NSNotificationCenter defaultCenter] addObserver:self
                      selector:@selector(load)
                          name:UIApplicationWillEnterForegroundNotification
                        object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                      selector:@selector(unload)
                          name:UIApplicationDidEnterBackgroundNotification
                        object:nil];
	
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(saveServerAddress)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"serverAddress"] length]) {
		serverAddress.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverAddress"];
	}
	[self broadcaseSettings:nil];
}
-(void)saveServerAddress{
	if(serverAddress.text.length)
		[[NSUserDefaults standardUserDefaults] setObject:serverAddress.text forKey:@"serverAddress"];
}

-(IBAction)broadcaseSettings:(id)sender{
	
	[broadcaseSettingsSession disconnectFromAllPeers];
	broadcaseSettingsSession.available = NO;
	broadcaseSettingsSession = nil;
	NSString* f = imageQuality.value >= 0.99 ? @"1.0" : [NSString stringWithFormat:@"0.%d", (int)(imageQuality.value * 10)];
	broadcaseSettingsSession = [[GKSession alloc] initWithSessionID:nil displayName:[NSString stringWithFormat:@"%@%@%@", DIRECT_SETTINGS_DISPLAY_NAME_PREFIX, f, serverAddress.text] sessionMode:GKSessionModePeer];
	broadcaseSettingsSession.available = YES;
}
-(void)shutdownBoardcaseSession{
	[broadcaseTakeActionSession disconnectFromAllPeers];
	broadcaseTakeActionSession.available = NO;
	broadcaseTakeActionSession = nil;
}
-(IBAction)send:(id)sender{
	NSString* uuid = [self uuidString];
	NSString* data = [NSString stringWithFormat:@"%@ TAKE %f|%@", uuid, imageQuality.value, serverAddress.text];
	[session sendDataToAllPeers:[data dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataUnreliable error:nil];
	[session sendDataToAllPeers:[data dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
	
	broadcaseTakeActionSession = [[GKSession alloc] initWithSessionID:nil displayName:[NSString stringWithFormat:@"%@%@", DIRECT_TAKE_DISPLAY_NAME_PREFIX, uuid] sessionMode:GKSessionModePeer];
	broadcaseTakeActionSession.available = YES;
	[self performSelector:@selector(shutdownBoardcaseSession) withObject:nil afterDelay:2.0];
}
-(void)connectPeer:(NSString*)peerID{
	if (![[session displayNameForPeer:peerID] isEqualToString:SERVER_DISPLAY_NAME] && ![[[session displayNameForPeer:peerID] substringToIndex:[DIRECT_TAKE_DISPLAY_NAME_PREFIX length]] isEqualToString:DIRECT_TAKE_DISPLAY_NAME_PREFIX] && ![[[session displayNameForPeer:peerID] substringToIndex:[DIRECT_SETTINGS_DISPLAY_NAME_PREFIX length]] isEqualToString:DIRECT_SETTINGS_DISPLAY_NAME_PREFIX]) {
		[session connectToPeer:peerID withTimeout:5];
		[self.clients reloadData];
	}
}
- (void)session:(GKSession *)s peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
	if(state == GKPeerStateDisconnected)
    {
    }
    else if(state == GKPeerStateConnected)
    {
    }
    else if (state == GKPeerStateAvailable)
    {
		if (![[session displayNameForPeer:peerID] isEqualToString:SERVER_DISPLAY_NAME]) {
			[self performSelector:@selector(connectPeer:) withObject:peerID afterDelay:0.5];
		}
    }
	[self.clients reloadData];
}
- (void)session:(GKSession *)s didReceiveConnectionRequestFromPeer:(NSString *)peerID{
	if (![[s displayNameForPeer:peerID] isEqualToString:SERVER_DISPLAY_NAME]) {
		[s acceptConnectionFromPeer:peerID error:NULL];
	}
}

- (void)session:(GKSession *)s connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error{
	NSLog(@"connectionWithPeerFailed: %@ %@", peerID, error);
	[self.clients reloadData];
	// retry
	if (![[s displayNameForPeer:peerID] isEqualToString:SERVER_DISPLAY_NAME]) {
		[self performSelector:@selector(connectPeer:) withObject:peerID afterDelay:0.5];
	}
}
- (void)session:(GKSession *)session didFailWithError:(NSError *)error{
	NSLog(@"didFailWithError: %@", error);
	[self.clients reloadData];
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 5;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	if(section == 0){
		return [session peersWithConnectionState:GKPeerStateConnected].count;
	}else if(section == 1){
		return [session peersWithConnectionState:GKPeerStateDisconnected].count;
	}else if (section == 2) {
		return [session peersWithConnectionState:GKPeerStateAvailable].count;
	}else if(section == 3){
		return [session peersWithConnectionState:GKPeerStateUnavailable].count;
	}else if(section == 4){
		return [session peersWithConnectionState:GKPeerStateConnecting].count;
	}
	return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell* c = [tableView dequeueReusableCellWithIdentifier:@"c"];
	if (!c) {
		c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"];
	}
	NSArray* peers = nil;
	if(indexPath.section == 0){
		peers = [session peersWithConnectionState:GKPeerStateConnected];
	}else if(indexPath.section == 1){
		peers = [session peersWithConnectionState:GKPeerStateDisconnected];
	}else if (indexPath.section == 2) {
		peers = [session peersWithConnectionState:GKPeerStateAvailable];
	}else if(indexPath.section == 3){
		peers = [session peersWithConnectionState:GKPeerStateUnavailable];
	}else if(indexPath.section == 4){
		peers = [session peersWithConnectionState:GKPeerStateConnecting];
	}
	if (indexPath.row < peers.count) {
		c.textLabel.text = [session displayNameForPeer:[peers objectAtIndex:indexPath.row]];
	}else{
		c.textLabel.text = @"";
	}
	return c;
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	int count = 0;
	if(section == 0){
		count = [session peersWithConnectionState:GKPeerStateConnected].count;
		return count ? [NSString stringWithFormat:@"Connected %d", count] : nil;
	}else if(section == 1){
		count = [session peersWithConnectionState:GKPeerStateDisconnected].count;
		return count ? [NSString stringWithFormat:@"Disconnected %d", count] : nil;
	}else if (section == 2) {
		count = [session peersWithConnectionState:GKPeerStateAvailable].count;
		return count ? [NSString stringWithFormat:@"Available %d", count] : nil;
	}else if(section == 3){
		count = [session peersWithConnectionState:GKPeerStateUnavailable].count;
		return count ? [NSString stringWithFormat:@"Unavailable %d", count] : nil;
	}else if(section == 4){
		count = [session peersWithConnectionState:GKPeerStateConnecting].count;
		return count ? [NSString stringWithFormat:@"Connecting %d", count] : nil;
	}
	return nil;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}
@end
