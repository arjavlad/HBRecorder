//
//  HBEditVideoViewController.h
//  HBRecorder
//
//  Created by HilalB on 11/07/2016.
//  Copyright (c) 2016 HilalB. All rights reserved.
//

#import "HBEditVideoViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "SCVideoPlayerView.h"
#import "HBTrimVideoViewController.h"

@interface HBEditVideoViewController ()<SCVideoPlayerViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource> {
    NSMutableArray *_thumbnails;
    NSInteger _currentSelected;
}

@end

@implementation HBEditVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoPlayerView.tapToPauseEnabled = YES;
    self.videoPlayerView.player.loopEnabled = YES;
    self.videoPlayerView.delegate = self;
    [self.collectionView reloadData];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)togglePlayPauseBtn {
    
    if(self.videoPlayerView.player.isPlaying) {
        //To hide
        [UIView animateWithDuration:0.25 animations:^{
            [_playPauseImageView setAlpha:0.1f];
        } completion:^(BOOL finished) {
            _playPauseImageView.hidden = YES;
        }];
    } else {
        //To Show
        _playPauseImageView.hidden = NO;
        _playPauseImageView.alpha = 0.1;
        [UIView animateWithDuration:0.25 animations:^{
            _playPauseImageView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            
        }];
        
    }
}

#pragma mark-  SCVideoPlayerViewDelegate
- (void)videoPlayerViewTappedToPlay:(SCVideoPlayerView *__nonnull)videoPlayerView {
    [self togglePlayPauseBtn];
}

