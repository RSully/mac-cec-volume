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

#define DEFAULT_TIMEOUT_MS 2500

using namespace CEC;

@interface CECAPI ()
@property dispatch_queue_t queue;
@end

@implementation CECAPI {
    libcec_configuration *config;
    ICECCallbacks *callbacks;
    ICECAdapter *adapter;

    BOOL _didOpen;
}

-(instancetype)init {
    if ((self = [super init]))
    {
        _didOpen = NO;
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
    if (_didOpen) {
        NSLog(@"CEC open called, but already open");
        return NO;
    }

    NSLog(@"Opening %s", devicePath);

    dispatch_sync(_queue, ^{
        _didOpen = adapter->Open(devicePath, DEFAULT_TIMEOUT_MS);
    });
    return _didOpen;
}

-(const char *)getDefaultDevicePath {
    std::list<cec_adapter_descriptor> adapters = [self adapters];
    if (adapters.size() > 0) {
        return adapters.front().strComPath;
    }
    return NULL;
}



-(bool)volumeUpKeydown {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->SendKeypress(CECDEVICE_AUDIOSYSTEM, CEC_USER_CONTROL_CODE_VOLUME_UP));
}
-(bool)volumeDownKeydown {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->SendKeypress(CECDEVICE_AUDIOSYSTEM, CEC_USER_CONTROL_CODE_VOLUME_DOWN));
}
-(bool)audioKeyup {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->SendKeyRelease(CECDEVICE_AUDIOSYSTEM));
}


-(bool)volumeUpKeypress {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->VolumeUp());
}

-(bool)volumeDownKeypress {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->VolumeDown());
}

-(bool)toggleMuteKeypress {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->AudioToggleMute());
}

@end
