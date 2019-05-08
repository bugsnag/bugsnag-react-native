package com.sampler;

import android.util.Log;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.os.Bundle;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.bugsnag.android.Bugsnag;
import com.bugsnag.android.Client;
import com.bugsnag.android.Configuration;

public class NativeErrorModule extends ReactContextBaseJavaModule {

    public NativeErrorModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "NativeError";
    }

    @ReactMethod
    public void triggerNativeError() {
        throw new RuntimeException("triggeredNativeError");
    }
}