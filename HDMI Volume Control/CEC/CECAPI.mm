//
//  CecManager.m
//  HDMI Volume Control
//
//  Created by Ryan Sullivan on 1/3/15.
//  Copyright (c) 2015 Pickled Code. All rights reserved.
//

#import "CECAPI.h"
#import <libcec/cec.h>
#import <list>

#define DISPATCH_SYNC_RETURN_BOOL(queue, statement) \
    __block BOOL dispatchSyncReturnBoolResult;\
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
        _queue = dispatch_queue_create("me.rsullivan.apps.mac-cec-volume", DISPATCH_QUEUE_SERIAL);

        config = new libcec_configuration();
        config->Clear();
        snprintf(config->strDeviceName, 13, "mac-cec-volume");
        config->clientVersion = LIBCEC_VERSION_CURRENT;
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
    CECDestroy(adapter); adapter = NULL;
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

    // Fetch again using correct number of adapters
    if (real_count > count) {
        count = real_count;

        adapterList = (cec_adapter_descriptor*)realloc(adapterList, count * sizeof(cec_adapter_descriptor));

        dispatch_sync(_queue, ^{
            real_count = adapter->DetectAdapters(adapterList, count);
        });
    }
    
    if (count == -1) {
        NSLog(@"Failed to get adapters");
        free(adapterList);
        return adapters;
    }
    
    for (int i = 0; i < real_count; i++) {
        NSLog(@"found %s", adapterList[i].strComPath);
        adapters.push_back(adapterList[i]);
    }
    free(adapterList);

    return adapters;
}

-(BOOL)open:(const char *)devicePath {
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

-(void)debug {
    dispatch_sync(_queue, ^{
        cec_logical_addresses devices = adapter->GetActiveDevices();
        NSLog(@"primary device: %d", devices.primary);

        for (int i = 0; i < 16; i++)
        {
            cec_logical_address device = (cec_logical_address)i;
            if (!devices.IsSet(device)) {
                continue;
            }

            NSLog(@"*** device set: %d", i);

            NSLog(@"ping: %d", adapter->PingAdapter());
            NSLog(@"device cec version: %s", adapter->ToString(adapter->GetDeviceCecVersion(device)));

            std::string language = adapter->GetDeviceMenuLanguage(device);
            NSLog(@"device menu lang: %s", language.c_str());

            NSLog(@"device vendor id: %s", adapter->ToString((cec_vendor_id)adapter->GetDeviceVendorId(device)));
            NSLog(@"device power status: %s", adapter->ToString(adapter->GetDevicePowerStatus(device)));
            NSLog(@"device poll: %d", adapter->PollDevice(device));
            NSLog(@"device is active: %d", adapter->IsActiveDevice(device));
            NSLog(@"device osd name: %s", adapter->GetDeviceOSDName(device).c_str());
            NSLog(@"device is active source: %d", adapter->IsActiveSource(device));
        }
    });
}


-(BOOL)volumeUpKeydown {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->SendKeypress(CECDEVICE_AUDIOSYSTEM, CEC_USER_CONTROL_CODE_VOLUME_UP));
}
-(BOOL)volumeDownKeydown {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->SendKeypress(CECDEVICE_AUDIOSYSTEM, CEC_USER_CONTROL_CODE_VOLUME_DOWN));
}
-(BOOL)audioKeyup {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->SendKeyRelease(CECDEVICE_AUDIOSYSTEM));
}


-(BOOL)volumeUpKeypress {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->VolumeUp());
}

-(BOOL)volumeDownKeypress {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->VolumeDown());
}

-(BOOL)toggleMuteKeypress {
    DISPATCH_SYNC_RETURN_BOOL(_queue, adapter->AudioToggleMute());
}

@end
