# CCMQ
CCMQ是基于MMAP开发的适用于iOS的消息队列框架

## 基本特性介绍

### 1.到达性和顺序性：
CCMQ会确保消息一定能够发送到订阅者，CCMQ拥有串行和并行队列，串行队列会确保消息能够按照顺序发送顺序到达订阅者，并行队列则能够批量进行消息发送，但同一批次的消息到达顺序不能保证。

### 2.ACK机制：

#### 1.自动ACK：
CCMQ支持自动ACK，当消息到达所有订阅者之后，该条消息会自动回复ACK，代表该消息完成发送，将会从队列中移除并销毁

#### 2.手动ACK:
CCMQ支持手动ACK，订阅者可以根据自己的需要手动进行ACK回复

#### 3.重发机制
CCMQ提供了自动重发机制，当订阅者超时没有ACK时，CCMQ会进行消息重发

#### 4.消息持久化
CCMQ的会对消息进行持久化，意味着消息队列内的消息不会因为APP被杀掉而丢失，在APP再次打开之后，消息队列会恢复消息的发送

## 使用教程

### 1.环境要求：
CCMQ支持 iOS 6 以上
### 2.安装：
pod 'CCMQ'
### 3.初始化队列：
```
//串行队列
CCMQMessageQueue *searialQueue = [[CCMQMessageQueue alloc] initWithType:CCMQMessageQueueTypeSerial tag:@"serial"]

//并行队列
CCMQMessageQueue *concurrentQueue = [[CCMQMessageQueue alloc] initWithType:CCMQMessageQueueTypeConcurrent tag:@"concurrent"];
//设置并行发送的消息数量
concurrentQueue.maxConcurrentCount = 5;
```

### 4.发送消息：
通过调用以下的方法，CCMQ会向订阅者发送消息
```
CCMQMessage *message = [[CCMQMessage alloc] init];
//设置消息内容
message.message = "Datas";
[queue publish:message];
```

### 5.订阅消息队列：
每一个订阅者都需要设置port，port代表该订阅者的身份标识，当APP重新启动时，CCMQ通过port来判断该向哪些订阅者恢复消息发送。

**注意：当所有的port都ACK以后，才代表该消息发送完毕**
```
CCMQMessageSubscriber *subSerial = [[CCMQMessageSubscriber alloc] init];
//设置订阅者的port号
subSerial.port = @"sub1";
subSerial.subscribe = ^(CCMQMessage * _Nonnull message) {
    //订阅者可以在这里处理收到的消息
    ...
    //对于手动ACK的队列，需要手动进行ACK回复
    [queue finishMessage:message port:@"sub1"];
};
[queue addSubscriber:subSerial];
```
