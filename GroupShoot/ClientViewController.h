//
//  ClientViewController.h
//  GKSession
//
//  Created by Huizhe Xiao on 13-9-28.
//  Copyright (c) 2013年 Huizhe Xiao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClientViewController : UIViewController
@property (nonatomic, strong) IBOutlet UILabel* statusLabel;
@property (nonatomic, strong) IBOutlet UIView* previewView;
@property (nonatomic, strong) IBOutlet UITextView* log;
@end
