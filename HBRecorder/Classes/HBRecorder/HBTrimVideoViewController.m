//
//  HBTrimVideoViewController.m
//  Pods
//
//  Created by Arjav Lad on 05/07/17.
//
//

#import "HBTrimVideoViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "HBRecorder.h"

@interface HBTrimVideoViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, ICGVideoTrimmerDelegate>

@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat stopTime;
@property (strong, nonatomic) NSString *tempVideoPath;

@property (strong, nonatomic) TrimmingCompletion completion;

@end

@implementation HBTrimVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpMov.mov"];
    
    self.trimmerView.minLength = 3;
    self.trimmerView.maxLength = 60;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)onSave:(UIButton *)sender {
    CGSize naturalSize = [[self.asset tracksWithMediaType:AVMediaTypeVideo][0] naturalSize];
    self.exportSession = [[AVAssetExportSession alloc] initWithAsset:self.asset presetName:AVAssetExportPreset640x480] ;
    self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    if (self.videoPlayerView.xrate != -1){
        [self applyCropToVideoWithAsset:self.asset AtRect:CGRectMake(naturalSize.width * self.videoPlayerView.xrate, 0,self.view.frame.size.width, self.view.frame.size.height) OnTimeRange:self.videoPlayerView.range ExportToUrl:[NSURL fileURLWithPath:self.tempVideoPath] ExistingExportSession:self.exportSession needCrop:YES];
    } else {
        [self applyCropToVideoWithAsset:self.asset AtRect:CGRectNull OnTimeRange:self.videoPlayerView.range ExportToUrl:[NSURL fileURLWithPath:self.tempVideoPath] ExistingExportSession:self.exportSession needCrop:NO];
    }
    
}

- (IBAction)onBack:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
//            self.completion(NO, [NSError errorWithDomain:@"Trimming Cancelled by user." code:404 userInfo:nil], nil);
        });
    }];
}

- (void)startTrimmingWith:(AVAsset *)asset
               completion:(TrimmingCompletion)comp {
    self.completion = comp;
    [self deleteOtherFiles:[NSURL URLWithString:self.tempVideoPath]];
    
    self.asset = asset;
    
    // set properties for trimmer view
    [self.trimmerView setThemeColor:[UIColor orangeColor]];
    [self.trimmerView setAsset:self.asset];
    [self.trimmerView setShowsRulerView:YES];
    [self.trimmerView setDelegate:self];
    [self.trimmerView setThumbWidth:15];
    
    // important: reset subviews
    [self.trimmerView resetSubviews];
    [self.videoPlayerView setVideoAsset:self.asset];
}

+ (void)trimVideo:( AVAsset * _Nonnull )asset
               on:( UIViewController * _Nonnull )onVC
       completion:(_Nonnull TrimmingCompletion)comp {
    NSBundle *bundle = [NSBundle bundleForClass:HBRecorder.class];
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"HBRecorder.bundle/HBRecorder" bundle:bundle];
    HBTrimVideoViewController *vc = (HBTrimVideoViewController *)[story instantiateViewControllerWithIdentifier:@"HBTrimVideoViewController"];
    if (vc) {
        [onVC presentViewController:vc animated:YES
                         completion:^{
                             
                         }];
        [vc startTrimmingWith:asset completion:^(BOOL success, NSError * _Nullable error, NSURL * _Nullable videoUrl) {
            dispatch_async(dispatch_get_main_queue(), ^{
                comp(success, error.copy, videoUrl.copy);
                [vc dismissViewControllerAnimated:YES completion:^{
                    
                }];
            });
        }];
    } else {
        comp(NO, [NSError errorWithDomain:@"Error found!" code:404 userInfo:nil], nil);
    }
}


#pragma mark - ICGVideoTrimmerDelegate

- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime {
    self.startTime = startTime;
    self.stopTime = endTime;
    [self.videoPlayerView refreshTimePeriod:startTime end:endTime];
}

- (void)deleteOtherFiles:(NSURL *) url{
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        if ([file isEqualToString:@"tmpMov.mov"] || [[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] isEqualToString:[url absoluteString]]){
            continue;
        }
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
}

