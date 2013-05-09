#!/bin/bash

ROOMS=()
#COMPILER="/usr/local/lib/fpc/2.6.0/ppcx64"
COMPILER="/usr/local/lib/fpc/2.7.1/ppcx64"
FPCARGS=""
#UNITPATH="/usr/local/lib/fpc/2.6.0/units/x86_64-darwin"
UNITPATH="/usr/local/lib/fpc/2.7.1/units/x86_64-darwin"

for line in $(cat rooms.list)
do
	ROOMS[${#ROOMS[*]}]=$line
done

# Setup
echo "Preparing directories..."
echo
rm -r source 2> /dev/null
mkdir source
mkdir source/room
mkdir source/room/playlists
sudo chmod 777 source/
sudo chmod 777 source/room/
sudo chmod 777 source/room/playlists
echo
echo "Done!"
echo

# Main page
echo "Compiling main page..."
echo
	$COMPILER $FPCARGS index.pas -oindex.cgi
echo
echo "Done!"
echo

# New room page
echo "Compiling new room page..."
echo
	$COMPILER $FPCARGS new.pas -onew.cgi
echo
echo "Done!"
echo

# Room creation
echo "Compiling room creation script..."
echo
	$COMPILER $FPCARGS createroom.pas -ocreateroom.cgi
echo
echo "Done!"
echo

# Room delete
echo "Compiling room deletion scripts..."
echo
	$COMPILER $FPCARGS deleteroom.pas -odeleteroom.cgi
	$COMPILER $FPCARGS eraseroom.pas -oeraseroom
echo
echo "Done!"
echo

# Room list
echo "Compiling room list script..."
echo
	$COMPILER $FPCARGS list.pas -olist/index.cgi
echo
echo "Done!"
echo

# Room search
echo "Compiling room search script..."
echo
	$COMPILER $FPCARGS search.pas -osearch/index.cgi
echo
echo "Done!"
echo

# Room pages
echo "Compiling room pages..."
echo
	$COMPILER $FPCARGS room.pas -oroom.out

	for ROOM in ${ROOMS[*]}
	do
		cp room.out $ROOM/index.cgi
	done
echo
echo "Done!"
echo

# Room servers
echo "Compiling room server scripts..."
echo
	$COMPILER $FPCARGS server.pas -oserver.out

	for ROOM in ${ROOMS[*]}
	do
		cp server.out $ROOM/server.cgi
	done
echo
echo "Done!"
echo

# Room TV server
echo "Compiling room TV server..."
echo
	$COMPILER $FPCARGS tvserver.pas -otvserver.out

	for ROOM in ${ROOMS[*]}
	do
		cp tvserver.out $ROOM/tvserver
	done
echo
echo "Done!"
echo

# Room TV mode script
echo "Compiling room TV mode scripts..."
echo
	$COMPILER $FPCARGS tvmode.pas -otvmode.out

	for ROOM in ${ROOMS[*]}
	do
		cp tvmode.out $ROOM/tvmode.cgi
	done
echo
echo "Done!"
echo

# Room settings page
echo "Compiling room settings scripts..."
echo
	$COMPILER $FPCARGS settings.pas -osettings.out

	for ROOM in ${ROOMS[*]}
	do
		cp settings.out $ROOM/settings.cgi
	done
echo
echo "Done!"
echo

# Room configuration scripts
echo "Compiling room configuration scripts..."
echo
	$COMPILER $FPCARGS configure.pas -oconfigure.out

	for ROOM in ${ROOMS[*]}
	do
		cp configure.out $ROOM/configure.cgi
	done
echo
echo "Done!"
echo

# Room auths
echo "Compiling room auth scripts..."
echo
	$COMPILER $FPCARGS auth.pas -oauth.out

	for ROOM in ${ROOMS[*]}
	do
		cp auth.out $ROOM/auth.cgi
	done
echo
echo "Done!"
echo

# Private room auth
echo "Compiling private room auth scripts..."
echo
	$COMPILER $FPCARGS private.pas -oprivate.out

	for ROOM in ${ROOMS[*]}
	do
		cp private.out $ROOM/private.cgi
	done
echo
echo "Done!"
echo

# Room settings auth
echo "Compiling room settings auth scripts..."
echo
	$COMPILER $FPCARGS settings-auth.pas -osettings-auth.out

	for ROOM in ${ROOMS[*]}
	do
		cp settings-auth.out $ROOM/settings-auth.cgi
	done
echo
echo "Done!"
echo


# Room playlist
echo "Compiling room playlist script..."
echo
	$COMPILER $FPCARGS playlist.pas -oplaylist.out

	for ROOM in ${ROOMS[*]}
	do
		cp playlist.out $ROOM/playlist.cgi
	done
echo
echo "Done!"
echo

# Optimization
echo "Stripping binaries..."
echo
	strip index.cgi

	for ROOM in ${ROOMS[*]}
	do
		strip $ROOM/*.cgi
		strip $ROOM/tvserver
	done
echo
echo "Done!"
echo

# Source code
echo "Copying source code..."
echo
	cp INFO-README.html	source/
	cp index.pas		source/
	cp new.pas		source/
	cp createroom.pas	source/
	cp createroom.sh	source/
	cp search.pas		source/
	cp list.pas		source/
	cp deleteroom.pas	source/
	cp eraseroom.pas	source/
	cp rooms.ini		source/
	cp room.js		source/	
	cp sync-host.js		source/
	cp sync-client.js	source/
	cp room.css		source/
	cp index.css		source/
	cp general.css		source/
	cp init.js		source/
	cp compile.sh		source/

	cp room.pas		source/room/
	cp auth.pas		source/room/
	cp playlist.pas		source/room/
	cp server.pas		source/room/
	cp settings.pas		source/room/
	cp configure.pas	source/room/
	cp settings-auth.pas	source/room/
	cp tvserver.pas		source/room/
	cp tvmode.pas		source/room/
	cp settings.ini		source/room/
	cp playlist.ini		source/room/

	cp savedplaylist.ini	source/room/playlists/

	cp $UNITPATH/strarrutils/strarrutils.pas	source/
	cp $UNITPATH/htmlutils/htmlutils.pas		source/
	cp -r $UNITPATH/synapse				source/synapse

	zip -r source/source.zip source/*
echo
echo "Done!"
echo

echo "Cleaning up..."
echo
	rm *.o */*.o *.ppu */*.ppu *.out 2> /dev/null
echo
echo "Done!"
echo
