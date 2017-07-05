//
//  HBTrimVideoViewController.h
//  Pods
//
//  Created by Arjav Lad on 05/07/17.
//
//

#import <UIKit/UIKit.h>
#import "ICGVideoTrimmer.h"
#import "ICGVideoPlayerView.h"

typedef void(^TrimmingCompletion)(BOOL success, NSError* _Nullable error, NSURL* _Nullable videoUrl);

@interface HBTrimVideoViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *lblDuration;
@property (weak, nonatomic) IBOutlet UIButton *btnSave;
@property (weak, nonatomic) IBOutlet ICGVideoPlayerView *videoPlayerView;
@property (weak, nonatomic) IBOutlet ICGVideoTrimmerView *trimmerView;

@property (strong, nonatomic) AVAsset *asset;

+ (void)trimVideo:( AVAsset * _Nonnull )asset
               on:( UIViewController * _Nonnull )onVC
       completion:(_Nonnull TrimmingCompletion)comp;
@end
