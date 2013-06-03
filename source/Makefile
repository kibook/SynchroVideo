all:
	make build
	make clean

build:
	fpc index.pas -oindex.cgi -Mobjfpc -Sh -Fumodules/* -Fuunits/
	fpc bin/tvserver.pas -obin/tvserver -Mobjfpc -Sh

clean:
	rm *.o *.or */*.o */*.ppu */*/*.o */*/*.ppu
