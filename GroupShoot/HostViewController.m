//
//  HostViewController.m
//  GKSession
//
//  Created by Huizhe Xiao on 13-9-28.
//  Copyright (c) 2013年 Huizhe Xiao. All rights reserved.
//

#import "HostViewController.h"
#import "Const.h"
@interface HostViewController ()<AsyncUdpSocketDelegate>{
	AsyncUdpSocket* socket;
}

@end

@implementation HostViewController
@synthesize serverAddress, clients, imageQuality;
-(void)load{
	
	socket=[[AsyncUdpSocket alloc]initIPv4];
	socket.delegate = self;
	
	
	NSError *error = nil;
	[socket bindToPort:SOURCE_PORT error:&error];
	
	[socket enableBroadcast:YES error:&error];
	
	
}
-(void)unload{
	socket.delegate = nil;
	socket = nil;
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
	
}
-(IBAction)send:(id)sender{
	NSString* uuid = [self uuidString];
	NSString* data = [NSString stringWithFormat:@"%@ TAKE %f|%@", uuid, imageQuality.value, serverAddress.text];
	
	[socket sendData:[data dataUsingEncoding:NSUTF8StringEncoding] toHost:@"255.255.255.255" port:DEST_PORT withTimeout:5 tag:1];
	
}
- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
	NSLog(@"didSendDataWithTag: %ld", tag);
}
- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
	
	NSLog(@"didNotSendDataWithTag: %ld %@", tag, error);
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 5;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//	if(section == 0){
//		return [session peersWithConnectionState:GKPeerStateConnected].count;
//	}else if(section == 1){
//		return [session peersWithConnectionState:GKPeerStateDisconnected].count;
//	}else if (section == 2) {
//		return [session peersWithConnectionState:GKPeerStateAvailable].count;
//	}else if(section == 3){
//		return [session peersWithConnectionState:GKPeerStateUnavailable].count;
//	}else if(section == 4){
//		return [session peersWithConnectionState:GKPeerStateConnecting].count;
//	}
	return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell* c = [tableView dequeueReusableCellWithIdentifier:@"c"];
	if (!c) {
		c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"];
	}
//	NSArray* peers = nil;
//	if(indexPath.section == 0){
//		peers = [session peersWithConnectionState:GKPeerStateConnected];
//	}else if(indexPath.section == 1){
//		peers = [session peersWithConnectionState:GKPeerStateDisconnected];
//	}else if (indexPath.section == 2) {
//		peers = [session peersWithConnectionState:GKPeerStateAvailable];
//	}else if(indexPath.section == 3){
//		peers = [session peersWithConnectionState:GKPeerStateUnavailable];
//	}else if(indexPath.section == 4){
//		peers = [session peersWithConnectionState:GKPeerStateConnecting];
//	}
//	if (indexPath.row < peers.count) {
//		c.textLabel.text = [session displayNameForPeer:[peers objectAtIndex:indexPath.row]];
//	}else{
//		c.textLabel.text = @"";
//	}
	return c;
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//	int count = 0;
//	if(section == 0){
//		count = [session peersWithConnectionState:GKPeerStateConnected].count;
//		return count ? [NSString stringWithFormat:@"Connected %d", count] : nil;
//	}else if(section == 1){
//		count = [session peersWithConnectionState:GKPeerStateDisconnected].count;
//		return count ? [NSString stringWithFormat:@"Disconnected %d", count] : nil;
//	}else if (section == 2) {
//		count = [session peersWithConnectionState:GKPeerStateAvailable].count;
//		return count ? [NSString stringWithFormat:@"Available %d", count] : nil;
//	}else if(section == 3){
//		count = [session peersWithConnectionState:GKPeerStateUnavailable].count;
//		return count ? [NSString stringWithFormat:@"Unavailable %d", count] : nil;
//	}else if(section == 4){
//		count = [session peersWithConnectionState:GKPeerStateConnecting].count;
//		return count ? [NSString stringWithFormat:@"Connecting %d", count] : nil;
//	}
	return nil;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}
@end
