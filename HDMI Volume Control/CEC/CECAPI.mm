//
//  CecManager.m
//  HDMI Volume Control
//
//  Created by Ryan Sullivan on 1/3/15.
//  Copyright (c) 2015 Pickled Code. All rights reserved.
//

#import "CECAPI.h"
#import <cec.h>
#import <list>

#define DISPATCH_SYNC_RETURN_BOOL(queue, statement) \
    __block bool dispatchSyncReturnBoolResult;\
    dispatch_sync(queue, ^{ dispatchSyncReturnBoolResult = statement; });\
    return dispatchSyncReturnBoolResult;

using namespace CEC;

@interface CECAPI ()
@property dispatch_queue_t queue;
@end

@implementation CECAPI {
    libcec_configuration *config;
    ICECCallbacks *callbacks;
    ICECAdapter *adapter;
}

-(instancetype)init {
    if ((self = [super init]))
    {
        _queue = dispatch_queue_create("com.pickledcode.apps.mac-cec-volume", DISPATCH_QUEUE_SERIAL);

        config = new libcec_configuration();
        config->Clear();
        snprintf(config->strDeviceName, 13, "mac-cec-volume");
        config->clientVersion = CEC_CLIENT_VERSION_CURRENT;
        config->bActivateSource = 0;
        config->deviceTypes.Add(CEC_DEVICE_TYPE_RECORDING_DEVICE);

        callbacks = new ICECCallbacks();
        callbacks->Clear();

        config->callbacks = callbacks;

        adapter = (ICECAdapter*)CECInitialise(config);

        if (!adapter) {
            NSLog(@"Failed to initalize libcec");
            return nil;
        }

        adapter->InitVideoStandalone();
    }
    return self;
}

-(void)dealloc {
    CECDestroy(adapter), adapter = NULL;
    delete callbacks;
    delete config;
}


-(std::list<cec_adapter_descriptor>)adapters {
    std::list<cec_adapter_descriptor> adapters;
    
    __block int count = 10;
    cec_adapter_descriptor *adapterList = (cec_adapter_descriptor*)malloc(count * sizeof(cec_adapter_descriptor));

    __block int real_count;
    dispatch_sync(_queue, ^{
        real_count = adapter->DetectAdapters(adapterList, count);
    });

    if (real_count > count) {
        count = real_count;

        adapterList = (cec_adapter_descriptor*)realloc(adapterList, count * sizeof(cec_adapter_descriptor));

        dispatch_sync(_queue, ^{
            count = adapter->DetectAdapters(adapterList, count);
        });
    }
    
    if (count == -1) {
        NSLog(@"Failed to get adapters");
        free(adapterList);
        return adapters;
    }
    
    for (int i = 0; i < count; i++) {
        adapters.push_back(adapterList[i]);
    }
    free(adapterList);
    
    return adapters;
}

-(bool)open:(const char *)devicePath {
    NSLog(@"Opening %s", devicePath);
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->Open(devicePath))
}

-(const char *)getDefaultDevicePath {
    std::list<cec_adapter_descriptor> adapters = [self adapters];
    if (adapters.size() > 0) {
        return adapters.front().strComPath;
    }
    return NULL;
}

-(void)volumeUp {
    dispatch_async(_queue, ^{
        adapter->VolumeUp();
    });
}
-(void)volumeDown {
    dispatch_async(_queue, ^{
        adapter->VolumeDown();
    });
}

-(void)toggleMute {
    dispatch_async(_queue, ^{
        adapter->MuteAudio();
    });
}

@end
