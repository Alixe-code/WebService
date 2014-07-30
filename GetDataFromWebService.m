//
//  GetDataFromWebService.m
//  MyPatroller
//
//  Created by 刘 俊 on 12-10-11.
//
//
#define COM_NAME @"http://yourWeb.com/"
//#define WEBSERVICE_DOMAIN @"http://yourWeb.com/"   //production
#define WEBSERVICE_DOMAIN @"http://yourWeb.com"   //development

#import "GetDataFromWebService.h"
#import "JSONKit.h"
#import "NetworkConnect.h"

@implementation GetDataFromWebService

@synthesize resultsDictionary,measureName,dataArray,resultBoard;
@synthesize delegate;

-(id)initWithType:(QUSET_TYPE)type withDownType:(RETURNVALUE_TYPE)downpe
{
    if (self=[super init])
    {
        resultsDictionary=[[NSMutableArray alloc]init];
        resultBoard=[[NSArray alloc]init];
        
        delegateType=type;
        downType=downpe;
    }
    return self;
}

-(void)cancle
{
    if (theConnection)
    {
        [theConnection cancel];
    }
}

//根据参数集封装请求体
-(NSString *)getSoapBodyWithFuntions:(NSArray *)function
{
    //NSLog(@"function内容：%@",function);
    NSString *webMethod;
    NSArray *method;
    
    switch (delegateType)
    {
        case DEVICEACTIVE:
        {
            measureName=@"DeviceActive";
            method= [NSArray arrayWithObjects:@"identifierForVendor",nil];
        }
            break;
            
        default:
            break;
    }
    
    webMethod=measureName;
    
    NSString *header=[NSString stringWithFormat:@"<%@ xmlns=\"%@\">\n",webMethod,COM_NAME];
    NSString *footer=[NSString stringWithFormat:@"</%@>\n",webMethod];
    
    NSMutableString *functionArray=[[NSMutableString alloc]init];
    for (int i=0;i<[function count];i++)
    {
        NSString *oneFunction=[NSString stringWithFormat:@"<%@>%@</%@>\n",[method objectAtIndex:i],[function objectAtIndex:i],[method objectAtIndex:i]];
        [functionArray appendString:oneFunction];
    }
    
    NSString *soapBody=[NSString stringWithFormat:@"%@%@%@",header,functionArray,footer];
        
    return  soapBody;
}

-(void)asyncRequest:(NSArray *)parameters
{
    //网络状态检测
    if ([NetworkConnect connectedToNetwork])
    {
        soapMessage=[NSMutableString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                     "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"];
        
        //根据具体方法匹配路径
        NSString *adress=[NSString stringWithFormat:@"%@iosservice.asmx?op=%@",WEBSERVICE_DOMAIN,measureName];
        fwqId=[NSURL URLWithString:adress];
        //请求发送到的路径
        NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:fwqId];
        [theRequest setTimeoutInterval:60];
        
        [theRequest addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                
        //封装Header信息（用于webService请求加密）
        NSString *soapMessageBody=[self getSoapBodyWithFuntions:parameters];
        
        //拼接完整请求体
        NSString *wholeBody=[NSString stringWithFormat:@"<soap:Body>"
                             "%@"
                             "</soap:Body>"
                             "</soap:Envelope>",soapMessageBody];
        
        [soapMessage appendString:wholeBody];
        
        //NSLog(@"完整请求：%@",soapMessage);
        NSString *value=[NSString stringWithFormat:@"%@%@",COM_NAME,measureName];
        [theRequest addValue:value forHTTPHeaderField:@"SOAPAction"];
        
        NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapMessage length]];
        [theRequest addValue: msgLength forHTTPHeaderField:@"Content-Length"];
        
        [theRequest setHTTPMethod:@"POST"];
        [theRequest setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
        theRequest.timeoutInterval=30;
        
        //请求
        theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    	
        //如果连接已经建好，则初始化data
        if( theConnection )
        {
            webData = [NSMutableData data];
        }
        else
        {
            NSLog(@"theConnection is NULL");
        }
    }
    else
    {
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"无法连接网络，请检查设置" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (NSArray *)syncRequest:(NSArray *)parameters
{
    //网络状态检测
    if ([NetworkConnect connectedToNetwork])
    {
        soapMessage=[NSMutableString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                     "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"];
        
        //根据具体方法匹配路径
        NSString *adress=[NSString stringWithFormat:@"http://mobile.mypatroller.com/iosservice.asmx?op=%@",measureName];
        fwqId=[NSURL URLWithString:adress];
        //请求发送到的路径
        NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:fwqId];
        [theRequest setTimeoutInterval:60];
        
        [theRequest addValue: @"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        
        //封装Header信息（用于webService请求加密）
        NSString *soapMessageBody=[self getSoapBodyWithFuntions:parameters];
        
        //拼接完整请求体
        NSString *wholeBody=[NSString stringWithFormat:@"<soap:Body>"
                             "%@"
                             "</soap:Body>"
                             "</soap:Envelope>",soapMessageBody];
        
        [soapMessage appendString:wholeBody];
        
        //NSLog(@"完整请求：%@",soapMessage);
        NSString *value=[NSString stringWithFormat:@"%@%@",COM_NAME,measureName];
        [theRequest addValue:value forHTTPHeaderField:@"SOAPAction"];
        
        NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapMessage length]];
        [theRequest addValue: msgLength forHTTPHeaderField:@"Content-Length"];
        
        [theRequest setHTTPMethod:@"POST"];
        [theRequest setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
        
        //请求
        NSData *returnData = [NSURLConnection sendSynchronousRequest:theRequest
                                                   returningResponse:nil error:nil];
        
        if (returnData==nil||[returnData length]==0)
        {
            //返回错误信息
            return nil;
        }
        else
        {
            NSString *theXML = [[NSString alloc] initWithBytes: [returnData bytes] length:[returnData length] encoding:NSUTF8StringEncoding];
            
            NSArray *returnInfo;
            if (downType==CHOOSE)
            {
                returnInfo=[self praseSimpleObject__Sync:theXML];
            }
            else
            {
                returnInfo=[self praseObjects__Sync:theXML];
            }
            
            return returnInfo;
        }
    }
    else
    {
        return nil;
    }
}

