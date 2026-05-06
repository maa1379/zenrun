import com.android.build.gradle.BaseExtension
import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    subprojects {
        afterEvaluate {
            if (extensions.findByName("android") != null) {
                extensions.configure<BaseExtension>("android") {
                    if (namespace == null) {
                        namespace = project.group.toString()
                    }
                }
            }
        }
    }

    // ✅ فیکس dependency conflicts
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.fragment:fragment:1.7.1")
            force("androidx.activity:activity:1.8.1")
            force("androidx.lifecycle:lifecycle-runtime:2.7.0")
            force("androidx.lifecycle:lifecycle-livedata:2.7.0")
            force("androidx.lifecycle:lifecycle-livedata-core:2.7.0")
            force("androidx.lifecycle:lifecycle-livedata-core-ktx:2.7.0")
            force("androidx.lifecycle:lifecycle-viewmodel:2.7.0")
            force("androidx.lifecycle:lifecycle-viewmodel-savedstate:2.7.0")
            force("androidx.lifecycle:lifecycle-process:2.7.0")
            force("androidx.savedstate:savedstate:1.2.1")
            force("androidx.profileinstaller:profileinstaller:1.3.1")
            force("androidx.tracing:tracing:1.2.0")
            force("androidx.arch.core:core-runtime:2.2.0")
            force("androidx.window:window:1.2.0")
            force("androidx.window:window-java:1.2.0")
            force("androidx.window.extensions.core:core:1.0.0")
            force("androidx.annotation:annotation-experimental:1.4.0")
        }
    }
}

subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") ||
            plugins.hasPlugin("com.android.library")) {

            extensions.configure<BaseExtension>("android") {
                compileSdkVersion(36)
                buildToolsVersion("36.0.0")
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(name)
    layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
