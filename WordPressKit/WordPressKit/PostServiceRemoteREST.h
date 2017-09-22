#import <Foundation/Foundation.h>
#import "PostServiceRemote.h"
#import "SiteServiceRemoteWordPressComREST.h"

@interface PostServiceRemoteREST : SiteServiceRemoteWordPressComREST <PostServiceRemote>

/**
 *  @brief      Autosaves the post.
 *
 *  @param      post        The post to autosave. Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)autosave:(RemotePost *)post
         success:(void (^)(RemotePost *post))success
         failure:(void (^)(NSError *error))failure;

@end
