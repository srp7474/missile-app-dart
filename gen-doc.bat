%echo off
echo uses dartdoc to generate the documentation package
set flutter_root=D:\pgms\flutter-1-20\flutter
call %flutter_root%\bin\cache\dart-sdk\bin\dartdoc --no-link-to-remote


xcopy doc\api H:\data\gael-home\war\docs\missile\api /SY
