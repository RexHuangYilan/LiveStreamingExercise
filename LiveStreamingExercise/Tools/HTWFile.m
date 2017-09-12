//
//  HTWFile.m
//  LiveStreamingExercise
//
//  Created by Rex on 2017/2/20.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "HTWFile.h"

@implementation HTWFile

+(NSString *)createFileName:(NSString *)filename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    [fileManager removeItemAtPath:path error:nil];
    [fileManager createFileAtPath:path contents:nil attributes:nil];
    return path;
}

@end
