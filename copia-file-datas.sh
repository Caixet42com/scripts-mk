#!/bin/bash

startDate=$(date -d "2023-05-22" +%s)
endDate=$(date -d "2023-05-28" +%s)

find /db/backup/checklist/auditoria -type f -name "*.log" | while read file
do
    fileDate=$(date -r "$file" +%s)
    if [ $fileDate -ge $startDate ] && [ $fileDate -le $endDate ]
    then
        if grep -qE "172\.27\.225\.19|172\.27\.225\.20|172\.27\.232\.170" "$file"
        then
            echo $file
            scp "$file" auditoria@10.17.191.1:/gluster/volume1/home/auditoria/audit-clientes/inpasa/
        fi
    fi
done


#COPIA ARQUIVOS BASEADO EM DATA INICIAL E FINAL
#E FAZ UMA AÇÃO DEPOIS DE CRIAR ESSA LISTA

#ULTIMO CLIENTE USADO AUDITORIA INPASA