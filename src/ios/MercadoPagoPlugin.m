#import "MercadoPagoPlugin.h"
@import MercadoPagoSDK;
@interface UIColor (fromHex)
+ (UIColor *)colorwithHexString:(NSString *)hexStr alpha:(CGFloat)alpha;
@end
@implementation UIColor (fromHex)

#define MERCADO_PAGO_BASE_COLOR @"#30AFE2"

+ (UIColor *)colorwithHexString:(NSString *)hexStr alpha:(CGFloat)alpha;
{
    //-----------------------------------------
    // Convert hex string to an integer
    //-----------------------------------------
    unsigned int hexint = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet
                                       characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&hexint];
    
    //-----------------------------------------
    // Create color object, specifying alpha
    //-----------------------------------------
    UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                     blue:((CGFloat) (hexint & 0xFF))/255
                    alpha:alpha];
    
    return color;
}

@end
@implementation MercadoPagoPlugin

- (void)startCheckout:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = [command callbackId];
    NSString* publicKey = [[command arguments] objectAtIndex:0];
    NSString* prefId = [[command arguments] objectAtIndex:1];
    
    [MercadoPagoContext setPublicKey:publicKey];
    
    if ([[command arguments] objectAtIndex:2]!= (id)[NSNull null]){
        UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:2] alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    } else {
        UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:100];
        [MercadoPagoContext setupPrimaryColor:color];
    }
    if ([[[command arguments] objectAtIndex:3]boolValue]){
        [MercadoPagoContext setDarkTextColor];
    }else {
        [MercadoPagoContext setLightTextColor];
    }
    
    UINavigationController *choFlow =[MPFlowBuilder startCheckoutViewController:prefId callback:^(Payment *payment) {
        NSString *mppayment = [payment toJSONString];
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString:mppayment];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    }callbackCancel:nil];
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    [rootViewController presentViewController:choFlow animated:YES completion:^{}];
    
}
- (void)getPaymentMethods:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    [MPServicesBuilder getPaymentMethods:^(NSArray<PaymentMethod *> *paymentMethods) {
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [self toString:paymentMethods]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    } failure:^(NSError *error) {
        
    }];
    
}
- (void)getIssuers:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    PaymentMethod *pm = [[PaymentMethod alloc]init];
    pm._id=@"visa";
    [MPServicesBuilder getIssuers:pm bin:nil success:^(NSArray<Issuer *> *issuers) {
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [self toString:issuers]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    } failure:^(NSError *error) {
        
    }];
    
}
- (void)getInstallments:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    Issuer *is =[[ Issuer alloc]init];
    
    is._id = [[NSNumber alloc] initWithInt:[[command arguments] objectAtIndex:3]];
    
    
    [MPServicesBuilder getInstallments:[[command arguments] objectAtIndex:2] amount:[[[command arguments] objectAtIndex:4] doubleValue ]issuer:is paymentMethodId:[[command arguments] objectAtIndex:1] success:^(NSArray<Installment *> *installments) {
        
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [self toString:installments]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    } failure:^(NSError * error) {
        
    }];
}
- (void)getIdentificationTypes:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    
    [MPServicesBuilder getIdentificationTypes:^(NSArray<IdentificationType *> * identificationTypes) {
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [self toString:identificationTypes]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    } failure:^(NSError * error) {
        
    }];
}
- (void)createToken:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    NSInteger expy = [[[command arguments] objectAtIndex:3] integerValue];
    NSInteger expm = [[[command arguments] objectAtIndex:2] integerValue];
    
    
    CardToken *cardToken =[[CardToken alloc]initWithCardNumber:[[command arguments] objectAtIndex:1] expirationMonth:expm expirationYear:expy securityCode:[[command arguments] objectAtIndex:4] cardholderName:[[command arguments] objectAtIndex:5] docType:[[command arguments] objectAtIndex:6] docNumber:[[command arguments] objectAtIndex:7]];
    
    //
    [MPServicesBuilder createNewCardToken:cardToken success:^(Token * token) {
        NSString *mpToken = [token toJSONString];
        // printf("token %s",[mpToken UTF8String]);
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: mpToken];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    } failure:^(NSError * error) {
        
        NSLog(@"error: %@ \n",[error localizedDescription]);
    }];
}
- (void)getBankDeals:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    [MPServicesBuilder getPromos:^(NSArray<Promo *> * promo) {
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [self toString:promo]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    } failure:^(NSError * error) {
        
    }];
}
- (void)getPaymentResult:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    int payment = [[[command arguments] objectAtIndex:1] intValue];
    
    [MPServicesBuilder getInstructions:1202870 paymentTypeId:@"ticket" success:^(InstructionsInfo * instruction) {
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [instruction toJSONString]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    } failure:^(NSError * error) {
        
    }];
}
- (void)createPayment:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    int quantity = [[[command arguments] objectAtIndex:2]intValue];
    double price = [[[command arguments] objectAtIndex:3]doubleValue];
    
    Item *item = [[Item alloc]initWith_id:[[command arguments] objectAtIndex:1] title:@"title" quantity:quantity unitPrice: price];
    
    Issuer *is =[[ Issuer alloc]init];
    is._id = [[NSNumber alloc] initWithInt:[[command arguments] objectAtIndex:10]];
    
    PaymentMethod *pm = [[PaymentMethod alloc]init];
    pm._id = [[command arguments] objectAtIndex:8];
    
    [MercadoPagoContext setMerchantAccessToken:[[command arguments] objectAtIndex:5]];
    
    MerchantPayment *mp=[[MerchantPayment alloc]initWithItems:item installments:[[command arguments] objectAtIndex:9] cardIssuer:is tokenId:[[command arguments] objectAtIndex:11] paymentMethod:pm campaignId:[[command arguments] objectAtIndex:4]];
    
    [MPServicesBuilder createPayment:[[command arguments] objectAtIndex:6] merchantPaymentUri:[[command arguments] objectAtIndex:7] payment:mp success:^(Payment * payment) {
        NSString *mppayment = [payment toJSONString];
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: mppayment];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    } failure:^(NSError * error) {
        
    }];
}

