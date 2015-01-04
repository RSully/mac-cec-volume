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
    __block bool dsrbResult;\
    dispatch_sync(queue, ^{ dsrbResult = statement; });\
    return dsrbResult;

using namespace CEC;

@implementation CECAPI {
    libcec_configuration *config;
    ICECCallbacks *callbacks;
    ICECAdapter *adapter;

    dispatch_queue_t queue;
}

-(instancetype)init {
    if ((self = [super init]))
    {
        queue = dispatch_queue_create("com.pickledcode.apps.mac-cec-volume", DISPATCH_QUEUE_SERIAL);

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
    std::list<cec_adapter_descriptor> devices;
    
    int count = 10;
    cec_adapter_descriptor *deviceList = (cec_adapter_descriptor*)malloc(count * sizeof(cec_adapter_descriptor));
    int real_count = adapter->DetectAdapters(deviceList, count);
    
    if (real_count > count) {
        count = real_count;
        
        deviceList = (cec_adapter_descriptor*)realloc(deviceList, count * sizeof(cec_adapter_descriptor));
        count = adapter->DetectAdapters(deviceList, count);
    }
    
    if (count == -1) {
        NSLog(@"Failed to get adapters");
        free(deviceList);
        return devices;
    }
    
    for (int i = 0; i < count; i++) {
        devices.push_back(deviceList[i]);
    }
    free(deviceList);
    
    return devices;
}

-(bool)initialize:(const char*)device {
    std::list<cec_adapter_descriptor> devices = [self adapters];
    
    if (device == NULL && devices.size() > 0) {
        device = devices.front().strComPath;
    }
    
    NSLog(@"Opening %s", device);

    DISPATCH_SYNC_RETURN_BOOL(queue, adapter->Open(device))
}

-(void)volumeUp {
    dispatch_async(queue, ^{
        adapter->VolumeUp();
    });
}
-(void)volumeDown {
    dispatch_async(queue, ^{
        adapter->VolumeDown();
    });
}

@end
