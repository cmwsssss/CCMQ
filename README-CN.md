中文版本请[点击这里](https://github.com/cmwsssss/CCMQ/blob/main/README-CN.md)

# CCMQ
CCMQ is a message queue framework built for iOS based on MMAP

## Features

### Reachability and Sequentiality：
CCMQ will ensure that messages must be sent to subscribers, CCMQ has serial and concurrent queues, serial queues will ensure that messages can be sent in order to reach subscribers in order, concurrent queues are able to send messages in batch, but the arrival order of the same batch of messages is not guaranteed.

### ACK：

#### Automatic ACK：
CCMQ supports automatic ACK, when the message reaches the subscriber, the subscriber will automatically reply ACK, when all subscribers reply ACK, it means the message is finished sending, will be removed from the queue and destroyed

#### Manual ACK:
CCMQ supports manual ACK, subscribers can manually reply ACK according to their needs

#### 3.Resend mechanism
CCMQ provides an automatic resend mechanism, when the subscriber timeout to send an ACK, CCMQ will perform a message retransmission

#### 4.Persistence
CCMQ persists messages, meaning that messages in the message queue will not be lost when the app is killed, and the message queue will resume sending messages after the app launch again.

## Getting Started

### Prerequisites：
CCMQ支持 iOS 6 以上
### Installation：
pod 'CCMQ'
### Initialize the queue：
```
//Initialize a searial queue
CCMQMessageQueue *searialQueue = [[CCMQMessageQueue alloc] initWithType:CCMQMessageQueueTypeSerial tag:@"serial"]

//Initialize a concurrent queue
CCMQMessageQueue *concurrentQueue = [[CCMQMessageQueue alloc] initWithType:CCMQMessageQueueTypeConcurrent tag:@"concurrent"];

//Set the number of messages to be sent in concurrent
concurrentQueue.maxConcurrentCount = 5;
```

### Send message：
CCMQ sends messages to subscribers by calling the following methods
```
CCMQMessage *message = [[CCMQMessage alloc] init];

//Set the message's content
message.message = "Datas";
[queue publish:message];
```

### 5.Subscribe to the message queue：
Each subscriber needs to set a port, which means the identity of that subscriber. When the APP is restarted, CCMQ uses port to determine which subscribers to resume sending messages to

**Note: When all ports reply ACK, it means the message is finished sending**
```
CCMQMessageSubscriber *subSerial = [[CCMQMessageSubscriber alloc] init];

//Set the port of subscriber
subSerial.port = @"sub1";
subSerial.subscribe = ^(CCMQMessage * _Nonnull message) {
    //Handle incoming messages here
    ...
    //For queues with manual ACKs, you need to do the ACK reply manually
    [queue finishMessage:message port:@"sub1"];
};
[queue addSubscriber:subSerial];
```
