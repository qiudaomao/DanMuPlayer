//
//  DMPlayerlist.h
//  DanMuPlayer
//
//  Created by zfu on 2018/1/5.
//  Copyright © 2018年 zfu. All rights reserved.
//

#ifndef DMPlaylist_h
#define DMPlaylist_h

@import JavaScriptCore;

/*-----------------------------------------------------------------------------*/
/*
 * DMMeidaItem
 * Each item contains a playable online media
 */
@protocol DMMediaItemJSB <JSExport>
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *description;
@property (nonatomic) CGFloat resumeTime;
@property (nonatomic) NSString *artworkImageURL;
@property (nonatomic) NSDictionary *options;
@property (nonatomic, assign) BOOL mp4;
@end

@interface DMMediaItem : NSObject<DMMediaItemJSB>
+(void)setup:(JSContext*)context;
@end


/*-----------------------------------------------------------------------------*/
/*
 * A DMPlaylist contains many DMMediaItem
 */
@protocol DMPlaylistJSB <JSExport>
-(void)push:(DMMediaItem*)item;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic) NSMutableArray<DMMediaItem*> *items;
@end

@interface DMPlaylist : NSObject<DMPlaylistJSB>
+(void)setup:(JSContext*)context;
@end



#endif /* DMPlaylist_h */
