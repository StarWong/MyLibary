@echo off
cls
SET Flags=-c -6 -O2 -Ve -X- -pr -a8 -b -d -k- -vi -tWM -r -RT-

del deflate.obj inflate.obj inftrees.obj infback.obj inffast.obj trees.obj compress.obj adler32.obj crc32.obj

bcc32.exe %Flags% adler32.c
bcc32.exe %Flags% deflate.c
bcc32.exe %Flags% infback.c
bcc32.exe %Flags% inffast.c
bcc32.exe %Flags% inflate.c
bcc32.exe %Flags% inftrees.c
bcc32.exe %Flags% trees.c
bcc32.exe %Flags% crc32.c
bcc32.exe %Flags% compress.c