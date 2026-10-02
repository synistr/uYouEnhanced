#import "uYouPlus.h"

// uYou AdBlock Workaround LITE (This Version will only remove ads from only Videos/Shorts!) - @PoomSmart
%group uYouAdBlockingWorkaroundLite
%hook YTHotConfig
- (BOOL)disableAfmaIdfaCollection { return NO; }
%end
%hook YTIPlayerResponse
%new(@@:)
- (NSMutableArray *)playerAdsArray {
    return [NSMutableArray array];
}
%new(@@:)
- (NSMutableArray *)adSlotsArray {
    return [NSMutableArray array];
}
%end

%hook YTIClientMdxGlobalConfig
%new(B@:)
- (BOOL)enableSkippableAd { return YES; }
%end

%hook YTHotConfig
- (BOOL)clientInfraClientConfigIosEnableFillingEncodedHacksInnertubeContext { return NO; }
%end

%hook YTAdShieldUtils
+ (id)spamSignalsDictionary { return @{}; }
+ (id)spamSignalsDictionaryWithoutIDFA { return @{}; }
%end

%hook YTDataUtils
+ (id)spamSignalsDictionary { return @{ @"ms": @"" }; }
+ (id)spamSignalsDictionaryWithoutIDFA { return @{}; }
%end

%hook YTAdsInnerTubeContextDecorator
- (void)decorateContext:(id)context {
    %orig(nil);
}
%end

%hook YTAccountScopedAdsInnerTubeContextDecorator
- (void)decorateContext:(id)context {
    %orig(nil);
}
%end

%hook YTLocalPlaybackController
- (id)createAdsPlaybackCoordinator { return nil; }
%end

%hook MDXSession
- (void)adPlaying:(id)ad {}
%end

%hook YTReelInfinitePlaybackDataSource
- (YTReelModel *)makeContentModelForEntry:(id)entry {
    YTReelModel *model = %orig;
    if ([model respondsToSelector:@selector(videoType)] && model.videoType == 3)
        return nil;
    return model;
}
%end
%end

