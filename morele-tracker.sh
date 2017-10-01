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
#  Products' urls are read from a file named:                                  #
#                                                                              #
#     morele-urls.list                                                         #
#                                                                              #
#  located in the script's directory.                                          #
#                                                                              #
################################################################################
#                                                                              #
#  Basic functionality implemented so far:                                     #
#                                                                              #
#  morele-tracker.sh [-v]                                                      #
#  morele-tracker.sh [-v] print                                                #
#     - prints current prices and quantities                                   #
#                                                                              #
#  morele-tracker.sh [-v] log                                                  #
#     - logs current prices and quantities to a file                           #
#                                                                              #
#  morele-tracker.sh [-v] replay [filter]                                      #
#     - prints archived prices and quantities, if optional filter string       #
#       is given, script will print only lines containing this string          #
#       (eg. to filter interesting product)                                    #
#                                                                              #
#  Switches:                                                                   #
#    -v   Makes the script more verbose/talkative during the operation.        #
#         All verbose messages are redirected to stderr.                       #
#                                                                              #
#  Calling the script with anything else as first argument or with wrong       #
#  (non-existent) switch will print basic help.                                #
#                                                                              #
################################################################################


################################################################################
#                                                                              #
#  Default file names and paths                                                #
#                                                                              #
################################################################################

# Default debug level is 0 (no debugging) to change it use config file
# or better -v switch
DEFAULT_DEBUG_LEVEL=0

# Get absolute script path
SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

# For future use
DEFAULT_CONFIG_FILE_NAME="morele-tracker.conf"

# Input file with list of urls to check
DEFAULT_INPUT_FILE_NAME="morele-urls.list"

# Main data file name and its sub dir
DEFAULT_LOG_FILE_NAME="price-tracker.log"
DEFAULT_LOG_FILE_DIR="log"

# Temporary file where fetched pages are stored for processing
DEFAULT_CACHE_FILE_NAME=".curl-cache.temp"


################################################################################
#                                                                              #
#  Check, read and parse config file values (future use)                       #
#                                                                              #
################################################################################

# Check for config file and read it
if [ -r "$SCRIPT_PATH/${CONFIG_FILE_NAME:=$DEFAULT_CONFIG_FILE_NAME}" ]; then
  . "$SCRIPT_PATH/$CONFIG_FILE_NAME"
fi

# Parse config file values
# Debug level
DEBUG=${DEBUG_LEVEL:=$DEFAULT_DEBUG_LEVEL}

# Set absolute input file path and name
INPUT_FILE="$SCRIPT_PATH/${INPUT_FILE_NAME:=$DEFAULT_INPUT_FILE_NAME}"
# Set absolute log dir path
LOG_PATH="$SCRIPT_PATH/${LOG_DIR_NAME:=$DEFAULT_LOG_FILE_DIR}"
# Set absolute log file path and name
LOG_FILE="$LOG_PATH/${LOG_FILE_NAME:=$DEFAULT_LOG_FILE_NAME}"
# Set absolute cache file path and name
CACHE_FILE="$SCRIPT_PATH/${CACHE_FILE_NAME:=$DEFAULT_CACHE_FILE_NAME}"

################################################################################
#                                                                              #
#  Parse the switches                                                          #
#                                                                              #
################################################################################
while getopts v OPTION
do
  case $OPTION in
    v)
        DEBUG=1
        ;;
    \?)
        OPT_COMMAND="error"
        ;;
  esac
done

shift `expr $OPTIND - 1`

################################################################################
#                                                                              #
#  Parse the commands (options)                                                #
#                                                                              #
################################################################################
# What we have to do
[ "$OPT_COMMAND"!="error" ] && OPT_COMMAND=$1
[ -z "$OPT_COMMAND" ] && OPT_COMMAND="print"

# Option to filter replay output
OPT_FILTER=$2


################################################################################
#                                                                              #
#  Functions                                                                   #
#                                                                              #
################################################################################

# Fetch a page to parse
#
# usage:
#    fetch_page $URL_TO_FETCH $CACHE_FILE
#
fetch_page () {
    if [ -z "$1" -o -z "$2" ]; then
        return 1
    fi
    curl -sfo $2 $1
    if [ $? -ne 0 ]; then
        return 2
    fi
    return 0
}

# Parse the fetched page
#
# usage:
#    parse_page $CACHE_FILE
#
parse_page () {
    FILE=$1
    if [ ! -r "$1" ]; then
        return 1
    fi

    NAME=`cat $FILE | grep -m 1 '<title>' | sed 's/^<title>\(.*\)\sw\sMorele\.net<\/title>/\1/'`
    PRICE=`cat $FILE | grep 'id="product_price_brutto"' | sed 's/^.*content="\([0-9.]*\)".*/\1/'`
    if [ -z "$NAME" -o -z "$PRICE" ]; then
        return 2
    fi

    QTY=`cat $FILE | grep 'Dostępność: <b>' | sed 's/^Dostępność:\s<b>\(.*\)\sszt\.\s\?\([^<]*\)<\/b>/\1/'`
    if [ -z "$QTY" ]; then
        QTY=0
    fi

    printf "[ %8s ][ %4s ][ %s ]" "$PRICE" "$QTY" "$NAME"
    return 0
}

