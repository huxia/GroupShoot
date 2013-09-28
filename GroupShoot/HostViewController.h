//
//  HostViewController.h
//  GKSession
//
//  Created by Huizhe Xiao on 13-9-28.
//  Copyright (c) 2013年 Huizhe Xiao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HostViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITextField* serverAddress;
@property (nonatomic, strong) IBOutlet UITableView* clients;
@property (nonatomic, strong) IBOutlet UISlider* imageQuality;
-(IBAction)send:(id)sender;
@end
