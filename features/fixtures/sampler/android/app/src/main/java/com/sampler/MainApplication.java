package com.sampler;

import android.app.Application;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.pm.ApplicationInfo;

import com.facebook.react.ReactApplication;
import com.lugg.ReactNativeConfig.ReactNativeConfigPackage;
import com.bugsnag.BugsnagReactNative;
import com.bugsnag.android.Configuration;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.react.shell.MainReactPackage;
import com.facebook.soloader.SoLoader;

import java.util.Arrays;
import java.util.List;

public class MainApplication extends Application implements ReactApplication {

  private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {
    @Override
    public boolean getUseDeveloperSupport() {
      return BuildConfig.DEBUG;
    }

    @Override
    protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new MainReactPackage(),
          new ReactNativeConfigPackage(),
          BugsnagReactNative.getPackage(),
          new CustomMethodsPackage()
      );
    }

    @Override
    protected String getJSMainModuleName() {
      return "index";
    }
  };

  @Override
  public ReactNativeHost getReactNativeHost() {
    return mReactNativeHost;
  }

  @Override
  public void onCreate() {
    super.onCreate();
    boolean enableANR = false;
    int anrTimeout = 0;
    try {
      ApplicationInfo ai = getPackageManager().getApplicationInfo(getPackageName(), PackageManager.GET_META_DATA);
      String rawEnableANR = (String) ai.metaData.get("enable-anr");
      enableANR = Boolean.parseBoolean(rawEnableANR);
      anrTimeout = Integer.parseInt((String) ai.metaData.get("anr-timeout"));
    } catch (NameNotFoundException e) {
      throw new RuntimeException("An error occurred reading .env values", e);
    }
    Configuration config = new Configuration("my API key!");
    config.setDetectAnrs(enableANR);
    if (anrTimeout > 0) {
      config.setAnrThresholdMs(anrTimeout);
    }
    BugsnagReactNative.startWithConfiguration(this, config);
    SoLoader.init(this, /* native exopackage */ false);
  }
}
