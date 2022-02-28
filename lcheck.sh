#!/bin/bash
FILE="$2"

read -r -d '' OPTIONS << EOM
OPTIONS\n
-h                         list avaliable command-line options\n
-a <path>                  check unresolved attributes\n
-l <path>                  check broken links
EOM

if  [[ $1 = "-l" ]]; then

    path_to_script="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

    if [[ -z $FILE ]]; then

        echo -e "ERROR: No path provided.\n"
        echo -e $OPTIONS

    elif [[ -d $FILE ]]; then

        echo "Collecting master.adoc files."
        master_adocs=$(find $FILE -type f -name master\*adoc)

        echo "Building master.adoc files."
        for i in $master_adocs; do asciidoctor --safe -v -n $i >/dev/null 2>&1; done

        echo "Checking links."
        find $FILE -type f -name master\*html | xargs linkchecker -r1 -f $path_to_script/lcheck.ini --check-extern 2>/dev/null | grep -Ev "^Check time|^Size.*"

    elif [[ -f $FILE ]]; then
        filename=$(basename "$FILE")
        if [[ $filename == "master.adoc" ]]; then

            asciidoctor --safe -v -n $FILE >/dev/null 2>&1
            cut_adoc_extension=$(echo $FILE | cut -f 1 -d '.')
            html_file="$cut_adoc_extension.html"
            linkchecker -r1 -f $path_to_script/lcheck.ini --check-extern $html_file 2>/dev/null | grep -Ev "^Check time|^Size.*"

        else

            echo "ERROR: Not a master.adoc file."

        fi
    else

        echo "ERROR: Provided path does not exist: $FILE"

    fi

elif [[ $1 = "-a" ]]; then

    if [[ -z $FILE ]]; then

        echo -e "ERROR: No path provided.\n"
        echo -e $OPTIONS

    elif [[ -d $FILE ]]; then

        master_adocs=$(find $FILE -type f -name master\*adoc)
        for i in $master_adocs; do
            asciidoctor -a attribute-missing=warn --failure-level=WARN $i 2> >(grep -E "missing attribute" && echo -e 'FILE:' $i"\n")
        done

    elif [[ -f $FILE ]]; then
        filename=$(basename "$FILE")
        if [[ $filename == "master.adoc" ]]; then
            asciidoctor -a attribute-missing=warn --failure-level=WARN $FILE 2> >(grep -E "missing attribute" && echo -e 'FILE:' $FILE"\n")
        else

            echo "ERROR: Not a master.adoc file."

        fi
    else

        echo "ERROR: Provided path does not exist: $FILE"

    fi


elif [[ $1 = "-h" ]]; then

    echo -e $OPTIONS

else

    echo -e $OPTIONS

fi
