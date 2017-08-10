package com.bugsnagreactnativeexample;

import android.app.Application;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;

import com.facebook.react.ReactApplication;
import com.microsoft.codepush.react.CodePush;
import com.bugsnag.BugsnagReactNative;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.react.shell.MainReactPackage;
import com.facebook.soloader.SoLoader;
import com.bugsnag.BugsnagReactNative;

import java.util.Arrays;
import java.util.List;

public class MainApplication extends Application implements ReactApplication {

  private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {

    @Override
    protected String getJSBundleFile() {
      return CodePush.getJSBundleFile();
    }

    @Override
    public boolean getUseDeveloperSupport() {
      return BuildConfig.DEBUG;
    }

    @Override
    protected List<ReactPackage> getPackages() {
      Context appContext = getApplicationContext();
      String codePushDeploymentKey = null;
      try {
        ApplicationInfo ai = appContext.getPackageManager().getApplicationInfo(appContext.getPackageName(), PackageManager.GET_META_DATA);
        Bundle data = ai.metaData;
        codePushDeploymentKey = data.getString("com.microsoft.codepush.DEPLOYMENT_KEY");
      } catch (Exception ignore) {
      }
      return Arrays.<ReactPackage>asList(
          new MainReactPackage(),
          new CodePush(codePushDeploymentKey, appContext, BuildConfig.DEBUG),
          new CrashyPackage(),
          BugsnagReactNative.getPackage()
      );
    }
  };

  @Override
  public ReactNativeHost getReactNativeHost() {
    return mReactNativeHost;
  }

  @Override
  public void onCreate() {
    super.onCreate();
    BugsnagReactNative.start(this);
    SoLoader.init(this, /* native exopackage */ false);
  }
}
