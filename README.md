# How to build executable file under Linux for Windows 
## Install packages(example for Ubuntu or Debian)
````bash
$ sudo apt-get uodate && sudo apt-get install binutils-mingw-w64-i686 \
binutils-mingw-w64-x86-64 \
g++-mingw-w64-i686 \
g++-mingw-w64-x86-64 \
gcc-mingw-w64-base \
gcc-mingw-w64-i686 \
gcc-mingw-w64-x86-64 \
libz-mingw-w64 \
libz-mingw-w64-dev \
mingw-w64-common \
mingw-w64-i686-dev \
mingw-w64-tools \
mingw-w64-x86-64-dev \
mingw32 \
mingw32-binutils \
````

# How to link an application

````bash
x86_64-w64-mingw32-gcc -static main.c -L. -lcurl -lsupertor -I/root/libwinsupertor/src/tor/src/proxytor/ -I/root/libwinsupertor/src/tor/src/or -I/root/libwinsupertor/prefix-win/include/ -lssp -static-libgcc -static-libstdc++ -lws2_32 -o app-win-static.exe
````

````bash
x86_64-w64-mingw32-gcc main.c -L. -lsupertor  -I/root/libwinsupertor/prefix-win/include/ -I/root/libwinsupertor/src/tor/src/proxytor/ -o app-shared-win.exe
````