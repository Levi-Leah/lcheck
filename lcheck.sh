#!/bin/bash

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
elif ! ( [ $1 = "-h" ] || [ $1 = "-c" ] ); then
    if [[ -z $2 ]]; then
        echo -e 'No path provided.\n'
        echo -e $OPTIONS
        exit 1
    elif ! ( [ -d $2 ] || [ -f $2 ] ); then
        echo -e "Provided path does not exist: $2"
        exit 1
    fi
elif [[ $1 = "-c" ]]; then
    if [[ -z $2 ]]; then
        echo -e 'No variant provided.\n'
        echo -e $OPTIONS
        exit 1
    elif [[ ! $2 =~ [0-9] ]]; then
        echo -e "Provided variant is not a valid version number: $2"
        exit 1
    elif [[ -z $3 ]]; then
        echo -e 'No path provided.\n'
        echo -e $OPTIONS
        exit 1
    elif ! ( [ -d $3 ] || [ -f $3 ] ); then
        echo -e "Provided path does not exist: $3"
        exit 1
    fi
fi

if  [[ $1 = "-l" ]]; then

    path_to_script="$(realpath $(dirname "$0"))"

    if [[ -d $2 ]]; then

        echo "Collecting master.adoc files."
        master_adocs=$(find $2 -type f -name master\*adoc)

        echo "Building master.adoc files."
        for i in $master_adocs; do asciidoctor --safe -v -n $i >/dev/null 2>&1; done

        echo "Checking links."
        find $2 -type f -name master\*html | xargs linkchecker -r1 -f $path_to_script/lcheck.ini --check-extern 2>/dev/null | grep -Ev "^Check time|^Size.*"

    elif [[ -f $2 ]]; then
        if [[ $2 == *master.adoc ]]; then

            asciidoctor --safe -v -n $2 >/dev/null 2>&1
            cut_adoc_extension=$(echo $2 | cut -f 1 -d '.')
            html_file="$cut_adoc_extension.html"
            linkchecker -r1 -f $path_to_script/lcheck.ini --check-extern $html_file 2>/dev/null | grep -Ev "^Check time|^Size.*"

        else

            echo "Not a master.adoc file: $2"
            exit 1

        fi
    fi

elif [[ $1 = "-a" ]]; then

    if [[ -d $2 ]]; then

        master_adocs=$(find $2 -type f -name master\*adoc)
        for i in $master_adocs; do
            asciidoctor -a attribute-missing=warn --failure-level=WARN $i 2> >(grep -E "missing attribute" && echo -e '2:' $i"\n")
        done

    elif [[ -f $2 ]]; then
        if [[ $2 == *master.adoc ]]; then
            asciidoctor -a attribute-missing=warn --failure-level=WARN $2 2> >(grep -E "missing attribute" && echo -e '2:' $2"\n")
        else

            echo "Not a master.adoc file: $2"
            exit 1

        fi
    fi


elif [[ $1 = "-h" ]]; then

    echo -e $OPTIONS

elif [[ $1 = '-r' ]]; then

    if [[ -d $2 ]]; then

        echo -e "Removing master.html files from $2 directory recursively.\n"
        master_htmls=$(find $2 -type f -name master\*html)
        rm -v $master_htmls
    elif [[ -f $2 ]]; then
        if [[ $2 == *.html ]]; then
            rm -v $2
        else
            echo "Not an html file: $2"
            exit 1
        fi
    fi

elif [[ $1 = '-c' ]]; then

    if [[ -d $3 ]]; then
        start=`date +%s`

        echo "Collecting master.adoc files."
        master_adocs=$(find $3 -type f -name master\*adoc)

        echo "Building master.adoc files."
        for i in $master_adocs; do asciidoctor --safe -v -n $i >/dev/null 2>&1; done

        echo "Collecting master.adoc files."
        master_htmls=$(find $3 -type f -name master\*html)

        echo -e "\nChecking if links in '$3' directory contain only 'red_hat_enterprise_linux/$2' URL pattern."

        all_rhel_urls=$(for i in $master_htmls; do grep -HnPo '(?<=<a href=")[^\s]*(?=")' $i | grep -v '^#' | grep "red_hat_enterprise_linux\/[0-9]"; done)
        total_count=$(echo $all_rhel_urls | wc -w)

        missmathed_urls=$(echo "$all_rhel_urls" | grep -v "red_hat_enterprise_linux\/$2")
        errors_count=$(echo $missmathed_urls | wc -w)

        awk -F: '{print "\nFile:\t\t"$1 "\nLine number:\t"$2 "\nMatching URL:\t"$3$4}' <<< $missmathed_urls

        end=`date +%s`
        runtime=$((end-start))

        echo -e "\nStatistics:\nThat's it. $total_count URLs checked. $errors_count errors found.\nStopped checking at $(date '+%F %T') ($runtime seconds)"

    elif [[ -f $3 ]]; then
        start=`date +%s`

        if [[ $3 == *master.adoc ]]; then
            echo "Building master.adoc files."
            asciidoctor --safe -v -n $3 >/dev/null 2>&1

            cut_adoc_extension=$(echo $3 | cut -f 1 -d '.')
            html_file="$cut_adoc_extension.html"

            echo -e "\nChecking if links in '$3' file contain only 'red_hat_enterprise_linux/$2' URL pattern."

            all_rhel_urls=$(grep -HnPo '(?<=<a href=")[^\s]*(?=")' $html_file | grep -v '^#' | grep "red_hat_enterprise_linux\/[0-9]")
            total_count=$(echo $all_rhel_urls | wc -w)

            missmathed_urls=$(echo "$all_rhel_urls" | grep -v "red_hat_enterprise_linux\/$2")
            errors_count=$(echo $missmathed_urls | wc -w)

            awk -F: '{print "\nFile:\t\t"$1 "\nLine number:\t"$2 "\nMatching URL:\t"$3$4}' <<< $missmathed_urls

            end=`date +%s`
            runtime=$((end-start))

            echo -e "\nStatistics:\nThat's it. $total_count URLs checked. $errors_count errors found.\nStopped checking at $(date '+%F %T') ($runtime seconds)"

        else

            echo "Not a master.adoc file: $3"
            exit 1

        fi

    fi

fi
