allprojects {
    repositories {
        google()
        mavenCentral()
        // freeRASP (Talsec) native kutubxonasi — Maven Central'da emas.
        // Plagin o'zi ham e'lon qiladi, lekin Gradle loyiha darajasidagi
        // repozitoriylarni e'tiborsiz qoldirishi mumkin — shu sabab bu yerda.
        maven { url = uri("https://europe-west3-maven.pkg.dev/talsec-artifact-repository/freerasp") }
        maven { url = uri("https://europe-west3-maven.pkg.dev/talsec-artifact-repository/common") }
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
