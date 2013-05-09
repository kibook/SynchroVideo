#!/bin/bash

COMPILER="/usr/local/bin/ppcx64"
ARGS=""

mkdir $1
mkdir $1/playlists
mkdir $1/res

chmod 777 $1
chmod 777 $1/playlists
chmod 777 $1/res

> $1/settings.ini
> $1/playlist.ini
> $1/syncvid.syn
> $1/session.id

chmod 666 $1/*.ini
chmod 666 $1/syncvid.syn
chmod 666 $1/session.id

$COMPILER $ARGS room.pas -o$1/index.cgi
$COMPILER $ARGS server.pas -o$1/server.cgi
$COMPILER $ARGS playlist.pas -o$1/playlist.cgi
$COMPILER $ARGS tvmode.pas -o$1/tvmode.cgi
$COMPILER $ARGS tvserver.pas -o$1/tvserver
$COMPILER $ARGS auth.pas -o$1/auth.cgi
$COMPILER $ARGS private.pas -o$1/private.cgi
$COMPILER $ARGS configure.pas -o$1/configure.cgi
$COMPILER $ARGS settings.pas -o$1/settings.cgi
$COMPILER $ARGS settings-auth.pas -o$1/settings-auth.cgi

rm $1/*.o
rm $1/*.ppu

chmod 777 $1/*.cgi
chmod 777 $1/tvserver

cp *.js $1/
chmod 666 $1/*.js

cp htaccess $1/.htaccess
chmod 666 $1/.htaccess
