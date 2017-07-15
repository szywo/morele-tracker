# morele-tracker
A shell script to track prices and availability of morele.net products, intended to use with `cron`.

It works for now, but there is not any guarantee it will in the future, as it does not parse DOM tree. It only finds and parse some easily distinguishable lines of morele.net's product page code.

The script was tested with dash (the Debian Almquist Shell) so it should work with any POSIX shell.

#### !!! IMPORTANT !!!
The products' urls are currently included in script code, there is no way to pass them from comand line (will consider it), file (1st TODO) or to find them by product id (morele.net website limitation)

To include interesting product, you have to find its page on morele.net
and copy product url to section:

`!!! PUT HERE MORELE.NET PRODUCTS URLS !!!`

using format:

`parse_morele_page <morele_product_url>`

## Basic functionality implemented so far:
`morele-tracker.sh`

`morele-tracker.sh print`
  - prints current prices and quantities

`morele-tracker.sh log`
  - logs current prices and quantities to a file

`morele-tracker.sh replay [filter]`
  - prints archived prices and quantities, if optional filter string is given, script will print only lines containing this string (eg. to filter interesting product)

calling script with anything else as first argument will print basic help

## TODO list:
  - [ ] 1. Read urls from separate file.
  - [ ] 2. Refactor parse_morele_page() to return string and move printing/logging swith outside of the function.
  - [ ] 3. Move timestamp generation to separate function.
  - [ ] 4. Not enough already? Ok, I have a whole lot more ideas but don't have time to name them now, could say I have TODO to do.
  - ...
  - [ ] 777. Rewrite it in php, java or c/c++ to give it even more functionality or make morele.net hire me to write nice WEB API for them (;
