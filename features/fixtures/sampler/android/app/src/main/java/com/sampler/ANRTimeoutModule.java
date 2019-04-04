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

public class ANRTimeoutModule extends ReactContextBaseJavaModule {

    public ANRTimeoutModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "ANRTimeout";
    }

    @ReactMethod
    public void triggerANR(final int timeout) {
        Log.i("ANR", String.format("ANR triggered; timeout: %s", timeout));
        getCurrentActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    Thread.sleep(timeout);
                }
                catch (InterruptedException e) {

                }
            }
        });
    }
}