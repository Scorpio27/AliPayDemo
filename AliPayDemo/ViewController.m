//
//  ViewController.m
//  AliPayDemo
//
//  Created by Apple on 16/8/15.
//  Copyright © 2016年 iMac. All rights reserved.
//

#import "ViewController.h"
#import <AlipaySDK/AlipaySDK.h>
#import "Order.h"
#import "DataSigner.h"

@implementation Product

@end

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *productTableView;

@property(nonatomic, strong)NSMutableArray *productList;

@property (weak, nonatomic) IBOutlet UIButton *payButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"支付宝支付";
    self.navigationController.navigationBar.barTintColor = [UIColor orangeColor];
    
    if ([[UIDevice currentDevice].systemVersion floatValue]>=7.0?YES:NO) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    _productTableView.delegate = self;
    _productTableView.dataSource = self;
    _productTableView.rowHeight = 55;
//    _productTableView.bounces = NO;
    
    _payButton.backgroundColor = [UIColor colorWithRed:81.0f/255.0f green:141.0f/255.0f blue:229.0f/255.0f alpha:1.0f];
    _payButton.tintColor = [UIColor whiteColor];
    _payButton.layer.masksToBounds = YES;
    _payButton.layer.cornerRadius = 4.0f;
    
    [self generateData];
    
}

#pragma mark ==============产生随机订单号==============

- (NSString *)generateTradeNO
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned)time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
    
}

#pragma mark   ===============产生订单信息===============

-(void)generateData{
    NSArray *subjects = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7"];
    NSArray *bodys = @[@"土豪金iPhone6 Plus",@"玫瑰金iPhone6s Plus",@"只要999,iMac抱回家",@"Applewatch装x神器",@"充电5分钟，通话两小时",@"索尼大法好，买买买",@"三星盖乐世S7 Edge"];
    if (nil == self.productList) {
        _productList = [[NSMutableArray alloc] init];
    }else{
        [_productList removeAllObjects];
    }
    for (int i = 0; i < subjects.count; i++) {
        Product *prodcut = [[Product alloc] init];
        prodcut.subject = [subjects objectAtIndex:i];
        prodcut.body = [bodys objectAtIndex:i];
        prodcut.price = 0.01f + pow(7, i-2);
        [_productList addObject:prodcut];
        
    }
}

#pragma mark ==============UITableViewDelegate==============

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _productList.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellIDentifier = @"cellIDentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIDentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIDentifier];
    }
    
    Product *product = _productList[indexPath.row];
    cell.textLabel.text = product.body;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"一口价:%.2f",product.price];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    return cell;

}

#pragma mark   ==============点击订单模拟支付行为==============