- (void)showPaymentVault:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    if ([[command arguments] objectAtIndex:2]!= (id)[NSNull null]){
        UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:2] alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    } else {
        UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    }
    if ([[[command arguments] objectAtIndex:3]boolValue]){
        [MercadoPagoContext setDarkTextColor];
    }else {
        [MercadoPagoContext setLightTextColor];
    }
    UINavigationController *paymentFlow = [MPFlowBuilder startPaymentVaultViewController:[[[command arguments] objectAtIndex:1]doubleValue] paymentPreference:nil callback:^(PaymentMethod * paymentMethod, Token * token, Issuer * issuer, PayerCost * payerCost) {
        
        NSString *jsonPaymentMethod = [paymentMethod toJSONString];
        //NSString *jsonToken = [token toJSONString];
        
        NSMutableDictionary *mpResponse = [[NSMutableDictionary alloc] init];
        [mpResponse setObject:jsonPaymentMethod forKey:@"payment_methods"];
        [mpResponse setObject:@"{a}" forKey:@"token"];
        
        if (payerCost != nil && issuer != nil ){
            NSString *jsonIssuer = [issuer toJSONString];
            NSString *jsonPayerCost = [payerCost toJSONString];
            [mpResponse setObject:jsonIssuer forKey:@"issuer"];
            [mpResponse setObject:jsonPayerCost forKey:@"payer_cost"];
        }
        
        NSError * err;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:mpResponse options:0 error:&err];
        NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [[command arguments] objectAtIndex:2]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    [rootViewController presentViewController:paymentFlow animated:YES completion:^{}];
}
- (void)showCardWithInstallments:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    if ([[command arguments] objectAtIndex:2]!= (id)[NSNull null]){
        UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:2] alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    } else {
        UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    }
    if ([[[command arguments] objectAtIndex:3]boolValue]){
        [MercadoPagoContext setDarkTextColor];
    }else {
        [MercadoPagoContext setLightTextColor];
    }
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    UINavigationController *choFlow = [MPFlowBuilder startCardFlow:nil amount:[[[command arguments] objectAtIndex:1]doubleValue] paymentMethods:nil callback:^(PaymentMethod * paymentMethod, Token * token, Issuer * issuer, PayerCost * payerCost) {
        
        NSString *jsonPaymentMethod = [paymentMethod toJSONString];
        //NSString *jsonToken = [token toJSONString];
        
        NSMutableDictionary *mpResponse = [[NSMutableDictionary alloc] init];
        [mpResponse setObject:jsonPaymentMethod forKey:@"payment_methods"];
        [mpResponse setObject:@"{a}" forKey:@"token"];
        
        if (payerCost != nil && issuer != nil ){
            NSString *jsonIssuer = [issuer toJSONString];
            NSString *jsonPayerCost = [payerCost toJSONString];
            [mpResponse setObject:jsonIssuer forKey:@"issuer"];
            [mpResponse setObject:jsonPayerCost forKey:@"payer_cost"];
        }
        
        NSError * err;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:mpResponse options:0 error:&err];
        NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: myString];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
        [rootViewController dismissViewControllerAnimated:YES completion:^{}];
        
    } callbackCancel:^{
        [rootViewController dismissViewControllerAnimated:YES completion:^{}];
    }];
    
    
    [rootViewController presentViewController:choFlow animated:YES completion:^{}];
}
- (void)showCardWithoutInstallments:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    if ([[command arguments] objectAtIndex:1]!= (id)[NSNull null]){
        UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:1] alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    } else {
        UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    }
    if ([[[command arguments] objectAtIndex:2]boolValue]){
        [MercadoPagoContext setDarkTextColor];
    }else {
        [MercadoPagoContext setLightTextColor];
    }
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    UINavigationController *choFlow = [MPStepBuilder startCreditCardForm:nil amount:100.0 paymentMethods:nil token:nil callback:^(PaymentMethod * paymentMethod, Token * token, Issuer * issuer) {
        
        NSString *jsonPaymentMethod = [paymentMethod toJSONString];
        //NSString *jsonToken = [token toJSONString];
        
        NSMutableDictionary *mpResponse = [[NSMutableDictionary alloc] init];
        [mpResponse setObject:jsonPaymentMethod forKey:@"payment_methods"];
        [mpResponse setObject:@"{a}" forKey:@"token"];
        
        if (issuer != nil ){
            NSString *jsonIssuer = [issuer toJSONString];
            [mpResponse setObject:jsonIssuer forKey:@"issuer"];
        }
        
        NSError * err;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:mpResponse options:0 error:&err];
        NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: myString];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
        [rootViewController dismissViewControllerAnimated:YES completion:^{}];
        
    } callbackCancel:^{
        [rootViewController dismissViewControllerAnimated:YES completion:^{}];
    }];
    
    [rootViewController presentViewController:choFlow animated:YES completion:^{}];
}
- (void)showPaymentMethods:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    if ([[command arguments] objectAtIndex:1]!= (id)[NSNull null]){
        UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:1] alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    } else {
        UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    }
    if ([[[command arguments] objectAtIndex:2]boolValue]){
        [MercadoPagoContext setDarkTextColor];
    }else {
        [MercadoPagoContext setLightTextColor];
    }
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    UIViewController *viewPaymentMethods = [MPStepBuilder startPaymentMethodsStep:nil callback:^(PaymentMethod * paymentMethod) {
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [paymentMethod toJSONString]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        [rootViewController dismissViewControllerAnimated:YES completion:^{}];
        
    }];
    
    [self showInNavigationController:viewPaymentMethods];
}
- (void)showIssuers:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    if ([[command arguments] objectAtIndex:2]!= (id)[NSNull null]){
        UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:2] alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    } else {
        UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    }
    if ([[[command arguments] objectAtIndex:3]boolValue]){
        [MercadoPagoContext setDarkTextColor];
        
    } else {
        [MercadoPagoContext setLightTextColor];
    }
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    PaymentMethod *pm = [[PaymentMethod alloc]init];
    pm._id = [[command arguments] objectAtIndex:1];
    
    
    UIViewController *viewIssuers = [MPStepBuilder startIssuersStep:pm callback:^(Issuer * issuer){
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [issuer toJSONString]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        [rootViewController dismissViewControllerAnimated:YES completion:^{}];
    }];
    [self showInNavigationController:viewIssuers];
}
- (void)showInstallments:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    if ([[command arguments] objectAtIndex:4]!= (id)[NSNull null]){
        UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:4] alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    } else {
        UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    }
    if ([[[command arguments] objectAtIndex:5]boolValue]){
        [MercadoPagoContext setDarkTextColor];
    }else {
        [MercadoPagoContext setLightTextColor];
    }
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    Issuer *issuer =[[Issuer alloc]init];
    issuer._id=[[NSNumber alloc] initWithInt:[[command arguments] objectAtIndex:3]];
    
    UIViewController *navInstallments = [MPStepBuilder startInstallmentsStep:nil paymentPreference:nil amount:[[[command arguments] objectAtIndex:1]doubleValue] issuer:issuer paymentMethodId:[[command arguments] objectAtIndex:2] callback:^(PayerCost * payerCost) {
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: [payerCost toJSONString]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        [rootViewController dismissViewControllerAnimated:YES completion:^{}];
    }];
    
    [self showInNavigationController:navInstallments];
}