// uYou AdBlock Workaround (Note: disables uYou's "Remove YouTube Ads" YouTube-X Option) - @PoomSmart, @arichornlover & @Dodieboy
%group uYouAdBlockingWorkaround
// Workaround: uYou 3.0.3 Adblock fix
%hook YTHotConfig
- (BOOL)disableAfmaIdfaCollection { return NO; }
%end
%hook YTIPlayerResponse
%new(@@:)
- (NSMutableArray *)playerAdsArray {
    return [NSMutableArray array];
}
%new(@@:)
- (NSMutableArray *)adSlotsArray {
    return [NSMutableArray array];
}
%end
%hook YTIClientMdxGlobalConfig
%new(B@:)
- (BOOL)enableSkippableAd { return YES; }
%end
%hook YTHotConfig
- (BOOL)clientInfraClientConfigIosEnableFillingEncodedHacksInnertubeContext { return NO; }
%end
%hook YTAdShieldUtils
+ (id)spamSignalsDictionary { return @{}; }
+ (id)spamSignalsDictionaryWithoutIDFA { return @{}; }
%end
%hook YTDataUtils
+ (id)spamSignalsDictionary { return @{ @"ms": @"" }; }
+ (id)spamSignalsDictionaryWithoutIDFA { return @{}; }
%end
%hook YTLocalPlaybackController
- (id)createAdsPlaybackCoordinator { return nil; }
%end
%hook MDXSession
- (void)adPlaying:(id)ad {}
%end
%hook MDXSessionImpl
- (void)adPlaying:(id)ad {}
%end
// Shorts ads: video ads have videoType 3, non-video ads (e.g. product cards) carry ads custom data - @PoomSmart (YouTube-X)
static BOOL isAdsReelContentModel(YTReelContentModel *model) {
    if ([model respondsToSelector:@selector(videoType)])
        return ((YTReelModel *)model).videoType == 3;
    if ([model isKindOfClass:%c(YTReelNonVideoContentModel)]) {
        @try {
            id customData = [[(id)model valueForKey:@"renderer"] valueForKey:@"customData"];
            return [[customData description] containsString:@"YTIReelNonVideoAdsCustomData_reelNonVideoAdsCustomData"];
        } @catch (NSException *e) {}
    }
    return NO;
}
static void removeAdsReels(NSMutableOrderedSet <YTReelContentModel *> *reels) {
    if (![reels isKindOfClass:[NSMutableOrderedSet class]]) return;
    [reels removeObjectsAtIndexes:[reels indexesOfObjectsPassingTest:^BOOL(YTReelContentModel *obj, NSUInteger idx, BOOL *stop) {
        return isAdsReelContentModel(obj);
    }]];
}
%hook YTReelDataSource
- (YTReelContentModel *)makeContentModelForEntry:(id)entry {
    YTReelContentModel *model = %orig;
    return isAdsReelContentModel(model) ? nil : model;
}
// YouTube 21.x
- (void)setReels:(NSMutableOrderedSet <YTReelContentModel *> *)reels {
    removeAdsReels(reels);
    %orig;
}
%end
// YouTube 21.x builds Shorts models in a class method
%hook YTReelContentModel
+ (YTReelContentModel *)makeContentModelForEntry:(id)entry {
    YTReelContentModel *model = %orig;
    return isAdsReelContentModel(model) ? nil : model;
}
%end
%hook YTReelInfinitePlaybackDataSource
- (YTReelContentModel *)makeContentModelForEntry:(id)entry {
    YTReelContentModel *model = %orig;
    return isAdsReelContentModel(model) ? nil : model;
}
- (void)setReels:(NSMutableOrderedSet <YTReelContentModel *> *)reels {
    removeAdsReels(reels);
    %orig;
}
%end
static BOOL isProductList(YTICommand *command) {
    if ([command respondsToSelector:@selector(yt_showEngagementPanelEndpoint)]) {
        YTIShowEngagementPanelEndpoint *endpoint = [command yt_showEngagementPanelEndpoint];
        return [endpoint.identifier.tag isEqualToString:@"PAproduct_list"];
    }
    return NO;
}
%hook YTWatchNextResponseViewController
- (void)loadWithModel:(YTIWatchNextResponse *)model {
    YTICommand *onUiReady = model.onUiReady;
    if ([onUiReady respondsToSelector:@selector(yt_commandExecutorCommand)]) {
        YTICommandExecutorCommand *commandExecutorCommand = [onUiReady yt_commandExecutorCommand];
        NSMutableArray <YTICommand *> *commandsArray = commandExecutorCommand.commandsArray;
        [commandsArray removeObjectsAtIndexes:[commandsArray indexesOfObjectsPassingTest:^BOOL(YTICommand *command, NSUInteger idx, BOOL *stop) {
            return isProductList(command);
        }]];
    }
    if (isProductList(onUiReady))
        model.onUiReady = nil;
    %orig;
}
%end
%hook YTMainAppVideoPlayerOverlayViewController
- (void)playerOverlayProvider:(YTPlayerOverlayProvider *)provider didInsertPlayerOverlay:(YTPlayerOverlay *)overlay {
    if ([[overlay overlayIdentifier] isEqualToString:@"player_overlay_product_in_video"]) return;
    %orig;
}
%end
NSString *getAdString(NSString *description) {
    for (NSString *str in @[
        @"brand_promo",
        @"brand_video_shelf",
        @"carousel_footered_layout",
        @"carousel_headered_layout",
        @"eml.expandable_metadata",
        @"feed_ad_metadata",
        @"full_width_portrait_image_layout",
        @"full_width_square_image_layout",
        @"grid_ads_image_layout",
        @"landscape_image_wide_button_layout",
        @"post_shelf",
        @"product_carousel",
        @"product_engagement_panel",
        @"product_item",
        @"shopping_carousel",
        @"shopping_item_card_list",
        @"statement_banner",
        @"square_image_layout",
        @"text_image_button_layout",
        @"text_search_ad",
        @"video_display_full_layout",
        @"video_display_full_buttoned_layout"
    ])
        if ([description containsString:str]) return str;
    return nil;
}
static BOOL isAdRenderer(YTIElementRenderer *elementRenderer, int kind) {
    if ([elementRenderer respondsToSelector:@selector(hasCompatibilityOptions)] && elementRenderer.hasCompatibilityOptions && elementRenderer.compatibilityOptions.hasAdLoggingData) {
        HBLogDebug(@"YTX adLogging %d %@", kind, elementRenderer);
        return YES;
    }
    NSString *description = [elementRenderer description];
    NSString *adString = getAdString(description);
    if (adString) {
        HBLogDebug(@"YTX getAdString %d %@ %@", kind, adString, elementRenderer);
        return YES;
    }
    return NO;
}
static NSMutableArray <YTIItemSectionRenderer *> *filteredArray(NSArray <YTIItemSectionRenderer *> *array) {
    NSMutableArray <YTIItemSectionRenderer *> *newArray = [array mutableCopy];
    NSIndexSet *removeIndexes = [newArray indexesOfObjectsPassingTest:^BOOL(YTIItemSectionRenderer *sectionRenderer, NSUInteger idx, BOOL *stop) {
        if ([sectionRenderer isKindOfClass:%c(YTIShelfRenderer)]) {
            YTIShelfSupportedRenderers *content = ((YTIShelfRenderer *)sectionRenderer).content;
            YTIHorizontalListRenderer *horizontalListRenderer = content.horizontalListRenderer;
            NSMutableArray <YTIHorizontalListSupportedRenderers *> *itemsArray = horizontalListRenderer.itemsArray;
            NSIndexSet *removeItemsArrayIndexes = [itemsArray indexesOfObjectsPassingTest:^BOOL(YTIHorizontalListSupportedRenderers *horizontalListSupportedRenderers, NSUInteger idx2, BOOL *stop2) {
                YTIElementRenderer *elementRenderer = horizontalListSupportedRenderers.elementRenderer;
                return isAdRenderer(elementRenderer, 4);
            }];
            [itemsArray removeObjectsAtIndexes:removeItemsArrayIndexes];
        }
        if (![sectionRenderer isKindOfClass:%c(YTIItemSectionRenderer)])
            return NO;
        NSMutableArray <YTIItemSectionSupportedRenderers *> *contentsArray = sectionRenderer.contentsArray;
        if (contentsArray.count > 1) {
            NSIndexSet *removeContentsArrayIndexes = [contentsArray indexesOfObjectsPassingTest:^BOOL(YTIItemSectionSupportedRenderers *sectionSupportedRenderers, NSUInteger idx2, BOOL *stop2) {
                YTIElementRenderer *elementRenderer = sectionSupportedRenderers.elementRenderer;
                return isAdRenderer(elementRenderer, 3);
            }];
            [contentsArray removeObjectsAtIndexes:removeContentsArrayIndexes];
        }
        YTIItemSectionSupportedRenderers *firstObject = [contentsArray firstObject];
        YTIElementRenderer *elementRenderer = firstObject.elementRenderer;
        return isAdRenderer(elementRenderer, 2);
    }];
    [newArray removeObjectsAtIndexes:removeIndexes];
    return newArray;
}
// Like filteredArray, but also unwraps YTISectionListSupportedRenderers, as passed to the insert methods
static NSArray *filteredSections(NSArray *sections) {
    if (![sections isKindOfClass:[NSArray class]]) return sections;
    NSMutableArray *kept = [NSMutableArray array];
    for (id renderer in sections) {
        id section = renderer;
        if ([renderer isKindOfClass:%c(YTISectionListSupportedRenderers)] && ((YTISectionListSupportedRenderers *)renderer).itemSectionRenderer)
            section = ((YTISectionListSupportedRenderers *)renderer).itemSectionRenderer;
        if (filteredArray(@[section]).count) [kept addObject:renderer];
    }
    return kept;
}
%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;
    if (([self.accessibilityIdentifier isEqualToString:@"eml.expandable_metadata.vpp"]))
        [self removeFromSuperview];
}
%end
%hook YTInnerTubeCollectionViewController
- (void)displaySectionsWithReloadingSectionControllerByRenderer:(id)renderer {
    NSMutableArray *sectionRenderers = [self valueForKey:@"_sectionRenderers"];
    [self setValue:filteredArray(sectionRenderers) forKey:@"_sectionRenderers"];
    %orig;
}
- (void)addSectionsFromArray:(NSArray <YTIItemSectionRenderer *> *)array {
    %orig(filteredArray(array));
}
// YouTube 21.x also inserts and replaces sections after the feed has loaded (e.g. home feed ad slots)
- (BOOL)insertSections:(NSArray *)sections byPosition:(int)position error:(id *)error {
    NSArray *kept = filteredSections(sections);
    if (sections.count && !kept.count) return YES;
    return %orig(kept, position, error);
}
- (BOOL)insertSections:(NSArray *)sections byRelativePositionInSectionList:(id)list error:(id *)error {
    NSArray *kept = filteredSections(sections);
    if (sections.count && !kept.count) return YES;
    return %orig(kept, list, error);
}
- (void)insertBelowVisibleSection:(id)section {
    if (section && !filteredSections(@[section]).count) return;
    %orig;
}
- (void)replaceSectionController:(id)controller withItemSectionRenderer:(id)renderer {
    if (renderer && !filteredSections(@[renderer]).count) return;
    %orig;
}
%end
// Catch-all for ad elements arriving through any other path - @dayanch96 (YTLite)
%hook YTIElementRenderer
- (NSData *)elementData {
    if (self.hasCompatibilityOptions && self.compatibilityOptions.hasAdLoggingData) return nil;
    return %orig;
}
%end
%hook YTSectionListViewController
- (void)loadWithModel:(YTISectionListRenderer *)model {
    if ([model respondsToSelector:@selector(contentsArray)]) {
        NSMutableArray *contentsArray = model.contentsArray;
        [contentsArray removeObjectsAtIndexes:[contentsArray indexesOfObjectsPassingTest:^BOOL(YTISectionListSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
            id firstObject = renderers.itemSectionRenderer.contentsArray.firstObject;
            @try {
                for (NSString *key in @[@"hasPromotedVideoRenderer", @"hasCompactPromotedVideoRenderer", @"hasPromotedVideoInlineMutedRenderer"])
                    if ([[firstObject valueForKey:key] boolValue]) return YES;
            } @catch (NSException *e) {}
            return NO;
        }]];
    }
    %orig;
}
%end
%end

%ctor {
    if (IS_ENABLED(kAdBlockWorkaroundLite)) {
        %init(uYouAdBlockingWorkaroundLite);
    }
    if (IS_ENABLED(kAdBlockWorkaround)) {
        %init(uYouAdBlockingWorkaround);
    }
}
