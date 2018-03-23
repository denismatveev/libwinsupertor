#
#

OPENSSL_VERSION ?= 1.0.2n
OPENSSL_URL = https://www.openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz

LIBEVENT_VERSION ?= 2.1.8-stable
LIBEVENT_URL = https://github.com/libevent/libevent/releases/download/release-$(LIBEVENT_VERSION)/libevent-$(LIBEVENT_VERSION).tar.gz

CURL_VERSION ?= 7.59.0
CURL_URL = https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
ZLIB_VERSION ?= 1.2.11
ZLIB_URL = http://zlib.net/zlib-$(ZLIB_VERSION).tar.gz
MINGW  ?= mingw
HOST   ?= i686-w64-mingw32

CC     ?= $(HOST)-gcc
CXX    ?= $(HOST)-g++
CPP    ?= $(HOST)-cpp
LD     ?= $(HOST)-ld
AR     ?= $(HOST)-ar
RANLIB ?= $(HOST)-ranlib

PREFIX_DIR ?= $(PWD)/prefix-win
CPPFLAGS ?= "-I/usr/i686-w64-mingw32/include/ -I${PREFIX_DIR}/include"
LDFLAGS ?= "-L/usr/i686-w64-mingw32/lib/ -L${PREFIX_DIR}/lib"
#export LDFLAGS="$LDFLAGS -L/usr/i686-w64-mingw32/lib/ -L/root/libwinsupertor/prefix-win/lib"
#export LIBS="$LIBS -l:libssl.dll.a -l:libevent.dll.a -l:libcrypto.dll.a -l:libz.dll.a -l:libpthread.dll.a -l:libcurl.dll.a -lws2_32"

all: prepare sharedlib

.PHONY: clean prepare

prepare:
	mkdir -p src dist prefix || true


#ZLIB static
src/zlib-fetch-stamp:
	wget $(ZLIB_URL) -P dist/
	touch $@
src/zlib-unpack-stamp: src/zlib-fetch-stamp
	tar xfzv dist/zlib-${ZLIB_VERSION}.tar.gz -C src/
	touch $@
src/zlib-build-stamp: src/zlib-unpack-stamp
	cd src/zlib-${ZLIB_VERSION} && \
	make -f win32/Makefile.gcc BINARY_PATH=${PREFIX_DIR}/bin INCLUDE_PATH=${PREFIX_DIR}/include LIBRARY_PATH=${PREFIX_DIR}/lib SHARED_MODE=1 PREFIX=${HOST}- install
	touch $@
	
# OpenSSL.
src/openssl-fetch-stamp:
	wget $(OPENSSL_URL) -P dist/
	touch $@

src/openssl-unpack-stamp: src/openssl-fetch-stamp
	tar zxfv dist/openssl-$(OPENSSL_VERSION).tar.gz -C src/
	touch $@

src/openssl-build-stamp: src/openssl-unpack-stamp
	cd src/openssl-$(OPENSSL_VERSION) && \
		./Configure $(MINGW) shared      \
		--cross-compile-prefix=$(HOST)-  \
		--prefix=$(PREFIX_DIR) &&            \
		make -j4 &&                          \
		make install
	touch $@

#Curl

src/libcurl-fetch-stamp: 
	wget $(CURL_URL) -P dist/
	touch $@

src/libcurl-unpack-stamp: src/libcurl-fetch-stamp
	tar xfzv dist/curl-${CURL_VERSION}.tar.gz -C src/
	touch $@

src/libcurl-build-stamp: src/libcurl-unpack-stamp src/openssl-build-stamp 
	cd src/curl-${CURL_VERSION} && \
	 	./configure --host=${HOST} --build=x86_64-linux-gnu \
	      --disable-rt --disable-ftp --disable-ldap --disable-ldaps --disable-rtsp --disable-dict \
              --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smb --disable-smtp \
              --disable-gopher --disable-sspi --disable-ntlm-wb --disable-tls-srp --without-zlib --disable-threaded-resolver \
              --disable-file --with-ssl=$(PREFIX_DIR) --prefix=$(PREFIX_DIR) && \
		make -j4 && \
		make install
	touch $@
