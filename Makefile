#
# This Makefile heavily abuses the stamp idiom :-)
#

OPENSSL_VERSION ?= 1.0.2n
OPENSSL_URL = https://www.openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz

LIBEVENT_VERSION ?= 2.1.8-stable
LIBEVENT_URL = https://github.com/libevent/libevent/releases/download/release-$(LIBEVENT_VERSION)/libevent-$(LIBEVENT_VERSION).tar.gz

CURL_VERSION ?= 7.59.0
CURL_URL = https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz

MINGW  ?= mingw
HOST   ?= i686-w64-mingw32

CC     ?= $(HOST)-gcc
CXX    ?= $(HOST)-g++
CPP    ?= $(HOST)-cpp
LD     ?= $(HOST)-ld
AR     ?= $(HOST)-ar
RANLIB ?= $(HOST)-ranlib

PREFIX ?= $(PWD)/prefix

all: prepare tor

.PHONY: clean prepare

prepare:
	mkdir -p src dist prefix || true


#Curl

src/libcurl-fetch-stamp:
	wget $(CURL_URL) -P dist/
	touch $@

src/libcurl-unpack-stamp: src/libcurl-fetch-stamp
	tar xfzv dist/curl-${CURL_VERSION}.tar.gz -C src/
	touch $@

src/libcurl-build-stamp: src/libcurl-unpack-stamp
	cd src/curl-${CURL_VERSION} && \
	 	./configure --host=${HOST} --build=x86_64-linux-gnu \
	      --disable-rt --disable-ftp --disable-ldap --disable-ldaps --disable-rtsp --disable-dict \
              --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smb --disable-smtp \
              --disable-gopher --disable-sspi --disable-ntlm-wb --disable-tls-srp --without-zlib --disable-threaded-resolver \
              --disable-file --prefix=$(PREFIX) && \
		make && \
		make install
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
		--prefix=$(PREFIX) &&            \
		make &&                          \
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
		--prefix=$(PREFIX) &&              \
		make &&                            \
		make install
	touch $@

# Tor.
src/tor-fetch-stamp:
	git clone https://git.torproject.org/tor.git src/tor
	touch $@

src/tor-configure-stamp: src/tor-fetch-stamp
	cd src/tor && ./autogen.sh
	touch $@

tor: src/tor-configure-stamp src/libevent-build-stamp src/openssl-build-stamp src/libcurl-build-stamp
	cd src/tor &&                          \
		./configure --host=$(HOST)         \
		--disable-asciidoc                 \
		--disable-zstd                     \
		--disable-lzma                     \
		--enable-static-libevent           \
		--with-libevent-dir=$(PREFIX)      \
		--enable-static-openssl            \
		--with-openssl-dir=$(PREFIX)       \
		--prefix=$(PREFIX) &&              \
		make &&                            \
		make install

clean:
	rm -rf src/* dist/* prefix/* || true
