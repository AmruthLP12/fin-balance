# flutter_local_notifications stores scheduled reminders with Gson; R8 must keep
# the generic type information or loading them fails with "Missing type parameter".
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