# Generate a timestamp
get_timestamp () {
    printf "[ %s ]" "$(date +"%Y-%m-%d %H:%M%z")"
    return 0
}

# Delete any remaining temporary files
cleanup () {
    if [ -e $CACHE_FILE ]; then
        rm $CACHE_FILE
    fi
}

################################################################################
#                                                                              #
#  Main script                                                                 #
#                                                                              #
################################################################################
[ $DEBUG -ge 1 ] && echo "DEBUG: Executing choosen command: $OPT_COMMAND" >&2

case $OPT_COMMAND in
    "log" | "print" | "")
        if [ ! -r "$INPUT_FILE" ]; then
            echo "ERROR: Can not read $INPUT_FILE" >&2
            exit 1
        fi

        [ $DEBUG -ge 1 ] && echo "DEBUG: Set the input file: $INPUT_FILE" >&2

        if [ "$OPT_COMMAND" = "log" -a $DEBUG -eq 0 ]; then
          printf "Processing"
        fi

        TIMESTAMP=$(get_timestamp)

        [ $DEBUG -ge 1 ] && echo "DEBUG: Get a timestamp: $TIMESTAMP" >&2

        [ $DEBUG -ge 1 ] && echo "DEBUG: Enter read loop:" >&2

        while read URL ; do

            [ $DEBUG -ge 1 ] && echo "DEBUG: Get the url: $URL ..." >&2

            fetch_page "$URL" "$CACHE_FILE"
            CMD_RESULT=$?

            [ $DEBUG -ge 1 ] && echo "DEBUG:  ... check fetching result: $CMD_RESULT" >&2

            if [ $CMD_RESULT -ne 0 ]; then
                [ $CMD_RESULT -eq 1 ] && echo "Warning: wrong page_fetch call: $URL $CACHE_FILE" >&2
                [ $CMD_RESULT -eq 2 ] && echo "Warning: \`curl\` could not fetch page $URL" >&2
                continue
            fi

            [ $DEBUG -eq 1 -a -r $CACHE_FILE ] && echo "DEBUG:  ... and store in $CACHE_FILE" >&2

            [ $DEBUG -ge 1 ] && echo "DEBUG: Parse $CACHE_FILE ..." >&2

            PARSED_RESULT=$(parse_page "$CACHE_FILE")
            CMD_RESULT=$?

            [ $DEBUG -ge 1 ] && echo "DEBUG:  ... parse_page status $CMD_RESULT returned value $PARSED_RESULT" >&2

            if [ $CMD_RESULT -ne 0 ]; then
                [ $CMD_RESULT -eq 1 ] && echo "Warning: can not read $CACHE_FILE of $URL" >&2
                [ $CMD_RESULT -eq 2 ] && echo "Warning: could not parse $CACHE_FILE of $URL" >&2
                continue
            fi

            if [ "$OPT_COMMAND" = "log" ]; then
                if [ ! -d "$LOG_PATH" ]; then
                    mkdir "$LOG_PATH"
                    if [ $? -ne 0 ]; then
                        echo "Error: could not create log dir: $LOG_PATH" >&2
                        cleanup
                        exit 2
                    fi
                fi
                printf "%s%s\n" "$TIMESTAMP" "$PARSED_RESULT" >> $LOG_FILE
                [ $DEBUG -eq 0 ] && printf "."
            else
                printf "%s%s\n" "$TIMESTAMP" "$PARSED_RESULT"
            fi


        done < $INPUT_FILE

        [ $DEBUG -ge 1 ] && echo "DEBUG: Exit read loop." >&2

        if [ "$OPT_COMMAND" = "log" -a $DEBUG -eq 0 ]; then
            printf "done\n"
        fi

        [ $DEBUG -ge 1 ] && echo -n "DEBUG: Cleanup ..." >&2

        cleanup

        [ $DEBUG -ge 1 ] && echo " done." >&2

        ;;

    "replay")
        if [ ! -r $LOG_FILE ]; then
            echo "Error, no log file found: $LOG_FILE" >&2
            exit 3
        fi

        if [ -n "$OPT_FILTER" ]; then
            cat $LOG_FILE | grep $OPT_FILTER
        else
            cat $LOG_FILE
        fi

        ;;

    "error" | *)
        echo "Usage: morele-tracker.sh [-v] print|log|replay [filter_string]" >&2
        exit 1
        ;;
esac

[ $DEBUG -ge 1 ] && echo "DEBUG: Exit." >&2
exit 0
