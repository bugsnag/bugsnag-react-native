package com.bugsnag;

import com.bugsnag.android.JsonStream;

import org.junit.Test;

import java.io.BufferedWriter;
import java.io.Writer;

import static org.junit.Assert.*;

public class JavaScriptExceptionTest {

    @Test
    public void javaScriptException_parsesStandardExceptions() {
        Writer w; //get writer somehow
        JsonStream j = new JsonStream(w);
        JavaScriptException je = new JavaScriptException("TypeError", "undefined is not a function", "sdfjkldsf\nsdjklasd\nsddjskf");
        try {
            je.toStream(j);
            // make assertion about what was written to writer
        } catch (Exception e) {
            assertNull("Exception should not be thrown", e);
        }
    }

//    @Test
//    public void javaScriptException_parsesHermesExceptions() {
//    }

}