# Libevent.
src/libevent-fetch-stamp:
	wget $(LIBEVENT_URL) -P dist/
	touch $@

src/libevent-unpack-stamp: src/libevent-fetch-stamp
	tar zxfv dist/libevent-$(LIBEVENT_VERSION).tar.gz -C src/
	touch $@

src/libevent-build-stamp: src/libevent-unpack-stamp
	cd src/libevent-$(LIBEVENT_VERSION) && \
		./configure --host=$(HOST)         \
		--prefix=$(PREFIX_DIR) &&              \
		make -j4 &&                            \
		make install
	touch $@
# libsupertor

src/libsupertor-fetch-stamp: src/tor-fetch-stamp
	git clone https://denismatveev@bitbucket.org/denismatveevteam/libsupertor.git src/libsupertor
	touch $@

src/libsupertor-patch-stamp: src/libsupertor-fetch-stamp
	cp -r src/libsupertor/tor/src src/tor/
	cp src/libsupertor/tor/configure.ac src/tor/
	touch $@
	
# libdl

src/libdl-fetch-stamp:
	git clone https://github.com/dlfcn-win32/dlfcn-win32.git src/dlfcn-win32
	touch $@
src/libdl-configure-stamp: src/libdl-fetch-stamp
	cd src/dlfcn-win32 && ./configure --prefix=${PREFIX_DIR} \
					--cross-prefix=${HOST}- \
					--enable-static
	touch $@
src/libdl-build-stamp: src/libdl-configure-stamp
	cd src/dlfcn-win32 && \
	make -j4 && make install
	touch $@

# Tor.
src/tor-fetch-stamp:
	git clone https://git.torproject.org/tor.git src/tor
	touch $@

src/tor-configure-stamp: src/tor-fetch-stamp
	cd src/tor && ./autogen.sh
	touch $@

staticlib: src/tor-configure-stamp src/libevent-build-stamp src/libcurl-build-stamp src/zlib-build-stamp src/libsupertor-patch-stamp src/libdl-build-stamp
	cd src/tor &&                          \
		./configure --host=$(HOST)         \
		--enable-static-tor		   \
		--disable-asciidoc                 \
		--disable-zstd                     \
		--disable-lzma                     \
		--with-zlib-dir=$(PREFIX_DIR)/lib          \
		--enable-static-libevent           \
		--with-libevent-dir=$(PREFIX_DIR)  \
		--enable-static-openssl            \
		--with-openssl-dir=$(PREFIX_DIR)/lib       \
  		--with-libcurl-dir=${PREFIX_DIR}/lib	\
		--with-libpthread-dir=/usr/i686-w64-mingw32/lib \
		--with-libm-dir=/usr/i686-w64-mingw32/lib \
		--with-libdl-dir=${PREFIX_DIR}/lib \
		--prefix=$(PREFIX_DIR) &&              \
		make -j4 && make staticlibs &&             \

	touch $@
sharedlib: src/tor-configure-stamp src/libevent-build-stamp src/libcurl-build-stamp src/libsupertor-patch-stamp src/libdl-build-stamp src/zlib-build-stamp
	cd src/tor && ./configure --host=$(HOST) \
				  --enable-shared-libs \
				  --disable-asciidoc \
				  --disable-zstd     \
                		  --disable-lzma  \
				  --with-libpthread-dir=/usr/i686-w64-mingw32/lib \
				  --with-openssl-dir=$(PREFIX_DIR)/lib       \
				  --with-libcurl-dir=${PREFIX_DIR}/lib	\
				  --with-libdl-dir=${PREFIX_DIR}/lib \
				  --with-libm-dir=/usr/i686-w64-mingw32/lib \
 				  --prefix=$(PREFIX_DIR) && \
				  make -j4 && make sharedlibs && \
	touch $@

				  

clean:
	rm -rf src/* dist/* prefix/* || true
