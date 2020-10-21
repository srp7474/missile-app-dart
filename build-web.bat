%echo off
echo build web app V2
call flutter build web -t lib\missile-main.dart

xcopy build\web H:\data\gael-home\war\web\missile\web /SY
