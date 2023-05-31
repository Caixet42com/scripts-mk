#!/bin/bash

# Define as datas de início e fim da última segunda-feira até domingo da semana passada
#startDate=$(date -d "last-monday" +%s)
#endDate=$(date -d "last-sunday" +%s)

# Define as datas de início e fim da segunda-feira a domingo da semana passada
startDate=$(date -d "last-monday - 7 days" +%s)
endDate=$(date -d "last-sunday" +%s)

# Imprime as datas de início e fim
echo "Data de início: $(date -d @$startDate +'%d/%m/%Y')"
echo "Data de término: $(date -d @$endDate +'%d/%m/%Y')"


# Converte as datas de início e fim para um formato legível
startDateFormatted=$(date -d @$startDate +'%d-%m-%Y')
endDateFormatted=$(date -d @$endDate +'%d-%m-%Y')

# Arquivo temporário para armazenar arquivos a serem arquivados
tempFileList="/tmp/temp_files_to_archive.txt"

# Arquivo de arquivo temporário
tempArchive="/tmp/temp_archive.tar.gz"

# Encontra e processa arquivos
find /db/backup/checklist/auditoria -type f -name "*.log" | while read file
do
    fileDate=$(date -r "$file" +%s)
    if [ $fileDate -ge $startDate ] && [ $fileDate -le $endDate ]
    then
        if grep -qE "172\.27\.225\.19|172\.27\.225\.20|172\.27\.232\.170" "$file"
        then
            echo $file >> "$tempFileList"
            cat $tempFileList
        fi
    fi
done

# Cria o arquivo e o copia
if [ -f "$tempFileList" ]
then
    tar -czf "$tempArchive" -T "$tempFileList"
    scp "$tempArchive" auditoria@10.17.191.1:/gluster/volume1/home/auditoria/audit-clientes/inpasa/$endDate_Inpasa_audit.tar.gz
    # Limpa os arquivos temporários
    rm "$tempFileList"
    rm "$tempArchive"
fi
