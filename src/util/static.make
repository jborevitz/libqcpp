CXXFLAGS=-static -static-libstdc++ -std=c++11 -O3 -I src/ -I src/ext/
LIBS=-L/usr/local/lib -lbz2 -lz -lm -lyaml-cpp -lmpc -lmpfr -lgmp -lpthread
SRCS=$(wildcard src/*.cc src/ext/*.c src/ext/*.cpp)
TESTSRCS=$(wildcard src/tests/*.cc src/test/ext/*.c)
OBJS=$(addsuffix .o,$(basename $(SRCS)))
ARCHIVES=/usr/local/lib/libbz2.a /usr/local/lib/libz.a /usr/local/lib/libyaml-cpp.a /usr/local/lib/libmpc.a /usr/local/lib/libmpfr.a /usr/local/lib/libgmp.a /usr/lib/libm.a /usr/lib/libpthread.a
VERSION=$(shell git describe --always)

all: gbsqc test-qcpp libqcpp.a

src/qc-config.hh: src/qc-config.hh.in
	sed -e 's/\$${QCPP_VERSION}/$(VERSION)/' $< >$@

%.o: %.cc src/qc-config.hh
	g++ $(CXXFLAGS) -c -o $@ $<

libqcpp.a: $(ARCHIVES)
	ar rcs $@.tmp $(OBJS)
	echo "CREATE $@" > qcpp-script.mri
	list='$^ $@.tmp'; for p in $$list; do \
	    echo "ADDLIB $$p" >> qcpp-script.mri; \
	done
	echo "SAVE" >> qcpp-script.mri
	ar -M < qcpp-script.mri
	ranlib $@
	rm -f $@.tmp qcpp-script.mri

%: ./src/progs/%.cc $(SRCS) src/qc-config.hh
	g++ $(CXXFLAGS) -o $@ $< $(SRCS) $(LIBS)

test-qcpp: $(TESTSRCS)
	g++ $(CXXFLAGS) -I src/tests/ -I src/tests/ext/ -o $@ $(TESTSRCS) $(SRCS) $(LIBS)

libdist: libqcpp.a $(SRCS)
	rm -rf libqcpp_$(VERSION)
	mkdir libqcpp_$(VERSION)
	mkdir libqcpp_$(VERSION)/lib
	mkdir libqcpp_$(VERSION)/include
	sed -e 's/\$${QCPP_VERSION}/$(VERSION)/' src/qc-config.hh.in >src/qc-config.hh
	cp src/*.hh libqcpp_$(VERSION)/include
	cp libqcpp.a libqcpp_$(VERSION)/lib
	tar cvJf libqcpp_$(VERSION).tar.xz libqcpp_$(VERSION)

dist: libqcpp.a $(SRCS)
	rm -rf libqcpp_$(VERSION)
	mkdir libqcpp_$(VERSION)
	mkdir libqcpp_$(VERSION)/lib
	mkdir libqcpp_$(VERSION)/bin
	mkdir libqcpp_$(VERSION)/include
	cp src/*.hh libqcpp_$(VERSION)/include
	cp libqcpp.a libqcpp_$(VERSION)/lib
	cp gbsqc test-qcpp libqcpp_$(VERSION)/bin
	tar cvJf libqcpp_$(VERSION).tar.xz libqcpp_$(VERSION)

clean:
	rm -rf *.mri *.a *.o gbsqc test-qcpp libqcpp_*
