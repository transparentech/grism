cd bin
REM Move to grism.rbw. The suffix .rbw means that there will not be a 
REM DOS window started in addition to the Grism window.
rename grism grism.rbw
cd ..

REM .rb files are executable if you have Ruby installed on your machine
setup.rb
if not %errorlevel%==0 goto end

:end
pause
