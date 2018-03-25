# How to link an application

````bash
x86_64-w64-mingw32-gcc -static main.c -L. -lcurl -lsupertor -I/root/libwinsupertor/src/tor/src/proxytor/ -I/root/libwinsupertor/src/tor/src/or -I/root/libwinsupertor/prefix-win/include/ -lssp -static-libgcc -static-libstdc++ -lws2_32 -o app-win-static.exe
````

````bash
x86_64-w64-mingw32-gcc main.c -L. -lsupertor  -I/root/libwinsupertor/prefix-win/include/ -I/root/libwinsupertor/src/tor/src/proxytor/ -o app-shared-win.exe
````