//
//  MGImageData.m
//  MGFacepp
//
//  Created by 张英堂 on 2016/12/27.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGImageData.h"

@interface MGImageData ()
{
    void *_rawData;
}
@property (nonatomic, assign) CMSampleBufferRef sampleBuffer;
@property (nonatomic, assign) CVImageBufferRef CVImageBuffer;


@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign) BOOL isUIImage;



@end

@implementation MGImageData
- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}
-(instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    self = [super init];
    if (self) {
        _isUIImage = NO;
        self.sampleBuffer = sampleBuffer;
    }
    return self;
}

-(instancetype)initWithImage:(UIImage *)image{
    self = [super init];
    if (self) {
        _isUIImage = YES;
        self.image = image;
    }
    return self;
}

- (CVImageBufferRef)CVImageBuffer{
    if (!_CVImageBuffer) {
        _CVImageBuffer = CMSampleBufferGetImageBuffer(self.sampleBuffer);
    }
    return _CVImageBuffer;
}

-(CGFloat)width{
    if (NO == self.isUIImage) {
        
        size_t tempWidth = 0;
        
        CVImageBufferRef imageBuffer = self.CVImageBuffer;
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t PerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        
        BOOL isPlenar = CVPixelBufferIsPlanar(imageBuffer);
        if (isPlenar) {
            PerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
        }
        
        OSType type = CVPixelBufferGetPixelFormatType(imageBuffer);
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);

        size_t pointSize = [MGImageData getImageBit:type];
        
        if (pointSize != 0) {
            tempWidth = (PerRow - width*pointSize)/pointSize + width;
        }else{
            tempWidth = width;
        }
                
        return tempWidth;
    }
    return self.image.size.width;
}


-(CGFloat)height{
    if (NO == self.isUIImage) {
        CVImageBufferRef imageBuffer = self.CVImageBuffer;
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        return height;
    }
    return self.image.size.height;
}

-(const char *)getData{
    if (_rawData != NULL) {
        return _rawData;
    }
    
    if (NO == self.isUIImage) {
        _rawData = [MGImageData MGRawDataFromSampleBuffer:self.CVImageBuffer];
    }else{
        _rawData = [MGImageData GetRGBAData:self.image.CGImage];
    }
    
    return _rawData;
}

- (void)releaseImageData{
    if (YES == self.isUIImage) {
        free(_rawData);
        
        self.image = nil;
    }else{
        self.sampleBuffer = nil;
    }
}


+ (size_t)getImageBit:(OSType)type{
    size_t returnSize = 0;
    
    switch (type) {
        case kCVPixelFormatType_32ARGB:
        case kCVPixelFormatType_32BGRA:
        case kCVPixelFormatType_32ABGR:
        case kCVPixelFormatType_32RGBA:
            returnSize = 4;
            break;
        case kCVPixelFormatType_24RGB:
        case kCVPixelFormatType_24BGR:
            returnSize = 3;
            break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr8PlanarFullRange:
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
        case kCVPixelFormatType_422YpCbCr_4A_8BiPlanar:
            returnSize = 1;
            break;
            
        default:
            returnSize = 0;
            break;
    }
    
    return returnSize;
}

+ (void *)MGRawDataFromSampleBuffer:(CVImageBufferRef)imageBuffer{
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    return baseAddress;
}

+ (unsigned char*)GetRGBAData:(CGImageRef)imageRef{
    int RGBA = 4;
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*)malloc(width*height*4*sizeof(unsigned char));
    NSUInteger bytesPerPixel = RGBA;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return rawData;
}

@end