#pragma mark NSURLConnection Delegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[webData setLength: 0];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[webData appendData:data];
}

//如果电脑没有连接网络，则出现此信息（不是网络服务器不通）
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	//NSLog(@"ERROR with theConenction");
    
    [self.delegate didFailToGetInfo:nil withType:delegateType];
    
    [connection cancel];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	//NSLog(@"3 DONE. Received Bytes: %d", [webData length]);
    
    if (webData==nil||[webData length]==0)
    {
        //返回错误信息
        [self.delegate didFailToGetInfo:nil withType:delegateType];
    }
    else
    {
        NSString *theXML = [[NSString alloc] initWithBytes: [webData mutableBytes] length:[webData length] encoding:NSUTF8StringEncoding];
        
        [self handleValue:theXML];
    }
}

#pragma mark 解析部分_async

-(void)handleValue:(NSString *)theXML
{
    //NSLog(@"*********内容：%@",theXML);
    if (downType==DETAILINFO||downType==DETAIL_OBJECTS)
    {
        NSString *startString=[NSString stringWithFormat:@"<%@Result>",measureName];
        NSString *endString=[NSString stringWithFormat:@"</%@Result>",measureName];
        
        NSInteger first=[theXML rangeOfString:startString].location;
        NSInteger last=[theXML rangeOfString:endString].location;
        //NSLog(@"位置：%d",[theXML rangeOfString:@"["].location);
        //NSLog(@"位置：%d",[theXML rangeOfString:@"]"].location);
        
        NSRange range=NSMakeRange(first+[startString length],last-first-[startString length]);
        NSInteger length=last-first-[startString length]+2;
        if (length>1)
        {
            body=[[NSMutableString alloc]initWithString:[theXML substringWithRange:range]];
            
            if ([body length]>2)
            {
                //解析JSON
                [self prase:body];
            }
            else
            {
                //返回数据为空,给出提示
                [self.delegate didAnalyzeTheData:nil withType:delegateType];
            }
        }
        else
        {
            //返回错误信息
            [self.delegate didFailToGetInfo:nil withType:delegateType];
        }
    }
    else if(downType==CHOOSE)
    {
        NSString *theXML = [[NSString alloc] initWithBytes: [webData mutableBytes] length:[webData length] encoding:NSUTF8StringEncoding];
        //NSLog(@"*********内容：%@",theXML);
        
        NSString *firstStep=[NSString stringWithFormat:@"Result>"];
        NSString *lastStep=[NSString stringWithFormat:@"</"];
        NSInteger dataLength=[firstStep length];
        
        NSInteger first=[theXML rangeOfString:firstStep].location;
        NSInteger last=[theXML rangeOfString:lastStep].location;
        NSRange range=NSMakeRange(first+dataLength,last-(first+dataLength));
        
        NSInteger length=last-first-[firstStep length]+2;
        if (length>1)
        {
            body=[[NSMutableString alloc]initWithString:[theXML substringWithRange:range]];
            //NSLog(@"返回值：%@",body);
            
            NSArray *resultArray=[NSArray arrayWithObjects:body, nil];
            [self.delegate didAnalyzeTheData:resultArray withType:delegateType];
        }
    }
}

