#import <UIKit/UIKit.h>

@class Blog;
@class WPAccount;

#pragma mark - WPWebViewController

@interface WPWebViewController : UIViewController<UIWebViewDelegate>

/**
 *	@brief		Represents the Endpoint URL to render
 */
@property (nonatomic, strong) NSURL     *url;

/**
 *	@brief		Optionally scrolls the endpoint to the bottom of the screen, automatically.
 */
@property (nonatomic, assign) BOOL      shouldScrollToBottom;

/**
 *	@brief		Optionally suppresses navigation and sharing
 */
@property (nonatomic, assign) BOOL      secureInteraction;

/**
 *  @brief  When true adds a custom referrer to NSURLRequest.
 */
@property (nonatomic, assign) BOOL addsWPComReferrer;

/**
 *	@brief		Dismiss modal presentation
 */
- (IBAction)dismiss;

- (void)authenticateWithBlog:(Blog *)blog;
- (void)authenticateWithAccount:(WPAccount *)account;

/**
 *	@brief      Helper method to initialize a WebViewController Instance
 *
 *	@param		url         The URL that needs to be rendered
 *  @returns                A WPWebViewController instance ready to be pushed.
 */
+ (instancetype)webViewControllerWithURL:(NSURL *)url;

/**
 *	@brief      Helper method to initialize a WebViewController Instance with a 
 *              custom options button
 *
 *	@param		url         The URL that needs to be rendered
 *  @param      button      A custom options button to display instead of the
 *                          default share button.
 *  @returns                A WPWebViewController instance ready to be pushed.
 */
+ (instancetype)webViewControllerWithURL:(NSURL *)url
                           optionsButton:(UIBarButtonItem *)button;

@end
