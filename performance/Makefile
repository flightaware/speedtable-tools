

TCLSH=tclsh

TARGET=/usr/local/lib/speedtable_performance

FILES=*.tcl

all:
	@echo "'make install' to install"

install:
	mkdir -p $(TARGET)
	cp $(FILES) $(TARGET)
	cd $(TARGET); $(TCLSH) performance.tcl
	cd $(TARGET); echo "pkg_mkIndex ." | $(TCLSH)
