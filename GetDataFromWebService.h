//
//  GetDataFromWebService.h
//  MyPatroller
//
//  Created by 刘 俊 on 12-10-11.
//
//

#import <Foundation/Foundation.h>

@protocol DataFromWebServiceDelegate;

//请求类型
typedef enum
{
    DEVICEACTIVE,
}QUSET_TYPE;

//返回值类型
typedef enum
{
    DETAILINFO,         //单个对象
    DETAIL_OBJECTS,     //对象集合
    CHOOSE,
}RETURNVALUE_TYPE;


@interface GetDataFromWebService :NSObject
{
    NSURL *fwqId;
    
    QUSET_TYPE delegateType;
    RETURNVALUE_TYPE downType;
    NSMutableData *webData;
    NSMutableArray *resultsDictionary;
    
    NSString *measureName;
    NSMutableArray *dataArray;
    NSArray *ResultBoard;

    id <DataFromWebServiceDelegate>delegate;
    
    //webService返回值
    NSMutableString *body;
    
    NSMutableString *soapMessage;
    
    NSURLConnection *theConnection;
}

@property (nonatomic)NSMutableArray *resultsDictionary;
@property (nonatomic)NSString *measureName;
@property (nonatomic)NSArray *dataArray;
@property (nonatomic)NSArray *resultBoard;
@property (nonatomic)id <DataFromWebServiceDelegate>delegate;

-(id)initWithType:(QUSET_TYPE)type withDownType:(RETURNVALUE_TYPE)downpe;
//---------------------异步连接
-(void)asyncRequest:(NSArray *)parameters;
//断开连接
-(void)cancle;



//---------------------同步连接
-(NSArray *)syncRequest:(NSArray *)parameters;
-(NSArray *)praseSimpleObject__Sync:(NSString *)theXML;//简单值
-(NSArray *)praseObjects__Sync:(NSString *)theXML;//对象

@end

@protocol DataFromWebServiceDelegate

-(void)didFailToGetInfo:(NSArray *)errorData withType:(QUSET_TYPE)type;//数据获取失败
-(void)didAnalyzeTheData:(NSArray *)data withType:(QUSET_TYPE)type;//数据被成功解析

@end




