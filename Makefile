#
# libbsd
#

LIB_NAME = libbsd
LIB_VERSION_MAJOR = 0
LIB_VERSION_MINOR = 0
LIB_VERSION := $(LIB_VERSION_MAJOR).$(LIB_VERSION_MINOR)

LIB_PKGCONFIG := $(LIB_NAME).pc
LIB_STATIC := $(LIB_NAME).a
LIB_SHARED_SO := $(LIB_NAME).so
LIB_SONAME := $(LIB_SHARED_SO).$(LIB_VERSION_MAJOR)
LIB_SHARED := $(LIB_SONAME).$(LIB_VERSION_MINOR)

TAR_NAME := $(LIB_NAME)-$(LIB_VERSION)
TAR_FILE := $(TAR_NAME).tar.gz

LIB_DIST := Makefile ChangeLog Versions $(LIB_PKGCONFIG)

LIB_SRCS := arc4random.c bsd_getopt.c err.c fgetln.c heapsort.c \
	    humanize_number.c inet_net_pton.c \
	    hash/md5.c hash/md5hl.c \
	    setmode.c \
	    strlcat.c strlcpy.c fmtcheck.c progname.c vis.c unvis.c
LIB_SRCS := $(patsubst %,src/%,$(LIB_SRCS))

LIB_GEN_SRCS := \
	man/md5.3 \
	src/hash/md5hl.c

LIB_INCLUDES := bsd/err.h bsd/getopt.h bsd/ip_icmp.h bsd/random.h bsd/queue.h bsd/md5.h bsd/string.h \
		bsd/bsd.h bsd/cdefs.h bsd/stdlib.h vis.h libutil.h

LIB_MANS := arc4random.3 strlcpy.3 fgetln.3 fmtcheck.3 setmode.3 md5.3
LIB_MANS := $(patsubst %,man/%,$(LIB_MANS))

LIB_STATIC_OBJS = $(LIB_SRCS:%.c=%.o)
LIB_SHARED_OBJS = $(LIB_SRCS:%.c=%.lo)

MK_CFLAGS = -Iinclude/ -include bsd/bsd.h -D_GNU_SOURCE -D__REENTRANT

prefix		:= /usr
exec_prefix	:=
libdir		:= ${exec_prefix}/lib
usrlibdir	:= ${prefix}/lib
includedir	:= ${prefix}/include
pkgconfigdir	:= ${usrlibdir}/pkgconfig
mandir		:= ${prefix}/share/man

libs: $(LIB_STATIC) $(LIB_SHARED_SO)

man: $(LIB_MANS)

%.lo: %.c
	$(CC) -o $@ $(MK_CFLAGS) $(CFLAGS) -DPIC -fPIC -c $<

%.o: %.c
	$(CC) -o $@ $(MK_CFLAGS) $(CFLAGS) -c $<

man/md5.3:  man/mdX.3
	sed -e 's/mdX/md5/g' -e 's/mdY/md4/g' -e 's/MDX/MD5/g' $< > $@

src/hash/md5hl.c: src/hash/helper.c
	sed -e 's:hashinc:bsd/md5.h:g' -e 's:HASH:MD5:g' $< > $@

$(LIB_STATIC): $(LIB_STATIC_OBJS)
	ar rcs $@ $^

$(LIB_SHARED_SO): $(LIB_SONAME)
	ln -fs $^ $@

$(LIB_SONAME): $(LIB_SHARED)
	ln -fs $^ $@

$(LIB_SHARED): $(LIB_SHARED_OBJS)
	gcc -shared \
	  -Wl,-soname -Wl,$(LIB_SONAME) \
	  -Wl,--version-script=Versions \
	  -o $@ $^

.PHONY: ChangeLog

ChangeLog:
	-git log --stat -C >$@

dist: ChangeLog
	mkdir $(TAR_NAME)
	cp -a include src man $(LIB_DIST) $(TAR_NAME)
	tar czf $(TAR_FILE) $(TAR_NAME)
	rm -rf $(TAR_NAME)
	gpg -a -b $(TAR_FILE)

install: libs man
	mkdir -p $(DESTDIR)/$(libdir)
	mkdir -p $(DESTDIR)/$(usrlibdir)
	mkdir -p $(DESTDIR)/$(includedir)/bsd/
	mkdir -p $(DESTDIR)/$(mandir)/man3
	mkdir -p $(DESTDIR)/$(pkgconfigdir)
	install -m644 $(LIB_STATIC) $(DESTDIR)/$(usrlibdir)
	install -m644 $(LIB_SHARED) $(DESTDIR)/$(libdir)
	for i in $(LIB_INCLUDES); do \
	  install -m644 include/$$i $(DESTDIR)/$(includedir)/$$i; \
	done
	install -m644 $(LIB_MANS) $(DESTDIR)/$(mandir)/man3
	install -m644 $(LIB_PKGCONFIG) $(DESTDIR)/$(pkgconfigdir)
	ln -sf $(libdir)/$(LIB_SHARED) $(DESTDIR)/$(usrlibdir)/$(LIB_SHARED_SO)
	ln -sf $(LIB_SHARED) $(DESTDIR)/$(libdir)/$(LIB_SONAME)

clean:
	rm -f $(LIB_GEN_SRCS)
	rm -f $(LIB_STATIC_OBJS)
	rm -f $(LIB_STATIC)
	rm -f $(LIB_SHARED_OBJS)
	rm -f $(LIB_SHARED) $(LIB_SONAME) $(LIB_SHARED_SO)

