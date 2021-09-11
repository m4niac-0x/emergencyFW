#!/bin/bash

# ./emergencyFW.sh {action} {format} {target}
# {action} = block / unblock
# {format} = ip / country
# {target} = 192.168.x.x / 192.168.1.0/24 / fr/us/en/ca/...



##### GLOBAL VARS #####

# WORKPATH="/tmp/emergencyFW/"
ACTION="$1"
FORMAT="$2"
TARGET="$3"



##### FUNCTIONS #####

function check_workpath()
{
    WORKPATH="/tmp/emergencyFW/"
    
    if [[ ! -e "$WORKPATH" ]]
    then
        echo "$WORKPATH doesn't exist, creating..."
        mkdir "$WORKPATH"

    else
        if [[ ! -d "$WORKPATH" ]]
        then
            echo "Warning: $WORKPATH is a file, exiting..."
            exit 1

        else
            echo "$WORKPATH directory already exist, processing..."
        fi

    fi     
}


function get_country()
{
    WORKPATH="$1"
    COUNTRY="$2"
    BASE_URL="http://www.ipdeny.com/ipblocks/data/aggregated/"
    
    wget -q $BASE_URL/$COUNTRY-aggregated.zone -O $WORKPATH/$COUNTRY.zone
}


function blockip()
{
    IP="$1"
    iptables -I INPUT -s "$IP" -j DROP -v
}


function unblockip()
{
    IP="$1"
    iptables -D INPUT -s "$IP" -j DROP -v
}


function core()
{
    ACTION="$1"
    FORMAT="$2"
    TARGET="$3"
    WORKPATH="$4"
    
    check_workpath # $WORKPATH

    if [[ "$FORMAT" = "country" ]]
    then
        get_country "$WORKPATH" "$TARGET"
        HOWMANYLINES=$(cat "$WORKPATH/$TARGET.zone" | wc -l)

        if [[ "$ACTION" = "block" ]]
        then 
            # $SECONDS=0
            echo "Processing blacklist $HOWMANYLINES for $TARGET country... please wait..."
            for LINE in $(cat "$WORKPATH/$TARGET.zone")
            do
                blockip $LINE > /dev/null
            done 
            echo "Done ! Country $TARGET ($HOWMANYLINES) BLOCKED" # in $SECONDS seconds"
        
        elif [[ "$ACTION" = "unblock" ]]
        then 
            # $SECONDS=0
            echo "Processing unblacklist $HOWMANYLINES for $TARGET country... please wait..."
            for LINE in $(cat "$WORKPATH/$TARGET.zone")
            do
                unblockip $LINE > /dev/null
            done 
            echo "Done ! Country $TARGET ($HOWMANYLINES) UNBLOCKED" # in $SECONDS seconds"

        else
            echo "$ACTION invalid, exiting..."
            exit 1
        fi
    
    elif
        [[ "$FORMAT" = "ip" ]]
    then
        if [[ "$TARGET" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])?$ ]]
        then 
            echo "$IP address detected, $TARGET is valid"
            if [[ "$TARGET" != "0.0.0.0" ]]
            then
                if [[ "$ACTION" = "block" ]]
                then
                    echo "Processing blacklist $TARGET... please wait..."
                    blockip "$TARGET"
                    echo "Done! $TARGET blocked"
                
                elif [[ "$ACTION" = "unblock" ]]
                then
                    echo "Processing unblacklist $TARGET... please wait..."
                    unblockip "$TARGET"
                    echo "Done! $TARGET unblocked"
                
                else
                    echo "$ACTION invalid, process cancelled..."
                    exit 1
                fi 

            else
                echo "ERROR : You can't blacklist all the internet !"
                exit 1
            fi 
            
        elif [[ "$TARGET" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))?$ ]]
        then    
            echo "CIDR range detected, $TARGET is valid"
            if [[ "$TARGET" != "0.0.0.0" ]]
            then
                if [[ "$ACTION" = "block" ]]
                then
                    echo "Processing blacklist $TARGET... please wait..."
                    blockip "$TARGET"
                    echo "Done! $TARGET blocked"        
                
                elif [[ "$ACTION" = "unblock" ]]
                then
                    echo "Processing unblacklist $TARGET... please wait..."
                    unblockip "$TARGET"
                    echo "Done! $TARGET unblocked"
                
                else
                    echo "$ACTION invalid, process cancelled..."
                    exit 1
                fi
            
            else
                echo "ERROR : You can't blacklist all the internet !"
            fi

        else
            echo "ERROR : $TARGET is an invalid IP address or CIDR format..."
            exit 1
        fi

    else
        echo "Format : $FORMAT invalid, exiting..."
        exit 1
    fi
}


function action()
{
    ACTION="$1"
    FORMAT="$2"
    TARGET="$3"
    #WORKPATH="$4"

    if [[ $1 = "help" ]]
        then 
            echo "./emergencyFW.sh {action} {format} {target}"
            echo "ex.: ./emergencyFW block country je"
            echo "{action} = block / unblock"
            echo "{format} = ip / country"
            echo "{target} = 192.168.x.x / 192.168.1.0/24 / fr/us/en/ca/..."

    elif [[ "$#" -ne 3 ]]; 
    then 
        echo "Invalid parameters, use 'help'"
        exit 1

    elif [[ "$EUID" -ne 0 ]]
    then
        echo "Please run as root"
        exit 1

    elif [[ "$ACTION" = "block" ]]
    then
        core $ACTION $FORMAT $TARGET $WORKPATH
        echo "----- OPERATION SUCCESSFUL -----"
    
    elif [[ "$ACTION" = "unblock" ]]
    then
        core $ACTION $FORMAT $TARGET $WORKPATH
        echo "----- OPERATION SUCCESSFUL -----"

    else
        echo "Invalid action, use 'help'"
        exit 1
    fi

}



##### EXECUTION #####

action $ACTION $FORMAT $TARGET #$WORKPATH
exit 0