- (void)videoPlayerViewTappedToPause:(SCVideoPlayerView *__nonnull)videoPlayerView {
    [self togglePlayPauseBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //    self.navigationController.navigationBar.hidden = YES;
    
    //    _scrollView.frame = CGRectMake(_scrollView.frame.origin.x, _scrollView.frame.origin.y, _scrollView.frame.size.width , 110);
    
    //    NSMutableArray *thumbnails = [NSMutableArray new];
    //    NSInteger i = 0;
    
    //    for (SCRecordSessionSegment *segment in self.recordSession.segments) {
    //        UIImageView *imageView = [[UIImageView alloc] init];
    //        imageView.contentMode = UIViewContentModeScaleAspectFit;
    //        imageView.image = segment.thumbnail;
    //        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchedVideo:)];
    //        imageView.userInteractionEnabled = YES;
    //
    //        [imageView addGestureRecognizer:tapGesture];
    //
    //        [thumbnails addObject:imageView];
    //
    //        [self.scrollView addSubview:imageView];
    //
    //        i++;
    //    }
    //
    //    _thumbnails = thumbnails;
    //
    [self reloadScrollView];
    [self showVideo:0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self togglePlayPauseBtn];
    [self.videoPlayerView.player pause];
}

- (void)touchedVideo:(UITapGestureRecognizer *)gesture {
    NSInteger idx = [_thumbnails indexOfObject:gesture.view];
    [self showVideo:idx];
}

- (void)handleTrimmedVideoURL:(NSURL *)videoURL {
    if (_currentSelected < self.recordSession.segments.count) {
        SCRecordSessionSegment *segment = [[SCRecordSessionSegment alloc] initWithURL:videoURL info:nil];
        if (segment) {
            [self.recordSession removeSegmentAtIndex:_currentSelected deleteFile:YES];
            [self.recordSession insertSegment:segment atIndex:_currentSelected];
        }
    }
}

- (void)showVideo:(NSInteger)idx {
    if (idx < 0) {
        idx = 0;
    }
    
    if (idx < _recordSession.segments.count) {
        SCRecordSessionSegment *segment = [_recordSession.segments objectAtIndex:idx];
        [self.videoPlayerView.player setItemByAsset:segment.asset];
        [self.videoPlayerView.player play];
        [self togglePlayPauseBtn];
    } else {
        [self.videoPlayerView.player pause];
        [UIView animateWithDuration:0.25 animations:^{
            [_playPauseImageView setAlpha:0.1f];
        } completion:^(BOOL finished) {
            _playPauseImageView.hidden = YES;
        }];
    }
    
    _currentSelected = idx;
    
    for (NSInteger i = 0; i < _thumbnails.count; i++) {
        UIImageView *imageView = [_thumbnails objectAtIndex:i];
        
        imageView.alpha = i == idx ? 1 : 0.5;
    }
}

- (void)reloadScrollView {
    [self.collectionView reloadData];
    int totalSeconds = CMTimeGetSeconds(_recordSession.duration);
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    
    self.lblClipsDuration.text = [NSString stringWithFormat:@"%02d:%02d",minutes, seconds];
    self.lblClipsCounter.text =  @(_recordSession.segments.count).stringValue;
    return;
    
    CGFloat cellSize = self.scrollView.frame.size.height;
    
    int i = 0;
    
    float imgWidth = 0;
    
    for (UIImageView *imageView in _thumbnails) {
        
        if (!imgWidth) {
            float oldHeight = imageView.image.size.height;
            float scaleFactor = cellSize / oldHeight;
            float newWidth = imageView.image.size.width* scaleFactor;
            
            imgWidth = newWidth;
        }
        
        
        imageView.frame = CGRectMake(imgWidth * i, 0, imgWidth, cellSize);
        i++;
    }
    self.scrollView.contentSize = CGSizeMake(_thumbnails.count * imgWidth, self.scrollView.frame.size.height);
}

- (IBAction)deletePressed:(id)sender {
    if (_currentSelected < _recordSession.segments.count) {
        [_recordSession removeSegmentAtIndex:_currentSelected deleteFile:YES];
        [self reloadScrollView];
        [self showVideo:_currentSelected % _recordSession.segments.count];
        //        UIImageView *imageView = [_thumbnails objectAtIndex:_currentSelected];
        //        [_thumbnails removeObjectAtIndex:_currentSelected];
        //        [UIView animateWithDuration:0.3 animations:^{
        //            imageView.transform = CGAffineTransformMakeScale(0, 0);
        //            [self reloadScrollView];
        //        } completion:^(BOOL finished) {
        //            [imageView removeFromSuperview];
        //        }];
        
    }
}

- (IBAction)addPressed:(id)sender {
    
    [self startMediaBrowser];
    
}

- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)trimPressed:(UIButton *)sender {
    if (_currentSelected < self.recordSession.segments.count) {
        SCRecordSessionSegment *segment = [_recordSession.segments objectAtIndex:_currentSelected];
        if (segment.asset) {
            [HBTrimVideoViewController trimVideo:segment.asset.copy
                                              on:self
                                      completion:^(BOOL success, NSError *error, NSURL *videoUrl) {
                                          dispatch_async(dispatch_get_main_queue(), ^{

                                              if (success && !error && videoUrl) {
                                                  [self handleTrimmedVideoURL:videoUrl.copy];
                                              } else {
                                                  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error!" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                                                  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                      
                                                  }]];
                                                  [self presentViewController:alert animated:YES completion:^{
                                                      
                                                  }];
                                              }
                                          });
                                      }];
        }
    }
}

- (BOOL)startMediaBrowser {
    //Validations
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO) {
        return NO;
    }
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    mediaUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    
    mediaUI.allowsEditing = YES;
    mediaUI.delegate = self;
    
    [self presentViewController:mediaUI animated:YES completion:nil];
    return YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSURL *url = info[UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    SCRecordSessionSegment *segment = [SCRecordSessionSegment segmentWithURL:url info:nil];
    [_recordSession addSegment:segment];
    [self reloadScrollView];
}


#pragma mark- CollectionView Delegate and Datasource Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.recordSession.segments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoThumbClnViewCell" forIndexPath:indexPath];
    SCRecordSessionSegment *segment = self.recordSession.segments[indexPath.item];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:111];
    imageView.image = segment.thumbnail;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self showVideo:indexPath.item];
}

@end