//选中商品调用支付宝极简支付
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //点击获取prodcut实例并初始化订单信息
    Product *product = _productList[indexPath.row];
    
    /*
     *重要说明
     *这里只是为了方便直接向商户展示支付宝的整个支付流程,所以Demo中加签过程直接放在客户端完成
     *真实App里,privateKey等数据严禁放在客户端,加签过程务必要放在服务端完成
     *防止商户私密数据泄露,造成不必要的资金损失,及面临各种安全风险
     */
    //partnerID和sellerID获取失败时
    if ([partnerID length] == 0 || [sellerID length] == 0 || [partnerPrivateKey length] == 0) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"缺少appId或者seller或者私钥" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        }];
        
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    //==========生成订单信息及签名==========
    
    //将商品信息赋予AlixPayOrder的成员变量
    Order *order = [[Order alloc] init];
    order.app_id = partnerID;//商户ID
    order.method = @"alipay.trade.app.pay";//支付接口名称
    order.charset = @"utf-8";//参数编码格式
    
    //当前时间点
    NSDate *date = [[NSDate alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    order.timestamp = [formatter stringFromDate:date];
    
    order.version = @"1.0";//支付版本
    order.sign_type = @"RSA";//sign_type设置
    
    //商品数据
    order.biz_content = [[BizContent alloc] init];
    order.biz_content.seller_id = sellerID;//账户ID
    order.biz_content.body = product.body;//商品描述
    order.biz_content.subject = product.subject;//商品标题
    order.biz_content.out_trade_no = [self generateTradeNO];//订单ID（由商家自行制定）
    order.biz_content.timeout_express = @"30m";//超时时间设置
    order.biz_content.total_amount = [NSString stringWithFormat:@"%.2f",product.price];//商品价格
    
    //将商品信息拼接成字符串
    NSString *orderInfo = [order orderInfoEncoded:NO];
    NSString *orderInfoEncoded = [order orderInfoEncoded:YES];
    NSLog(@"orderSpec = %@",orderInfo);
    
    //获取私钥并将商户信息签名，外部商户的加签过程请务必放在服务端，防止公私钥数据泄露；需要遵循RSA签名规范，并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(partnerPrivateKey);
    NSString *signedString = [signer signString:orderInfo];
    
    //如果加签成功，则继续执行支付
    if (signedString != nil) {
        //应用注册scheme,在AliSDKDemo-Info.plist定义URL types,用于快捷支付成功后重新唤起商户应用
        NSString *appScheme = @"AliPayDemo";
        
        //将签名成功字符串格式化为订单字符串,请严格按照该格式
        NSString *orderString = [NSString stringWithFormat:@"%@&sign=%@",orderInfoEncoded,signedString];
        
        //调用支付结果开始支付
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            
            NSLog(@"resultDic = %@",resultDic);
            
            // 返回结果需要通过 resultStatus 以及 result 字段的值来综合判断并确定支付结果。 在 resultStatus=9000,并且 success="true"以及 sign="xxx"校验通过的情况下,证明支付成功。其它情况归为失败。较低安全级别的场合,也可以只通过检查 resultStatus 以及 success="true"来判定支付结果
            if (resultDic && [resultDic objectForKey:@"resultStatus"] && ([[resultDic objectForKey:@"resultStatus"] intValue] == 9000)) {
                //支付成功
            }else{
                //支付失败
            }
        }];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

#pragma mark ==============方法2==============

//服务器上生成订单,拼接字符串和签名,返回一个加密过的参数
- (IBAction)payButton:(id)sender {

    NSString *appScheme = @"AliPayDemo";
    NSString *str = @"partner=\"2088911310309131\"&seller_id=\"2088911310309131\"&out_trade_no=\"062ef92e-f00f-49d9-a46e-4adb1e726c98\"&subject=\"易掌管APP用户支付订单\"&body=\"易掌管APP用户支付订单\"&total_fee=\"0.01\"&notify_url=\"http://121.40.85.110:9060/v1/alipay/instantcredit/async\"&service=\"mobile.securitypay.pay\"&payment_type=\"1\"&_input_charset=\"utf-8\"&it_b_pay=\"1d\"&return_url=\"http://121.40.85.110:9060/v1/alipay/instantcredit/sync\"&sign=\"K6w0%2F7C5N9otlRAMIFP128fRoXGKaCmiYarpCI9h%2BckCaBSSpfGqYscKN4hCVbgzfQPQeUP34ERQ%2F%2FP3ROqDGQt2ak5YqOaevXVGBP558qIp2ujyINSz6WoTUTC7EL%2BI6GLUGg6O0k3Cm2QAphO%2FwiBMbtIskTFt3aiH7rUK2yQ%3D\"&sign_type=\"RSA\"";
    
    [[AlipaySDK defaultService] payOrder:str fromScheme:appScheme callback:^(NSDictionary *resultDic) {
        NSLog(@"resultDic = %@",resultDic);
        
        if ([resultDic[@"resultStatus"] isEqual:@"9000"]) {
            //支付成功
        }
        else if ([resultDic[@"resultStatus"] isEqual:@"8000"]) {
            //正在处理中
        }
        else if ([resultDic[@"resultStatus"] isEqual:@"4000"]) {
            //订单支付失败
        }
        else if ([resultDic[@"resultStatus"] isEqual:@"6001"]) {
            //您已中途取消支付
        }
        else if ([resultDic[@"resultStatus"] isEqual:@"6002"]) {
            //您的网络连接出错
        }
        else {
           //支付失败
        }
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
