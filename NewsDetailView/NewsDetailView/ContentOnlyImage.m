//
//  ContentOnlyImage.m
//  NewsDetailView
//
//  Created by apple on 2017/10/27.
//  Copyright © 2017年 jerei. All rights reserved.
//

#import "ContentOnlyImage.h"
#import <SDWebImageManager.h>
#import <JavaScriptCore/JavaScriptCore.h>

#define SCREENHEIGHT  ([UIScreen mainScreen].bounds.size.height)
#define SCREENWIDTH   ([UIScreen mainScreen].bounds.size.width)

@interface ContentOnlyImage ()<UIWebViewDelegate>{
    UIWebView *webView;
    NSArray *arr;
}

@end

@implementation ContentOnlyImage

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    arr = @[@"http://photo.6ag.cn/2016-07-31/260dcf146930fd16a1ab6dc268b59067.jpg",@"http://photo.6ag.cn/2016-07-31/9a321051523991486c641cebb6b26e06.jpg",@"http://photo.6ag.cn/2016-07-31/af1aea083e0e3b5b779ea89851582f35.jpg",@"http://photo.6ag.cn/2016-07-31/b185e3142413d67c43fb46d362331777.jpg"];
    webView = [[UIWebView alloc]initWithFrame:CGRectMake(10, 10, SCREENWIDTH-20, SCREENHEIGHT-20)];
    webView.delegate = self;
    //webView.scrollView.bounces = NO;
    //webView.scrollView.scrollEnabled = NO;
    webView.scrollView.showsVerticalScrollIndicator = NO;
    webView.scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:webView];
    [self composeContent];
}

- (void)composeContent{
    // 加载中的占位图
    NSMutableString *conStr = [NSMutableString new];
    int i = 0;
    for (NSString *str in arr) {
        [conStr appendString:@"<p>"];
        NSString *loading = [[NSBundle mainBundle] pathForResource:@"loading.jpg" ofType:nil];
        // img标签
        NSString *imgTag = [NSString stringWithFormat:@"<img src='%@' class='%@' id='%d' width='%f' height='%f' onclick='imgclick(this.id)'/>", loading, str, i, SCREENWIDTH, 100.0];
        [conStr appendString:imgTag];
        [conStr appendString:@"</p>"];
        i++;
    }
    NSString *htmlStr = [NSString stringWithString:conStr];
    //去本地html模板
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"article.html" ofType:nil];
    NSString *template = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
    //数据替换到模板中
    htmlStr = [template stringByReplacingOccurrencesOfString:@"<p>mainnews</p>" withString:htmlStr options:NSCaseInsensitiveSearch range:[template rangeOfString:@"<p>mainnews</p>"]];
    NSURL *baseURL = [NSURL fileURLWithPath:templatePath];
    //加载
    [webView loadHTMLString:htmlStr baseURL:baseURL];

}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [self loadImages];
    JSContext *jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //点击加载出来的图片
    jsContext[@"ocimgclick"] = ^(){
        NSArray *args = [JSContext currentArguments];
        if (args.count) {
            NSString *urlStr = [args[0] toString];
            NSLog(@"点击图片的地址:%@",urlStr);
        }
    };
    jsContext[@"resizewebview"]= ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resizeWebview];
        });
    };
}
- (void)resizeWebview
{
    NSString * clientheight_str = [webView stringByEvaluatingJavaScriptFromString: @"document.body.offsetHeight;"];
    //float clientheight = [clientheight_str floatValue];
    webView.frame = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT);
    //你的tableview
    //self.m_tableview.tableHeaderView = contentWebView;
}
- (void)loadImages{
    for (NSString *imageUrl in arr) {
        [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:imageUrl] options:SDWebImageRetryFailed progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
            if (image) {//如果下载成功
                NSString *imgB64 = [UIImageJPEGRepresentation(image, 1.0) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                //把图片在磁盘中的地址传回给JS
                NSString *source = [NSString stringWithFormat:@"data:image/png;base64,%@", imgB64];
                NSString *imageW = [NSString stringWithFormat:@"%f",SCREENWIDTH];
                NSString *imageH = [NSString stringWithFormat:@"%f",SCREENWIDTH/image.size.width*image.size.height];
                JSValue *callback = context[@"replaceImgDecodeData"];
                NSArray *arguments =@[imageURL.absoluteString,source,imageW,imageH];
                [callback callWithArguments:arguments];
            }
        }];
    }
    
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

@end
