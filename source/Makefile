FPC='/usr/local/lib/fpc/2.7.1/ppcx64'
all:
	make build
	make clean

build:
	$(FPC) index.pas -oindex.cgi -Mobjfpc -Sh -Fumodules/* -Fuunits/
	$(FPC) bin/tvserver.pas -obin/tvserver -Mobjfpc -Sh

clean:
	rm *.o *.or */*.o */*.ppu */*/*.o */*/*.ppu