-(void)prase:(NSString *)dataString
{
    NSData* jsonData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    
    dataArray=[[NSMutableArray alloc]init];
    if (downType==DETAILINFO)
    {
        NSMutableDictionary *dic=[NSMutableDictionary dictionaryWithDictionary:[jsonData objectFromJSONData]];
        [dataArray addObject:dic];
    }
    else 
    {
        /*
        NSArray *array=[jsonData mutableObjectFromJSONData];
        
        for (NSDictionary *dic in array)
        {
            [dataArray addObject:dic];
        }
         */
        
        id objc=[jsonData mutableObjectFromJSONData];
        //解析的结构可能为JKArray或者JKDictionary
        if ([objc isKindOfClass:[NSArray class]])
        {
            NSArray *array=(NSArray *)objc;
            for (NSDictionary *dic in array)
            {
                [dataArray addObject:dic];
            }
        }
        else
        {
            NSDictionary *dic=(NSDictionary *)objc;
            [dataArray addObject:dic];
        }
    }
    
    if (dataArray!=nil&&[dataArray count]!=0)
    {
        //[self print:dataArray];
        
        [self.delegate didAnalyzeTheData:dataArray withType:delegateType];
    }
    else
    {
        NSArray *errorInfo=[NSArray arrayWithObject:@"Permission is denied."];
        //返回错误信息（权限验证出错）
        [self.delegate didFailToGetInfo:errorInfo withType:delegateType];
    }
}

#pragma mark 解析部分_sync

-(NSArray *)praseSimpleObject__Sync:(NSString *)theXML
{
    //NSLog(@"async*********内容：%@",theXML);
    
    NSString *firstStep=[NSString stringWithFormat:@"Result>"];
    NSString *lastStep=[NSString stringWithFormat:@"</"];
    NSInteger dataLength=[firstStep length];
    
    NSInteger first=[theXML rangeOfString:firstStep].location;
    NSInteger last=[theXML rangeOfString:lastStep].location;
    NSRange range=NSMakeRange(first+dataLength,last-(first+dataLength));
    
    NSInteger length=last-first-[firstStep length]+2;
    if (length>1)
    {
        NSString *bodyString=[[NSMutableString alloc]initWithString:[theXML substringWithRange:range]];
        //NSLog(@"返回值：%@",body);
        
        NSArray *resultArray=[NSArray arrayWithObjects:bodyString, nil];
        return resultArray;
    }
    else
    {
        return nil;
    }
}

-(NSArray *)praseObjects__Sync:(NSString *)theXML
{
    //NSLog(@"async*********内容：%@",theXML);
    NSString *startString=[NSString stringWithFormat:@"<%@Result>",measureName];
    NSString *endString=[NSString stringWithFormat:@"</%@Result>",measureName];
    
    NSInteger first=[theXML rangeOfString:startString].location;
    NSInteger last=[theXML rangeOfString:endString].location;
    //NSLog(@"位置：%d",[theXML rangeOfString:@"["].location);
    //NSLog(@"位置：%d",[theXML rangeOfString:@"]"].location);
    
    NSRange range=NSMakeRange(first+[startString length],last-first-[startString length]);
    NSInteger length=last-first-[startString length]+2;
    if (length>1)
    {
        NSString *bodyString=[[NSMutableString alloc]initWithString:[theXML substringWithRange:range]];
        
        if ([bodyString length]>2)
        {
            //解析JSON
            NSData* jsonData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSMutableArray *infoArray=[[NSMutableArray alloc]init];
            if (downType==DETAILINFO)
            {
                NSMutableDictionary *dic=[NSMutableDictionary dictionaryWithDictionary:[jsonData objectFromJSONData]];
                [infoArray addObject:dic];
            }
            else
            {
                NSArray *array=[jsonData mutableObjectFromJSONData];
                
                for (NSDictionary *dic in array)
                {
                    [infoArray addObject:dic];
                }
            }
            
            if (infoArray!=nil&&[infoArray count]!=0)
            {
                return infoArray;
            }
            else
            {
                return nil;
            }
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

#pragma mark 3DES加密解密

-(NSString *)decryptString:(NSString *)encryptString
{
    return encryptString;
}

-(NSString *)encryptString:(NSString *)plainText
{
    return plainText;
}

#pragma mark 其他

//打印方法
-(void)print:(NSArray *)data
{
    if (data!=nil)
    {
        for (NSDictionary *dic in data)
        {
            NSLog(@"————打印方法");
            NSArray *allKeys=[dic allKeys];
            for (NSString *word in allKeys)
            {
                NSLog(@"%@---%@",word,[dic objectForKey:word]);
            }
            NSLog(@"打印方法,共%lu个字段*****",(unsigned long)[dic count]);
            NSLog(@" ");
            NSLog(@" ");
        }
    }
    else
    {
        NSLog(@"没有数据，无法解析");
    }
}

@end
