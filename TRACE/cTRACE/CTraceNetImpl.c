#include "defs.h"
#include "jni.h"
#include "CTraceNet.h"
#include <stdio.h>

JNIEXPORT void JNICALL 
Java_CTraceNet_runTrace(JNIEnv *env, jobject obj) 
{
    printf("Hello world!\n");
    return;
}