- (void)deleteTempFile {
    NSURL *url = [NSURL fileURLWithPath:self.tempVideoPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:url error:&err];
        NSLog(@"file deleted");
        if (err) {
            NSLog(@"file remove error, %@", err.localizedDescription );
        }
    } else {
        NSLog(@"no file by that name");
    }
}

- (AVAssetExportSession*)applyCropToVideoWithAsset:(AVAsset*)asset AtRect:(CGRect)cropRect OnTimeRange:(CMTimeRange)cropTimeRange ExportToUrl:(NSURL*)outputUrl ExistingExportSession:(AVAssetExportSession*)exporter needCrop:(BOOL)needOrNot {
    
    //Remove any prevouis videos at that path
    [[NSFileManager defaultManager]  removeItemAtURL:outputUrl error:nil];
    
    if (needOrNot){
        //create an avassetrack with our asset
        AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        //create a video composition and preset some settings
        AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.frameDuration = CMTimeMake(1, 30);
        
        CGFloat cropOffX = cropRect.origin.x;
        CGFloat cropOffY = cropRect.origin.y;
        CGFloat cropWidth = cropRect.size.width;
        CGFloat cropHeight = cropRect.size.height;
        
        videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight);
        
        //create a video instruction
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = cropTimeRange;
        
        AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
        
        UIImageOrientation videoOrientation = [self getVideoOrientationFromAsset:asset];
        
        CGAffineTransform t1 = CGAffineTransformIdentity;
        CGAffineTransform t2 = CGAffineTransformIdentity;
        
        switch (videoOrientation) {
                /*        case UIImageOrientationUp:
                 t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height - cropOffX, 0 - cropOffY );
                 t2 = CGAffineTransformRotate(t1, M_PI_2 );
                 break;
                 case UIImageOrientationDown:
                 t1 = CGAffineTransformMakeTranslation(0 - cropOffX, clipVideoTrack.naturalSize.width - cropOffY ); // not fixed width is the real height in upside down
                 t2 = CGAffineTransformRotate(t1, - M_PI_2 );
                 break;
                 */
            case UIImageOrientationRight:
                t1 = CGAffineTransformMakeTranslation(0 - cropOffX, 0 - cropOffY );
                t2 = CGAffineTransformRotate(t1, 0 );
                break;
            case UIImageOrientationLeft:
                t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.width - cropOffX, clipVideoTrack.naturalSize.height - cropOffY );
                t2 = CGAffineTransformRotate(t1, M_PI  );
                break;
            default:
                NSLog(@"no need to crop");
                break;
        }
        
        CGAffineTransform finalTransform = t2;
        [transformer setTransform:finalTransform atTime:kCMTimeZero];
        
        //add the transformer layer instructions, then add to video composition
        instruction.layerInstructions = [NSArray arrayWithObject:transformer];
        videoComposition.instructions = [NSArray arrayWithObject: instruction];
        
        // assign all instruction for the video processing (in this case the transformation for cropping the video
        exporter.videoComposition = videoComposition;
    }
    
    self.exportSession.timeRange = self.videoPlayerView.range;
    
    if (outputUrl) {
        exporter.outputURL = outputUrl;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([exporter status]) {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"crop Export failed: %@", [[exporter error] localizedDescription]);
                    if (self.completion){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.completion(NO,[exporter error],nil);
                        });
                        return;
                    }
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"crop Export canceled");
                    if (self.completion){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.completion(NO,nil,nil);
                        });
                        return;
                    }
                    break;
                default:
                    NSLog(@"seccessfully complete");
                    break;
            }
            
            if (self.completion){
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.completion(YES,nil,outputUrl);
                });
            }
            
        }];
    } else {
        if (self.completion){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completion(NO, [NSError errorWithDomain:@"Trimming Failed" code:404 userInfo:nil], nil);
            });
        }
    }
    
    return exporter;
}

- (UIImageOrientation)getVideoOrientationFromAsset:(AVAsset *)asset {
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return UIImageOrientationLeft; //return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIImageOrientationRight; //return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIImageOrientationDown; //return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIImageOrientationUp;  //return UIInterfaceOrientationPortrait;
}


@end
