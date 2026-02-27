// 1. ADD THIS IMPORT AT THE VERY TOP
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom Build Directory Logic
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// --- GLOBAL NEURAL PATCH: NAMESPACE & JVM 17 ALIGNMENT ---
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension

            // FORCE NAMESPACE (Fixes AGP 8.0+ Errors)
            if (android.namespace == null) {
                android.namespace = "com.habito_ai.${project.name.replace("-", "_")}"
            }

            // FORCE SDK & JAVA VERSION (Targeting Android 16 APIs)
            android.compileSdkVersion("android-36")
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    // 2. MODERN KOTLIN DSL: Replaces deprecated 'kotlinOptions'
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            // Use .set() with the JvmTarget enum for Kotlin 2.2.0+
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}