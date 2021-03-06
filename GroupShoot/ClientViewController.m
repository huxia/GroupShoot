//
//  ClientViewController.m
//  GKSession
//
//  Created by Huizhe Xiao on 13-9-28.
//  Copyright (c) 2013年 Huizhe Xiao. All rights reserved.
//

#import "ClientViewController.h"
#import "ASIFormDataRequest.h"
#import "RegexKitLite.h"
#import "Const.h"
@interface ClientViewController ()<AsyncUdpSocketDelegate,ASIHTTPRequestDelegate>{
	
	AVCaptureSession* avSession;
	AVCaptureDeviceInput* avInput;
	AVCaptureStillImageOutput *avStillImageOutput;
	
	CGFloat settingsQuality;
	NSString* settingsAddress;
	NSString* cachedUUID;
	AsyncUdpSocket* socket;
}

@end

@implementation ClientViewController
@synthesize statusLabel, previewView, log;
-(void)load{
	{
		[self log:@"load"];
		
		socket=[[AsyncUdpSocket alloc]initIPv4];
		socket.delegate = self;
		
		
		//绑定端口
		NSError *error = nil;
		if(![socket bindToPort:DEST_PORT error:&error] || error){
			[self log:[NSString stringWithFormat:@"bindToPort failed %@", error]];
		}else{
			[self log:@"binded to port"];
		}
		
		
		if(![socket enableBroadcast:YES error:&error] || error){
			[self log:[NSString stringWithFormat:@"enableBroadcast failed %@", error]];
		}
		
		[socket receiveWithTimeout:-1 tag:0];
		
	}
	{
		avSession = [[AVCaptureSession alloc] init];
		avSession.sessionPreset = AVCaptureSessionPresetPhoto;
		CALayer *viewLayer = self.previewView.layer;
		NSLog(@"viewLayer = %@", viewLayer);
		
		AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:avSession];
		
		captureVideoPreviewLayer.frame = self.previewView.bounds;
		[self.previewView.layer addSublayer:captureVideoPreviewLayer];
		
		AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		
		NSError *error = nil;
		avInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
		if (!avInput) {
			// Handle the error appropriately.
			NSLog(@"ERROR: trying to open camera: %@", error);
			avSession = nil;
		}
		[avSession addInput:avInput];
		
		avStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
		[avStillImageOutput setOutputSettings:outputSettings];
		
		[avSession addOutput:avStillImageOutput];
		
		[avSession startRunning];
	}
}
-(void)unload{
	{
		[self log:@"unload"];
		socket.delegate = nil;
		socket = nil;
	}
	{
		
		[avSession removeInput:avInput];
		[avSession removeOutput:avStillImageOutput];
		[avSession stopRunning];
		avSession = nil;
		avInput = nil;
		avStillImageOutput = nil;
	}
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
	
}
-(void)log:(NSString*)s{
	self.log.text = [NSString stringWithFormat:@"%@\n%@", self.log.text, s];
	[self.log scrollRangeToVisible:NSMakeRange(self.log.text.length-1, 1)];
}
-(void)reload{
	[self load];
	[self unload];
}
-(void)upload:(NSDictionary*)info{
	NSData* data = [info objectForKey:@"data"];
	NSString* url = [info objectForKey:@"serverAddress"];
	if (![url isMatchedByRegex:@"^https?\\:\\/\\/" options:RKLCaseless inRange:NSMakeRange(0, url.length) error:NULL]) {
		url = [NSString stringWithFormat:@"http://%@", url];
	}
	ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
	[self log:[NSString stringWithFormat:@"upload to %@... (%d)", [info objectForKey:@"serverAddress"], data.length]];
	request.delegate = self;
	request.userInfo = info;
	[request addData:data withFileName:@"1.jpg" andContentType:@"image/jpeg" forKey:@"photo"];
	[request setPostValue:[info objectForKey:@"meta"] forKey:@"meta"];
	[request setPostValue:[UIDevice currentDevice].name forKey:@"device"];
	[request startAsynchronous];
}
-(void)command:(NSString*)c{
	NSArray* a = [c componentsSeparatedByString:@" "];
	if (!a || a.count <= 1) {
		return;
	}
	NSString* uuid = [a objectAtIndex:0];
	if (!uuid || !uuid.length)
		return;
	static NSMutableDictionary* d = nil;
	if (!d) d = [[NSMutableDictionary alloc] init];
	if ([d objectForKey:uuid]) return;
	[d setObject:c forKey:uuid];
	
	NSString* command = [c substringWithRange:NSMakeRange(uuid.length + 1, 4)];
	NSString* commandArgs = [c substringFromIndex:uuid.length + 6];
	if ([command isEqualToString:@"TAKE"]) {
		[self log:[NSString stringWithFormat:@"take picture"]];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearReceivedData) object:nil];
		[self performSelector:@selector(clearReceivedData) withObject:nil afterDelay:4.0];
		self.statusLabel.text = c;
		AVCaptureConnection *videoConnection = nil;
		for (AVCaptureConnection *connection in avStillImageOutput.connections)
		{
			for (AVCaptureInputPort *port in [connection inputPorts])
			{
				if ([[port mediaType] isEqual:AVMediaTypeVideo] )
				{
					videoConnection = connection;
					break;
				}
			}
			if (videoConnection) { break; }
		}
		[avStillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
		 {
			 [self log:[NSString stringWithFormat:@"take picture done"]];
			 NSDictionary* meta = [NSDictionary dictionary];
			 CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
			 if (exifAttachments)
			 {
				 // Do something with the attachments.
				 NSLog(@"attachements: %@", exifAttachments);
				 meta = (__bridge NSDictionary*)exifAttachments;
			 }
			 else
				 NSLog(@"no attachments");
			 
			 CGFloat imageQuality = [[[commandArgs componentsSeparatedByString:@"|"] objectAtIndex:0] floatValue];
			 NSString* serverAddress = [[commandArgs componentsSeparatedByString:@"|"] objectAtIndex:1];
			 
			 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
			 UIImage* image = nil;
#ifdef __OPTIMIZE__
			 if (!image) {
				 image = [UIImage imageWithData:imageData];
			 }
			 UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
#endif
			 if (imageQuality < 0.99) {
				 if (!image) {
					 image = [UIImage imageWithData:imageData];
				 }
				 imageData = UIImageJPEGRepresentation(image, imageQuality);
			 }
			 NSData* dataToUpload = imageData;
			 [self upload:[NSDictionary dictionaryWithObjectsAndKeys:meta, @"meta",dataToUpload, @"data", serverAddress, @"serverAddress", nil]];
		 }];
	}
	
}
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock
     didReceiveData:(NSData *)data
            withTag:(long)tag
           fromHost:(NSString *)host
               port:(UInt16)port{
	[self log:[NSString stringWithFormat:@"didReceiveData %ld port %d", tag, port]];
	if (port == SOURCE_PORT) {
		[self command:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
	}
	[socket receiveWithTimeout:-1 tag:0];
	return YES;
}
- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error{
	[self log:[NSString stringWithFormat:@"didNotReceiveDataWithTag %ld %@", tag, error]];
}
-(void)clearReceivedData{
	self.statusLabel.text = @"";
}
- (void)requestFinished:(ASIHTTPRequest *)request{
	[self log:[NSString stringWithFormat:@"upload to %@ succeed.", [request.userInfo objectForKey:@"serverAddress"]]];
}
- (void)requestFailed:(ASIHTTPRequest *)request{
	
	[self log:[NSString stringWithFormat:@"upload to %@ failed. retry.", [request.userInfo objectForKey:@"serverAddress"]]];
	[self upload:request.userInfo];
	
	request.userInfo = nil;
}
@end
