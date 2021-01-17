#!/bin/sh
PROG=$(basename $0)
VERSION="0.1"

TEST_PLAN=$HOME/simple_test.jmx
RESULTS_FILE=results.jtl
REPORT_DIR=report

usage() {
    echo "Usage: $PROG [OPTIONS] URL"
    echo
    echo "Options:"
    echo "  -h, --help  show Usage"
    echo "  -n          number of requests per second(default 10)"
    echo "  -c          number of threads(default 10)"
    echo "  "
}

parse_options() {
    for OPT in "$@"
    do
        case $OPT in
            -h | --help)
                usage
                exit 1
                ;;
            --version)
                echo "$PROG version $VERSION"
                exit 1
                ;;
            -n)
                if [ -z "$2" ] || [ `echo $2 | grep '^-'` ]; then
                    echo "$PROG: option requires an argument -- $1" 1>&2
                    exit 1
                fi
                RPS=$2
                shift 2
                ;;
            -c)
                if [ -z "$2" ] || [ `echo $2 | grep '^-'` ]; then
                    echo "$PROG: option requires an argument -- $1" 1>&2
                    exit 1
                fi
                THREADS=$2
                shift 2
                ;;
            -*)
                echo "$PROG: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
                exit 1
                ;;
            esac
    done

    URL="$1"

    if [ -z "$URL" ]; then
        echo "$PROG: too few arguments" 1>&2
        echo "Try '$PROG --help' for more information." 1>&2
        exit 1
    fi
}

parse_url() {
    # extract the protocol
    TARGET_PROTOCOL="$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
    # remove the protocol
    url="$(echo ${1/$TARGET_PROTOCOL/})"
    # extract the user (if any)
    user="$(echo $url | grep @ | cut -d@ -f1)"
    # extract the host and port
    hostport="$(echo ${url/$user@/} | cut -d/ -f1)"
    # by request TARGET_HOST without TARGET_PORT    
    TARGET_HOST="$(echo $hostport | sed -e 's,:.*,,g')"
    # by request - try to extract the TARGET_PORT
    TARGET_PORT="$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
    # extract the TARGET_PATH (if any)
    TARGET_PATH="$(echo $url | grep / | cut -d/ -f2-)"
    # remove :// from TARGET_PROTOCOLcol 
    TARGET_PROTOCOL="$(echo $TARGET_PROTOCOL | sed -e's,://,,g')"
}


parse_options "$@"
parse_url "$URL"

rm -rf ${RESULTS_FILE} ${REPORT_DIR} jmeter.log
mkdir -p ${REPORT_DIR}

jmeter -JRPS="${RPS}" -JTHREADS="${THREADS}" -JTARGET_HOST="${TARGET_HOST}" -JTARGET_PROTOCOL="${TARGET_PROTOCOL}" -JTARGET_PORT="${TARGET_PORT}" -JTARGET_PATH="${TARGET_PATH}" \
    -n -t ${TEST_PLAN} -l ${RESULTS_FILE} -e -o ${REPORT_DIR}
