#!/bin/bash
PASSED="$2"

read -r -d '' OPTIONS << EOM
OPTIONS\n
-h                         \t\t\tlist avaliable command-line options\n
-a <path>                  \t\tcheck unresolved attributes\n
-l <path>                  \t\tcheck broken links\n
-r <path>                  \t\tremove master.html files\n
-c <version> <path>        \tfind links that do not match the version
EOM

if [ -z "$*" ]; then
    echo -e "No arguments provided.\n"
    echo -e $OPTIONS
    exit 1
elif [[ ! -z $1 ]] && [[ $1 != "-h" ]] && [[ -z $2 ]]; then
    echo -e "No path provided.\n"
    echo -e $OPTIONS
    exit 1
fi

if  [[ $1 = "-l" ]]; then

    path_to_script="$(realpath $(dirname "$0"))"

    if [[ -d $PASSED ]]; then

        echo "Collecting master.adoc files."
        master_adocs=$(find $PASSED -type f -name master\*adoc)

        echo "Building master.adoc files."
        for i in $master_adocs; do asciidoctor --safe -v -n $i >/dev/null 2>&1; done

        echo "Checking links."
        find $PASSED -type f -name master\*html | xargs linkchecker -r1 -f $path_to_script/lcheck.ini --check-extern 2>/dev/null | grep -Ev "^Check time|^Size.*"

    elif [[ -f $PASSED ]]; then
        filename=$(basename "$PASSED")
        if [[ $filename == "master.adoc" ]]; then

            asciidoctor --safe -v -n $PASSED >/dev/null 2>&1
            cut_adoc_extension=$(echo $PASSED | cut -f 1 -d '.')
            html_file="$cut_adoc_extension.html"
            linkchecker -r1 -f $path_to_script/lcheck.ini --check-extern $html_file 2>/dev/null | grep -Ev "^Check time|^Size.*"

        else

            echo "ERROR: Not a master.adoc file."

        fi
    else

        echo "ERROR: Provided path is not valid: $PASSED"

    fi

elif [[ $1 = "-a" ]]; then

    if [[ -d $PASSED ]]; then

        master_adocs=$(find $PASSED -type f -name master\*adoc)
        for i in $master_adocs; do
            asciidoctor -a attribute-missing=warn --failure-level=WARN $i 2> >(grep -E "missing attribute" && echo -e 'PASSED:' $i"\n")
        done

    elif [[ -f $PASSED ]]; then
        filename=$(basename "$PASSED")
        if [[ $filename == "master.adoc" ]]; then
            asciidoctor -a attribute-missing=warn --failure-level=WARN $PASSED 2> >(grep -E "missing attribute" && echo -e 'PASSED:' $PASSED"\n")
        else

            echo "ERROR: Not a master.adoc file."

        fi
    else

        echo "ERROR: Provided path does not exist: $PASSED"

    fi


elif [[ $1 = "-h" ]]; then

    echo -e $OPTIONS

elif [[ $1 = '-r' ]]; then

    echo -e "Removing master.html files from $PASSED directory recursively.\n"
    master_htmls=$(find $PASSED -type f -name master\*html)
    rm -v $master_htmls

elif [[ $1 = '-c' ]]; then

    num='^[0-9]+$'
    if [[ $2 =~ num ]] & [[ -d $3 ]]; then


        echo "Collecting master.adoc files."
        master_adocs=$(find $3 -type f -name master\*adoc)

        echo "Building master.adoc files."
        for i in $master_adocs; do asciidoctor --safe -v -n $i >/dev/null 2>&1; done

        echo "Collecting master.adoc files."
        master_htmls=$(find $3 -type f -name master\*html)

        echo -e "\nChecking URLs."

        for i in $master_htmls; do grep -HnPo '(?<=<a href=")[^\s]*(?=")' $i | grep -v '^#' | grep "red_hat_enterprise_linux\/[0-9]" | grep -v "red_hat_enterprise_linux\/$2" | awk -F: '{print "\nFile:\t\t"$1 "\nLine number:\t"$2 "\nMatching URL:\t"$3$4}'; done

    fi

else

    echo -e $OPTIONS

fi
