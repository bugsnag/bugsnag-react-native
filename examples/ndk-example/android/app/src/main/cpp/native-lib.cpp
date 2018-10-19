#include <jni.h>
#include <string>
#include <stdlib.h>
#include <signal.h>
#include <bugsnag.h>

extern "C" {

JNIEXPORT jint JNICALL
Java_com_garuth_FancyModule_somethingInnocuousFromJNI(
    JNIEnv *env,
    jobject _this,
    jint input) {
  if (input > 13) {
    //return par_vs(input, 2);
    raise(SIGSEGV);
  }
  int value = input / (input - 34);
  printf("Something innocuous this way comes: %d\n", value);
  return value;
}

}
