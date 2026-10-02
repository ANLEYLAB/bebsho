allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAndroidSettings = {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            val android = extensions.getByType(com.android.build.gradle.BaseExtension::class.java)
            
            // Force SDK 36 and minSdk 21 on all subprojects (vosk_flutter, flutter_tts, etc.)
            android.compileSdkVersion(36)
            android.defaultConfig.minSdkVersion(21)

            if (plugins.hasPlugin("com.android.library")) {
                val libraryExtension = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
                if (libraryExtension.namespace == null) {
                    if (name.contains("vosk")) {
                        libraryExtension.namespace = "org.vosk.vosk_flutter"
                    } else {
                        libraryExtension.namespace = "com.example.${name.replace("-", "_")}"
                    }
                }
            }
        }
    }

    if (state.executed) {
        configureAndroidSettings()
    } else {
        afterEvaluate {
            configureAndroidSettings()
        }
    }
}

subprojects {
    project.tasks.configureEach {
        if (name.contains("processDebugManifest") || name.contains("processReleaseManifest")) {
            doFirst {
                val manifestFile = file("${project.projectDir}/src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=\"")) {
                        manifestFile.writeText(content.replace(Regex("package=\"[^\"]*\""), ""))
                    }
                }
            }
        }
    }
}