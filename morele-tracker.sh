#! /bin/sh

################################################################################
#                                                                              #
#  morele-tracker.sh by Szymon Wojdan (https://github.com/szywo)               #
#                                                                              #
#  shell script to track prices and availability of morele.net products        #
#                                                                              #
#  It works for now, but there is not any guarantee it will in future,         #
#  as it does not parse DOM tree. It only finds and parse some easily          #
#  distinguishable lines of morele.net's product page code                     #
#                                                                              #
################################################################################
#                                                                              #
#  !!! IMPORTANT !!!                                                           #
#  Product urls are currently included in script code, there is no way to      #
#  pass them from comand line (will consider it), file (1st TODO) or to        #
#  find them by product id (morele.net website limitation)                     #
#                                                                              #
#  To include interesting product, you have to find its page on morele.net     #
#  and copy product url to section:                                            #
#                                                                              #
#      !!! PUT HERE MORELE.NET PRODUCTS URLS !!!                               #
#                                                                              #
################################################################################
#                                                                              #
#  Basic functionality implemented so far:                                     #
#                                                                              #
#  morele-tracker.sh                                                           #
#  morele-tracker.sh print                                                     #
#     - prints current prices and quantities                                   #
#                                                                              #
#  morele-tracker.sh log                                                       #
#     - logs current prices and quantities to a file                           #
#                                                                              #
#  morele-tracker.sh replay [filter]                                           #
#     - prints archived prices and quantities, if optional filter string       #
#       is given, script will print only lines containing this string          #
#       (eg. to filter interesting product)                                    #
#                                                                              #
#  calling script with anything else as first argument will print basic help   #
#                                                                              #
################################################################################


################################################################################
#                                                                              #
#  log and cache file names                                                    #
#                                                                              #
################################################################################
cachefile=".curl-cache"
logfile="price-tracker-log"
logdir="log"

################################################################################
#                                                                              #
#  setup paths for cache and log files to point to script's dir                #
#                                                                              #
################################################################################
path=`echo $0 | sed 's/\/[^\/]*$//'`
cachepath="$path/$cachefile"
logpath="$path/$logdir/$logfile"

command=${1}
option=${2}

################################################################################
#                                                                              #
#  function to retrive essential data from given morele product url            #
#                                                                              #
################################################################################
parse_morele_page () {
    curl -s $1 > $cachepath
    date=`date +"%Y-%m-%d %H:%M%z"`
    price=`cat $cachepath | grep 'id="product_price_brutto"' | sed 's/^.*content="\([0-9.]*\)".*/\1/'`
    name=`cat $cachepath | grep -m 1 '<title>' | sed 's/^<title>\(.*\)\sw\sMorele\.net<\/title>/\1/'`
    avail=`cat $cachepath | grep 'Dostępność: <b>' | sed 's/^Dostępność: <b>\(.*\)\sszt\.\s\?\([^<]*\)<\/b>/\1/'`
    if [ -z "$avail" ]; then
        avail=0
    fi
    case $command in
        "" | "print")
            echo [ $date ][ $price ][ $avail ][ $name ]
            ;;
        "log")
            echo [ $date ][ $price ][ $avail ][ $name ] >> $logpath
            echo -n "."
            ;;
    esac
    rm $cachepath
}


################################################################################
#                                                                              #
#  main script                                                                 #
#                                                                              #
################################################################################
case $command in
    "log" | "print" | "")
        if [ "$command" = "log" ]; then
            if [ ! -d "$path/$logdir" ]; then
                mkdir "$path/$logdir"
            fi
            echo -n "Processing"
        fi
        ################################################################################
        #                                                                              #
        #      !!! PUT HERE MORELE.NET PRODUCTS URLS !!!                               #
        #                                                                              #
        ################################################################################
        #                                                                              #
        #  use format: parse_morele_page <morele_product_url>                           #
        #                                                                              #
        ################################################################################
        # some sample urls (my recent wish fors)
        parse_morele_page "https://www.morele.net/procesor-serwerowy-intel-xeon-e3-1231v3-3-4-ghz-lga1150-box-bx80646e31231v3-640233/"
        parse_morele_page "https://www.morele.net/procesor-serwerowy-intel-xeon-e3-1241v3-3-5-ghz-lga1150-box-bx80646e31241v3-640234/"
        parse_morele_page "https://www.morele.net/procesor-serwerowy-intel-xeon-e3-1270-v3-8m-cache-3-50-ghz-box-bx80646e31270v3-619018/"
        parse_morele_page "https://www.morele.net/procesor-serwerowy-intel-xeon-e3-1271-v3-8m-cache-3-60-ghz-bx80646e31271v3-641043/"
        parse_morele_page "https://www.morele.net/karta-graficzna-evga-geforce-gtx-1060-gaming-acx-2-0-3gb-gddr5-192-bit-hdmi-dvi-3xdp-box-03g-p4-6160-kr-1004503/"
        parse_morele_page "https://www.morele.net/karta-graficzna-evga-geforce-gtx-1060-gaming-6gb-gddr5-192-bit-hdmi-dvi-3x-dp-box-06g-p4-6161-kr-1009506/"
        parse_morele_page "https://www.morele.net/karta-graficzna-evga-geforce-gtx-1060-sc-gaming-6gb-gddr5-192-bit-dvi-d-3xdp-hdmi-box-06g-p4-6163-kr-1049651/"
        parse_morele_page "https://www.morele.net/karta-graficzna-evga-geforce-gtx-1060-ftw-gaming-6gb-gddr5-192-bit-hdmi-dvi-d-3xdp-box-06g-p4-6268-kr-1114675/"
        parse_morele_page "https://www.morele.net/drukarka-laserowa-hewlett-packard-laserjet-pro-400-m402dne-c5j91a-b19-1053579/"
        parse_morele_page "https://www.morele.net/drukarka-laserowa-hewlett-packard-laserjet-pro-400-m402dn-c5f94a-775009/"
        parse_morele_page "https://www.morele.net/drukarka-laserowa-hewlett-packard-hp-laserjet-pro-m402dw-c5f95a-936791/"
        if [ "$command" = "log" ]; then
            echo "done"
        fi
        ;;
    "replay")
        if [ -e $logpath ]; then
            if [ -n "$option" ]; then
                cat $logpath | grep $option
            else
                cat $logpath
            fi
        else
            echo "Error, no log file found: $logpath"
        fi
        ;;
    *)
        echo "Usage: morele-tracker.sh print|log|replay [option]"
        exit 0
        ;;
esac
