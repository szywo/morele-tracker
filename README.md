# morele-tracker
A shell script to track prices and availability of morele.net products, at the beginning intended to use with `cron`.

It works for now, but there is not any guarantee it will in the future, as it does not parse DOM tree. It only finds and parse some easily distinguishable lines of morele.net's product page code.

The script was tested with dash (the Debian Almquist Shell) so it should work with any POSIX shell.

## Basic functionality implemented so far:
`morele-tracker.sh [-v]`

`morele-tracker.sh [-v] print`
  - prints current prices and quantities

`morele-tracker.sh [-v] log`
  - logs current prices and quantities to a file

`morele-tracker.sh [-v] replay [filter]`
  - prints archived prices and quantities, if optional filter string is given, script will print only lines containing this string (eg. to filter interesting product)

Calling the script with anything else as first argument or with wrong (non-existent) switch will print basic help.

### Important files
`./morele-urls.list`
- contains interesting product's urls; remember to leave the newline on a last line of the file

`./morele-tracker.conf`
- makes it possible to change defautl input and output files names (and paths) but only relative to the script's path

`./log/morele-tracker.log`
- stores data generated when using script's `log` command and is read by `replay` command

`./.curl-cache.temp`
- is temporary file that stores fetched pages until they are parsed. It is automaticaly deleted after the script's end.

## TODO list:
  - [x] 1. Read urls from separate file.
  - [x] 2. Refactor ~~parse_morele_page()~~ parse_page() to return string and move recognition of printing/logging option outside of the function.
  - [x] 3. Move timestamp generation to separate function.
  - [ ] 4. Add more switches to point to input/output and config files.
  - [ ] 5. Enable use of absolute IO/conf file paths.
  - [ ] 6. Not enough already? Ok, I have a whole lot more ideas but don't have time to name them now, could say I have TODO to do.
  - ...
  - [ ] 777. Rewrite it in php, java or c/c++ to give it even more functionality or make morele.net hire me to write nice WEB API for them (;
