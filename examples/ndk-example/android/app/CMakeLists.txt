cmake_minimum_required(VERSION 3.4.1)

add_library( # Sets the name of the library.
             native-lib

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             src/main/cpp/native-lib.cpp )

add_library(lib_bugsnag SHARED IMPORTED)
set(BUGSNAG_LIB_DIR
    ${CMAKE_SOURCE_DIR}/build/intermediates/bugsnag-libs)
set(BUGSNAG_INCLUDE_DIR ${BUGSNAG_LIB_DIR}/assets/include)
set_target_properties(lib_bugsnag PROPERTIES IMPORTED_LOCATION
                      ${BUGSNAG_LIB_DIR}/jni/${ANDROID_ABI}/libbugsnag-ndk.so)
target_include_directories(native-lib PRIVATE ${BUGSNAG_INCLUDE_DIR})
target_link_libraries(native-lib lib_bugsnag)

find_library( # Sets the name of the path variable.
              log-lib

              # Specifies the name of the NDK library that
              # you want CMake to locate.
              log )

# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

target_link_libraries( # Specifies the target library.
                       native-lib

                       # Links the target library to the log library
                       # included in the NDK.
                       ${log-lib} )
