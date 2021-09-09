#!/bin/bash
# Leonardo Araujo, 2020-10-01, leonardo.araujo@atos.net

# GLOBAL VARS
DAY=$(date +%Y-%m-%d)
MAINPATH="/etc/holocron"
LOGPATH="/var/log/holocron"
CONFIG="${MAINPATH}/holocron.yaml"
LOG="${LOGPATH}/holocron.log"

# ANSI escape codes for 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\e[0m'

Arguments () {
    case $arguments in
        -h | --help) Help ;;
        -i | --install) Install ;;
        -b | --backup) Backup ;;
        -c | --config) Config;;
                    *) Help ;;
    esac

}

Help () {
    echo -e "\n\tHolocron is a shell script designed to backup directories off"
    echo -e "\tremote servers in a local directory, usign tar.gz compression.\n"
    echo -e "\tAuthor: Leonardo Araujo, leonardo.araujo@atos.net"
    echo -e "\n\tGeneral Commands:"
                echo -e "\t-h | --help       | Help"
                echo -e "\t-i | --install    | Install" 
                echo -e "\t-c | --config     | Check Config"
                echo -e "\t-b | --backup     | Execute Backup\n"

}

Check () {

    which yq > /dev/null 2>&1
    if [ "$?" != "0" ];
        then 
            echo -e "\n\t${RED} yq v3.4.0 NOT FOUND! ${NC}"
            echo -e "\tSource: https://mikefarah.gitbook.io/yq/\n"
	    echo -e"\tInstall: wget https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq\n"
            exit 1
    fi

}

Install () {

    start=$(date +%s)

    Check
    if [ "$?" -eq "1" ];
        then 
            exit 1
    fi

    if [ -d "$MAINPATH" ] && [ -d "$LOGPATH" ];
        then
            echo -e "\n\t${GREEN}Config path and logging path already created! \n\t\t- /etc/holocron,\n\t\t- /var/log/holocron ${NC}"
        else
            echo -e "\n\t${GREEN}Creating config path and logging path...\n\t\t- /etc/holocron,\n\t\t- /var/log/holocron ${NC}"
            mkdir -p $MAINPATH > /dev/null 2>&1
            mkdir -p $LOGPATH  > /dev/null 2>&1
            cp ./templates/holocron.yaml $MAINPATH
            sleep 5
            echo -e "\t${GREEN}Done!"
            
    fi

    end=$(date +%s)
    seconds=$(echo "$end - $start" | bc)
    echo -e "\n ${GREEN} $(awk -v t=$SECONDS 'BEGIN{t=int(t*1000); printf "Elapsed Time:\t%d:%02d:%02d", t/3600000, t/60000%60, t/1000%60}') ${NC} \n"

}

Config () {

    Check
    if [ "$?" -eq "1" ];
        then
            exit 1
    fi

    echo -e "\n$(yq r -C ${CONFIG})\n"

}

Backup () {

    Check    
    start=$(date +%s)

    echo "Starting backup:$(yq r ${CONFIG} 'sources' | tr -d '-') - $(date)" >> ${LOG}

    TYPES=$(yq r ${CONFIG} --printMode p "servers.type*.*" | awk -F '.' '{print $NF}' | uniq)
    BACKUPDIR=$(yq r ${CONFIG} destiny)    

    for type in ${TYPES};
        do
            if [ ! -d "${BACKUPDIR}/${type}" ];
                then
                    mkdir -p ${BACKUPDIR}/${type} > /dev/null 2>&1
            fi
        done

    echo "Backup in: ${BACKUPDIR}" >> ${LOG}

    for type in ${TYPES};
        do
          for server in $(yq r ${CONFIG} --printMode p "servers.type.${type}.*.*" | awk -F '.' '{print $NF}'| uniq | xargs);
            do
	  	for source in $(yq r ${CONFIG} --printMode pv "servers.type.${type}.*.${server}" | awk -F ':' '{print $NF}' | sed 's/-/ /g' | uniq | xargs);
		do

               		ssh ${server} sudo tar czfP - /${source} > ${BACKUPDIR}/${type}/${source}_${server}.tar.gz

               		if [ "$?" -eq "0" ];
                  	then 
                     		echo -e "${GREEN}${server} - Backup completed!${NC}" >> ${LOG}
                      		local -g STATUS="COMPLETED"
               		else
                      		echo -e "${RED}${server} - Backup error!${NC}" >> ${LOG}
                      		local -g STATUS="FAILED"
               		fi
		done
            done
        done

    echo "Backup finished!" >> ${LOG}

    end=$(date +%s)
    seconds=$(echo "$end - $start" | bc)
    echo -e "${GREEN}$(awk -v t=$SECONDS 'BEGIN{t=int(t*1000); printf "Elapsed Time:\t%d:%02d:%02d", t/3600000, t/60000%60, t/1000%60}') ${NC}" >> ${LOG}

    mail=$(yq r ${CONFIG} mail)
    
    if $mail;
    then
        Mail
    else
        echo -e "Mail function is ${RED}false. ${NC}Check ${CONFIG}!\n" >> ${LOG} 
    fi

}

Mail () {

   to=$(yq r ${CONFIG} to)
   source=$(yq r ${CONFIG} source)

   echo -e "Weekly Backup of Santos Dumont Cluster:
        \nBackup status: ${STATUS}
        \nHolocron YAML configuration:\n
$(yq r ${CONFIG} --prettyPrint -j)
        \nFor more details, check under ${LOG}. ;)
        \n\tLeonardo Araujo, leonardo.araujo@atos.net" | mailx -r ${source} -s "Holocron Backup - ${DAY} - ${STATUS} " ${to} 
}

arguments=$1
Arguments
