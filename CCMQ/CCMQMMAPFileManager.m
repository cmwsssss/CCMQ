//
//  MMAPFileManager.m
//  MessageQueue
//
//  Created by cmw on 2020/9/21.
//  Copyright © 2020 com. All rights reserved.
//

#import "CCMQMMAPFileManager.h"
#import <sys/mman.h>

//message mmap数据块结构：(int length)(char *uuid)(char *content)
//ack数据块结构 (int totalLength)(char *uuid)(repeat (int length)(char acked)(char *port))

@implementation CCMQMMAPFileManager

static NSMutableDictionary *s_mmap_file_map;
static NSMutableDictionary *s_mmap_pointer_map;

static NSMutableDictionary *s_mmap_ack_file_map;
static NSMutableDictionary *s_mmap_ack_pointer_map;

static NSString *s_mmap_direcotyPath;

+ (void)initialize {
    s_mmap_file_map = [[NSMutableDictionary alloc] init];
    s_mmap_pointer_map = [[NSMutableDictionary alloc] init];
    s_mmap_ack_file_map = [[NSMutableDictionary alloc] init];
    s_mmap_ack_pointer_map = [[NSMutableDictionary alloc] init];
}

+ (NSString *)mmapFilePathWithQueue:(CCMQMessageQueue *)queue {
    return [[self getMMAPDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mmap", queue.tag]];
}

+ (NSString *)ackFilePathWithQueue:(CCMQMessageQueue *)queue {
    return [[self getMMAPDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_ack.mmap", queue.tag]];
}

+ (void)createMMAPFileForQueue:(CCMQMessageQueue *)queue {
    NSString *filePath = [self mmapFilePathWithQueue:queue];
    int fileInstance = open(filePath.UTF8String, O_RDWR|O_CREAT, 0666);
    [s_mmap_file_map setObject:@(fileInstance) forKey:queue.tag];
    
    size_t fileLength = [self getFileSize:filePath];
    
    void *ptr = mmap(NULL, fileLength, (PROT_READ|PROT_WRITE), (MAP_FILE|MAP_SHARED), fileInstance, 0);
    [s_mmap_pointer_map setObject:[NSValue valueWithPointer:ptr] forKey:queue.tag];
    
    NSString *ackFilePath = [self ackFilePathWithQueue:queue];
    fileInstance = open(ackFilePath.UTF8String, O_RDWR|O_CREAT, 0666);
    [s_mmap_ack_file_map setObject:@(fileInstance) forKey:queue.tag];
    
    fileLength = [self getFileSize:ackFilePath];
    ptr = mmap(NULL, fileLength, (PROT_READ|PROT_WRITE), (MAP_FILE|MAP_SHARED), fileInstance, 0);
    [s_mmap_ack_pointer_map setObject:[NSValue valueWithPointer:ptr] forKey:queue.tag];
}

+ (NSString *)getMMAPDirectoryPath {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        s_mmap_direcotyPath = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"MessageQueue"];
        
        BOOL isExisited = [[NSFileManager defaultManager]fileExistsAtPath:s_mmap_direcotyPath];
        if(isExisited == false) {
            [[NSFileManager defaultManager]createDirectoryAtPath:s_mmap_direcotyPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    });
    
    return s_mmap_direcotyPath;
}

+ (size_t)getFileSize:(NSString *)filePath {
    FILE *file = fopen(filePath.UTF8String, "r");
    if (file == NULL) {
        return 0;
    }
    fseek(file, 0, SEEK_END);
    size_t fileLength = ftell(file);
    fclose(file);
    return fileLength;
}

+ (void)initializeWithQueue:(CCMQMessageQueue *)queue {
    if (![s_mmap_file_map objectForKey:queue.tag]) {
        [self createMMAPFileForQueue:queue];
    }
}

+ (void)publishToMMAPFile:(CCMQMessage *)message queue:(CCMQMessageQueue *)queue {
        
    [queue MMAPFileLockLock];
    
    int instance = [[s_mmap_file_map objectForKey:queue.tag] intValue];
    
    int messageLength = (int)message.message.length + 1;
    NSString *filePath = [self mmapFilePathWithQueue:queue];
    size_t fileLength = [self getFileSize:filePath];
    
    int chunkSize = 4 + 33 + messageLength;
    
    void *ptr = [[s_mmap_pointer_map objectForKey:queue.tag] pointerValue];
    munmap(ptr, fileLength);
    
    ftruncate(instance, fileLength + chunkSize);
    
    ptr = mmap(NULL, fileLength + chunkSize, (PROT_READ|PROT_WRITE), (MAP_FILE|MAP_SHARED), instance, 0);
    [s_mmap_pointer_map setObject:[NSValue valueWithPointer:ptr] forKey:queue.tag];
    
    void *seek = ptr + fileLength;
    memcpy(seek, &chunkSize, sizeof(int));
    seek += sizeof(int);
    memcpy(seek, message.uuid.UTF8String, 33);
    seek += 33;
    memcpy(seek, message.message.UTF8String, messageLength);
    msync(ptr + fileLength, chunkSize, MS_SYNC);
    
    //更新ack
    
    instance = [[s_mmap_ack_file_map objectForKey:queue.tag] intValue];
    void *ackChunk = malloc(sizeof(void *));
    seek = ackChunk;
    NSInteger totalAckSize = 0;
    for (NSString *obj in message.ackPorts) {
        NSInteger chunkSize = obj.length + 1 + 1 + 4;
        ackChunk = realloc(ackChunk, totalAckSize + chunkSize);
        seek = ackChunk + totalAckSize;
        totalAckSize += chunkSize;
        memcpy(seek, &totalAckSize, sizeof(int));
        seek += 4;
        char tag = '0';
        memcpy(seek, &tag, 1);
        seek++;
        memcpy(seek, obj.UTF8String, obj.length + 1);
        seek += obj.length + 1;
    }
    
    filePath = [self ackFilePathWithQueue:queue];
    fileLength = [self getFileSize:filePath];
    
    chunkSize = 4 + 33 + (int)totalAckSize;
    
    ptr = [[s_mmap_ack_pointer_map objectForKey:queue.tag] pointerValue];
    munmap(ptr, fileLength);
    
    ftruncate(instance, fileLength + chunkSize);
    
    ptr = mmap(NULL, fileLength + chunkSize, (PROT_READ|PROT_WRITE), (MAP_FILE|MAP_SHARED), instance, 0);
    [s_mmap_ack_pointer_map setObject:[NSValue valueWithPointer:ptr] forKey:queue.tag];
    
    seek = ptr + fileLength;
    memcpy(seek, &chunkSize, sizeof(int));
    seek += sizeof(int);
    memcpy(seek, message.uuid.UTF8String, 33);
    seek += 33;
    memcpy(seek, ackChunk, totalAckSize);
    msync(ptr + fileLength, chunkSize, MS_SYNC);
    [queue MMAPFileLockUnLock];
}

+ (void *)findChunkPtrWithUUID:(NSString *)uuid ptr:(void *)basePtr maxOffset:(size_t)fileSize {
    void *ptr = basePtr;
    if ((int)(ptr - basePtr) >= fileSize) {
        return NULL;
    }
    void *seek = ptr + 4;
    char *chunkUUID = malloc(33);
    memcpy(chunkUUID, seek, 33);
    while (strcmp(chunkUUID, uuid.UTF8String) != 0) {
        int length = *(int *)ptr;
        ptr += length;
        if ((int)(ptr - basePtr) >= fileSize) {
            return NULL;
        }
        seek = ptr + 4;
        memcpy(chunkUUID, seek, 33);
    }
    return seek;
}

+ (CCMQMessage *)getMessageWithPtr:(void *)seek queue:(CCMQMessageQueue *)queue{
    void *ptr = seek - 4;
    char *uuidChar = malloc(33);
    
    memcpy(uuidChar, seek, 33);
    NSString *uuid = [NSString stringWithUTF8String:uuidChar];
    seek += 33;
    int length = *(int *)ptr;
    char *chunkMessage = malloc(length - 33 - 4);
    memcpy(chunkMessage, seek, length - 33 - 4);
    NSString *messageContent = [NSString stringWithUTF8String:chunkMessage];
    CCMQMessage *message = [[CCMQMessage alloc] init];
    message.message = messageContent;
    message.uuid = uuid;
    
    //处理ack ports
    
    ptr = [[s_mmap_ack_pointer_map objectForKey:queue.tag] pointerValue];
    seek = [self findChunkPtrWithUUID:uuid ptr:ptr maxOffset:[self getAckFileSizeWithQueue:queue]];
    if (seek == NULL) {
        [self removeMessage:message queue:queue];
        [[NSNotificationCenter defaultCenter] postNotificationName:FLUSH_NEXT_MESSAGE object:queue];
        return nil;
    }
    ptr = seek - 4;

    length = *(int *)ptr;
    length -= (4 + 33);
    seek += 33;
    NSMutableArray *ports = [[NSMutableArray alloc] init];
    while (length > 0) {
        int ackChunkSize = *(int *)seek;
        seek += 5;
        char *port = malloc(ackChunkSize - 5);
        memcpy(port, seek, ackChunkSize - 5);
        [ports addObject:[[NSString alloc]initWithCString:port encoding:NSUTF8StringEncoding]];
        length -= ackChunkSize;
        seek += ackChunkSize - 5;
    }
    message.ackPorts = [[NSArray alloc] initWithArray:ports];
    return message;
}

+ (CCMQMessage *)getMessageWithUUID:(NSString *)uuid queue:(CCMQMessageQueue *)queue {
    void *ptr = [[s_mmap_pointer_map objectForKey:queue.tag] pointerValue];
    void *seek = [self findChunkPtrWithUUID:uuid ptr:ptr maxOffset:[self getFileSizeWithQueue:queue]];
    if (seek == NULL) {
        return nil;
    }
    return [self getMessageWithPtr:seek queue:queue];
}

+ (NSArray <NSString *> *)portsNotReceviedAck:(CCMQMessage *)message queue:(CCMQMessageQueue *)queue {
    [queue MMAPFileLockLock];
    void *ptr = [[s_mmap_ack_pointer_map objectForKey:queue.tag] pointerValue];
    void *seek = [self findChunkPtrWithUUID:message.uuid ptr:ptr maxOffset:[self getAckFileSizeWithQueue:queue]];
    if (!seek) {
        [queue MMAPFileLockUnLock];
        return nil;
    }
    ptr = seek - 4;

    int length = *(int *)ptr;
    length -= (4 + 33);
    seek += 33;
    NSMutableArray *ports = [[NSMutableArray alloc] init];
    while (length > 0) {
        int ackChunkSize = *(int *)seek;
        seek += 4;
        char tag = *(char *)seek;
        if (tag == '0') {
            char *port = malloc(ackChunkSize - 5);
            memcpy(port, seek + 1, ackChunkSize - 5);
            [ports addObject:[[NSString alloc]initWithCString:port encoding:NSUTF8StringEncoding]];
        }
        seek += ackChunkSize - 4;
        length -= ackChunkSize;
    }
    [queue MMAPFileLockUnLock];
    return [NSArray arrayWithArray:ports];
}

+ (void)removeMessage:(CCMQMessage *)message queue:(CCMQMessageQueue *)queue {
    void *basePtr = [[s_mmap_pointer_map objectForKey:queue.tag] pointerValue];
    void *seek = [self findChunkPtrWithUUID:message.uuid ptr:basePtr maxOffset:[self getFileSizeWithQueue:queue]];
    if (seek == NULL) {
        return;
    }
    void *ptr = seek - 4;
    int fileInstance = [[s_mmap_file_map objectForKey:queue.tag] intValue];
    int chunkSize = *(int *)ptr;
    int offset = (int)(ptr - basePtr);
    NSString *filePath = [self mmapFilePathWithQueue:queue];
    size_t fileLength = [self getFileSize:filePath] - chunkSize;
    if (fileLength - offset != 0) {
        memcpy(ptr, ptr + chunkSize, fileLength - offset);
    }
    
    msync(basePtr, fileLength, MS_SYNC);
    ftruncate(fileInstance, fileLength);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_DID_REMOVED object:message];
}

+ (void)showFirstMessageWithBasePtr:(void *)ptr queue:(CCMQMessageQueue *)queue {
    void *seek = ptr + 4;
    CCMQMessage *message = [self getMessageWithPtr:seek queue:queue];
//    NSLog(@"firstMessage: %@", message.message);
}

+ (void)showFirstMessageInQueue:(CCMQMessageQueue *)queue {
    void *basePtr = [[s_mmap_pointer_map objectForKey:queue.tag] pointerValue] + 4;
    CCMQMessage *message = [self getMessageWithPtr:basePtr queue:queue];
//    NSLog(@"firstMessage: %@", message.message);
}

+ (void)finishMessage:(CCMQMessage *)message port:(NSString *)port queue:(CCMQMessageQueue *)queue {
    [queue MMAPFileLockLock];
    void *basePtr = [[s_mmap_ack_pointer_map objectForKey:queue.tag] pointerValue];
    void *seek = [self findChunkPtrWithUUID:message.uuid ptr:basePtr maxOffset:[self getAckFileSizeWithQueue:queue]];
    if (seek == NULL) {
        [queue MMAPFileLockUnLock];
        return;
    }
    void *ptr = seek - 4;
    int length = *(int *)ptr;
    length -= (4 + 33);
    seek += 33;
    BOOL needRemoveMessage = YES;
    while (length > 0) {
        int ackChunkSize = *(int *)seek;
        seek += 4;
        char tag = *(char *)seek;
        char *chunkPort = malloc(ackChunkSize - 5);
        memcpy(chunkPort, seek + 1, ackChunkSize - 5);
        if (strcmp(port.UTF8String, chunkPort) == 0) {
            tag = '1';
            memcpy(seek, &tag, 1);
            msync(seek, 1, MS_SYNC);
        } else if (tag == '0') {
            needRemoveMessage = NO;
        }
        length -= ackChunkSize;
        seek += ackChunkSize - 4;
    }
    
    if (needRemoveMessage) {
        seek = [self findChunkPtrWithUUID:message.uuid ptr:basePtr maxOffset:[self getAckFileSizeWithQueue:queue]];
        if (seek == NULL) {
            [queue MMAPFileLockUnLock];
            [[NSNotificationCenter defaultCenter] postNotificationName:FLUSH_NEXT_MESSAGE object:queue];
            return;
        }
        ptr = seek - 4;
        int fileInstance = [[s_mmap_ack_file_map objectForKey:queue.tag] intValue];
        int offset = (int)(ptr - basePtr);
        int chunkSize = *(int *)ptr;
        NSString *filePath = [self ackFilePathWithQueue:queue];
        size_t fileLength = [self getFileSize:filePath] - chunkSize;
        if (fileLength - offset != 0) {
            memcpy(ptr, ptr + chunkSize, fileLength - offset);
        }
        msync(basePtr, fileLength, MS_SYNC);
        ftruncate(fileInstance, fileLength);
                
        [self removeMessage:message queue:queue];
    }
    [queue MMAPFileLockUnLock];
    [[NSNotificationCenter defaultCenter] postNotificationName:FLUSH_NEXT_MESSAGE object:queue];
}

+ (NSArray <CCMQMessage*> *)getMessageToIndex:(NSInteger)index queue:(CCMQMessageQueue *)queue {
    [queue MMAPFileLockLock];
    void *basePtr = [[s_mmap_pointer_map objectForKey:queue.tag] pointerValue];
    void *ptr = basePtr;
    size_t fileLength = [self getFileSizeWithQueue:queue];
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    if (basePtr == NULL) {
        [queue MMAPFileLockUnLock];
        return messages;
    }
    for (int i = 0; i < index; i++) {
        if ((int)(ptr - basePtr) >= fileLength) {
            [queue MMAPFileLockUnLock];
            return messages;
        }
        int offset = *(int *)ptr;
        ptr += 4;
        CCMQMessage *message = [self getMessageWithPtr:ptr queue:queue];
        if (message) {
            [messages addObject:message];
        }
        ptr += (offset - 4);
    }
    [queue MMAPFileLockUnLock];
    return [NSArray arrayWithArray:messages];
}


+ (size_t)getFileSizeWithQueue:(CCMQMessageQueue *)queue {
    NSString *filePath = [self mmapFilePathWithQueue:queue];
    return [self getFileSize:filePath];
}

+ (size_t)getAckFileSizeWithQueue:(CCMQMessageQueue *)queue {
    NSString *filePath = [self ackFilePathWithQueue:queue];
    return [self getFileSize:filePath];
}

@end