- (void)showBankDeals:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    if ([[command arguments] objectAtIndex:1]!= (id)[NSNull null]){
        UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:1] alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    } else {
        UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:.9];
        [MercadoPagoContext setupPrimaryColor:color];
    }
    if ([[[command arguments] objectAtIndex:2]boolValue]){
        [MercadoPagoContext setDarkTextColor];
    }else {
        [MercadoPagoContext setLightTextColor];
    }
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    UIViewController *promo = [MPStepBuilder startPromosStep:^{
        [rootViewController dismissViewControllerAnimated:YES completion:^{}];
    }];
    
    [self showInNavigationController:promo];
}
- (void)showPaymentResult:(CDVInvokedUrlCommand*)command
{
    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
    NSString* callbackId = [command callbackId];
    
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
//    Payment *payment = [[Payment alloc]init];
//    payment._id= [[NSNumber alloc] initWithInt:[[command arguments] objectAtIndex:1]];
    

    
    NSData *data = [[[command arguments] objectAtIndex:1] dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];;

    Payment *payment = [Payment fromJSON:json];
    
    UINavigationController *navInstructions = [MPStepBuilder startInstructionsStep:payment paymentTypeId:@"ticket" callback:^(Payment *  payment) {
        
        [rootViewController dismissViewControllerAnimated:YES completion:^{}];
    }];
    
    [rootViewController presentViewController:navInstructions animated:YES completion:^{}];
 }

-(void) showInNavigationController:(UIViewController *)viewControllerBase{
    
    UINavigationController *navCon = [[UINavigationController alloc]initWithRootViewController:viewControllerBase];
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [rootViewController presentViewController:navCon animated:YES completion:^{}];
    
}
-(NSString *)toString:(NSArray*)array{
    NSString* json= @"[";
    
    for (int i=0; i < [array count]; i++) {
        json =[json stringByAppendingString:[array[i] toJSONString]];
        json = [json stringByAppendingString:@","];
    }
    json = [json substringToIndex:[json length] - 1];
    json = [json stringByAppendingString: @"]"];
    return json;
}
@end