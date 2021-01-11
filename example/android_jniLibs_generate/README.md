# Download jniLibs

Based on es_compression 0.9.9 : [https://github.com/isong0623/android_lib_es_compression0_9_9/releases/tag/v1.0](https://github.com/isong0623/android_lib_es_compression0_9_9/releases/tag/v1.0)

# Build jniLibs

Suppose you have Android Studio installed and Windows for your operating system.

**It's very easy to build android jni(*.so) library ,please take the following steps:**

* 1、Download CMake : [https://github.com/Kitware/CMake/releases/tag/v3.17.2](https://github.com/Kitware/CMake/releases/tag/v3.17.2)

* 2、Clone the git repository to your local dir.

* 3、Open this project("es_compression\example\android_jniLibs_generate").

* 4、Install NDK for Android Studio:
    Click File-> settings-> Appearance&Behavior-> System Settings -> Android SDK-> SDK Tools.
    (Tips: I installed '21.0' and '16.1'.)

* 5、Move "es_compression\example\android_jniLibs_generate\ninja.exe" to "\${CMake_Install_Path}/bin/".
(Note: This ninja.exe is copy from "\${Android_SDK}\cmake\3.10.2.4988404\bin\")
* 6、Config the Android SDK path and CMake Path in *"es_compression\example\android_jniLibs_generate\local.properties"* correctly.

* 7、Then 'Sync' your native project gradle dependencies and cmake dependencies.

* 8、Click Build->Make Project,when build finished, then you can see the jni libs in
"\${Project_Path}/app/build/intermediates/stripped_native_libs/debug/out/lib/"
maybe or
"\${Project_Path}/app/.cxx/cmake/debug/".

###### Be patient, the whole process took me about two hours.
###### It depends on the speed at which Git downloads.
# Now,enjoy this powerful compress tools.
# Good luck,everyone!