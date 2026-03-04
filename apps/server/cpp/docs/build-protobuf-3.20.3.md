# fps-zombie-multiplayer-backend

## Protobuf 3.20.3 (Windows + Linux for UE cross-compile)

### Prerequisites
- Git
- CMake
- Visual Studio 2022 (C++ workload)
- Ninja (optional but recommended for Linux cross-compile)
- Unreal Linux toolchain installed and:
  - `LINUX_MULTIARCH_ROOT` set to something like:
    `C:\UnrealToolchains\v25_clang-18.1.0-rockylinux8\`

---

## Option (Optional): vcpkg (Windows only)
If you just want Protobuf on Windows for non-UE usage:

```bat
git clone https://github.com/microsoft/vcpkg
cd vcpkg
bootstrap-vcpkg.bat
vcpkg install protobuf:x64-windows
````

For UE ThirdParty, you usually build from source to control CRT/static/shared flags.

---

## Build from source (recommended for UE ThirdParty)

### 0) Clone Protobuf v3.20.3

```bat
git clone --branch v3.20.3 --depth 1 https://github.com/protocolbuffers/protobuf.git protobuf-3.20.3
```

---

## 1) Windows build (MSVC, static libs)

> Run in **Developer Command Prompt for VS 2022** (or a normal cmd with VS environment).

```bat
cd protobuf-3.20.3

mkdir build-win
cmake -S cmake -B build-win -G "Visual Studio 17 2022" -A x64 ^
  -Dprotobuf_BUILD_TESTS=OFF ^
  -Dprotobuf_MSVC_STATIC_RUNTIME=OFF ^
  -DBUILD_SHARED_LIBS=OFF ^
  -DCMAKE_INSTALL_PREFIX="%cd%\install-win"

cmake --build build-win --config Release
cmake --build build-win --config Debug

cmake --install build-win --config Release
cmake --install build-win --config Debug
```

Expected (examples):

* `install-win\include\google\protobuf\...`
* `install-win\lib\protobuf.lib` (Release)
* `install-win\lib\protobufd.lib` (Debug)

---

## 2) Linux build (cross-compile from Windows using Unreal toolchain)

### 2.1 Verify toolchain (PowerShell)

```powershell
$Env:LINUX_MULTIARCH_ROOT
$clangpp = Join-Path $Env:LINUX_MULTIARCH_ROOT "x86_64-unknown-linux-gnu\bin\clang++.exe"
Test-Path $clangpp
& $clangpp -v
```

### 2.2 Create `ue-linux.toolchain.cmake` in `protobuf-3.20.3`

Create `protobuf-3.20.3\ue-linux.toolchain.cmake`:

```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(UE_TRIPLE "x86_64-unknown-linux-gnu")

if(NOT DEFINED ENV{LINUX_MULTIARCH_ROOT})
  message(FATAL_ERROR "LINUX_MULTIARCH_ROOT is not set")
endif()

file(TO_CMAKE_PATH "$ENV{LINUX_MULTIARCH_ROOT}" UE_TC_ROOT)
string(REGEX REPLACE "/?$" "/" UE_TC_ROOT "${UE_TC_ROOT}")

set(UE_SYSROOT "${UE_TC_ROOT}${UE_TRIPLE}")

set(CMAKE_C_COMPILER   "${UE_SYSROOT}/bin/clang.exe")
set(CMAKE_CXX_COMPILER "${UE_SYSROOT}/bin/clang++.exe")
set(CMAKE_AR           "${UE_SYSROOT}/bin/llvm-ar.exe")
set(CMAKE_RANLIB       "${UE_SYSROOT}/bin/llvm-ranlib.exe")
set(CMAKE_LINKER       "${UE_SYSROOT}/bin/ld.lld.exe")

set(CMAKE_C_COMPILER_TARGET   "${UE_TRIPLE}")
set(CMAKE_CXX_COMPILER_TARGET "${UE_TRIPLE}")

set(CMAKE_SYSROOT "${UE_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH "${UE_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Prevent try-run during cross-compile
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Build static libs usable inside UE Linux .so modules
set(CMAKE_C_FLAGS_INIT   "--target=${UE_TRIPLE} --sysroot=${UE_SYSROOT} -fPIC")
set(CMAKE_CXX_FLAGS_INIT "--target=${UE_TRIPLE} --sysroot=${UE_SYSROOT} -fPIC")
```

### 2.3 Configure / build / install Linux Release (PowerShell)

```powershell
cd protobuf-3.20.3

$tcRoot = "C:\UnrealToolchains\v25_clang-18.1.0-rockylinux8\x86_64-unknown-linux-gnu"
$cc  = Join-Path $tcRoot "bin\clang.exe"
$cxx = Join-Path $tcRoot "bin\clang++.exe"

$src = "C:\Workspace\GameStudio\BackendFps\fps-zombie-multiplayer-backend\protobuf-3.20.3"
$bld = Join-Path $src "build-linux-release"
$ins = Join-Path $src "install-linux-release"

Remove-Item -Recurse -Force $bld -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $ins -ErrorAction SilentlyContinue

cmake -S (Join-Path $src "cmake") -B $bld -G Ninja `
  -DCMAKE_TOOLCHAIN_FILE="$src\ue-linux.toolchain.cmake" `
  -DCMAKE_C_COMPILER="$cc" `
  -DCMAKE_CXX_COMPILER="$cxx" `
  -DCMAKE_BUILD_TYPE=Release `
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON `
  -Dprotobuf_BUILD_TESTS=OFF `
  -Dprotobuf_BUILD_EXAMPLES=OFF `
  -DBUILD_SHARED_LIBS=OFF `
  -Dprotobuf_BUILD_PROTOC_BINARIES=OFF `
  -DCMAKE_CXX_FLAGS="-stdlib=libc++" `
  -DCMAKE_EXE_LINKER_FLAGS="-stdlib=libc++" `
  -DCMAKE_INSTALL_PREFIX="$ins"

cmake --build $bld
cmake --install $bld

```

Expected:

* `install-linux-release\include\google\protobuf\...`
* `install-linux-release\lib\libprotobuf.a`

(Optional) Debug build:

```powershell
$bldD = Join-Path $src "build-linux-debug"
$insD = Join-Path $src "install-linux-debug"

Remove-Item -Recurse -Force $bldD -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $insD -ErrorAction SilentlyContinue

cmake -S (Join-Path $src "cmake") -B $bldD -G Ninja `
  -DCMAKE_TOOLCHAIN_FILE="$src\ue-linux.toolchain.cmake" `
  -DCMAKE_BUILD_TYPE=Debug `
  -Dprotobuf_BUILD_TESTS=OFF `
  -Dprotobuf_BUILD_EXAMPLES=OFF `
  -DBUILD_SHARED_LIBS=OFF `
  -Dprotobuf_BUILD_PROTOC_BINARIES=OFF `
  -DCMAKE_INSTALL_PREFIX="$insD"

cmake --build $bldD
cmake --install $bldD
```

---

## UE ThirdParty folder layout (recommended)

* `ThirdParty/Protobuf/include`  ← copy from either install’s `include` (same)
* `ThirdParty/Protobuf/lib/Win64/...` ← `.lib` from `install-win\lib`
* `ThirdParty/Protobuf/lib/Linux/...` ← `.a` from `install-linux-*\lib`

Note: keep using **Windows `protoc.exe`** for code generation; do not try to run a Linux `protoc` on Windows.
