package com.bugsnagreactnativeexample;

import android.os.Bundle;
import com.facebook.react.ReactActivity;
import com.bugsnag.BugsnagReactNative;

public class MainActivity extends ReactActivity {

    /**
     * Returns the name of the main component registered from JavaScript.
     * This is used to schedule rendering of the component.
     */
    @Override
    protected String getMainComponentName() {
        return "BugsnagReactNativeExample";
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        BugsnagReactNative.start(this);
    }
}
