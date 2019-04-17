#include <jni.h>
#include <string>
#include <android/log.h>
#include <stdexcept>

extern "C" JNIEXPORT jstring JNICALL
Java_com_bugsnagreactnativeexample_CrashyModule_stringFromJNI(
        JNIEnv* env,
        jobject /* this */) {
    std::string hello = "Hello from C++";
    throw std::runtime_error("womp womp");
    return env->NewStringUTF(hello.c_str());
}

