#!/bin/bash

# Primeiro script

# O nome do cliente é passado como um argumento para o script
nome_cliente=$1

# Execute o comando vpn com o nome do cliente e salve a saída
output=$(vpn $nome_cliente)

# Crie uma array vazia para armazenar os IPs
ips=()

# Para cada linha da saída
echo "$output" | while IFS= read -r line
do
  # Use awk para pegar a segunda coluna (os IPs)
  ip=$(echo $line | awk '{print $2}')
  
  # Verifique se o valor extraído é um endereço IP válido
  if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Se for, adicione à array de IPs
    ips+=($ip)
  fi
done

# Transforme a array de IPs em uma string para ser usada no grep
# Cada IP será separado por um "|", que no grep significa "ou"
ip_grep_string=$(printf "|%s" "${ips[@]}")
# Remova o primeiro "|"
ip_grep_string=${ip_grep_string:1}

# Segundo script

# Calcule o timestamp da última segunda-feira e do último domingo
startDate=$(date -d "last-monday - 7 days" +%s)
endDate=$(date -d "last-sunday" +%s)

# Imprima as datas de início e término
echo "Data de início: $(date -d @$startDate +'%d/%m/%Y')"
echo "Data de término: $(date -d @$endDate +'%d/%m/%Y')"

# Converte as datas de início e fim para um formato legível
startDateFormatted=$(date -d @$startDate +'%d-%m-%Y')
endDateFormatted=$(date -d @$endDate +'%d-%m-%Y')

# Crie os arquivos temporários para listar os arquivos e para o arquivo tar.gz
tempFileList="/tmp/temp_files_to_archive.txt"
tempArchive="/tmp/temp_archive.tar.gz"

# Encontre todos os arquivos .log no diretório especificado
find /db/backup/checklist/auditoria -type f -name "*.log" | while read file
do
    # Calcule o timestamp da última modificação do arquivo
    fileDate=$(date -r "$file" +%s)
    
    # Se o arquivo foi modificado entre a segunda-feira e o domingo da semana passada
    if [ $fileDate -ge $startDate ] && [ $fileDate -le $endDate ]
    then
        # Se o arquivo contém algum dos IPs
        if grep -qE "$ip_grep_string" "$file"
        then
            # Adicione o arquivo à lista de arquivos a serem arquivados
            echo $file >> "$tempFileList"
            # Imprima a lista atual de arquivos
            cat $tempFileList
        fi
    fi
done

# Se a lista de arquivos existe (ou seja, se algum arquivo foi encontrado)
if [ -f "$tempFileList" ]
then
    # Crie um arquivo tar.gz com todos os arquivos da lista
    tar -czf "$tempArchive" -T "$tempFileList"
    # Copie o arquivo para o servidor remoto
    scp "$tempArchive" auditoria@10.17.191.1:/gluster/volume1/home/auditoria/audit-clientes/inpasa/"$startDateFormatted"-"$endDateFormatted"-Inpasa-audit.tar.gz

    # Remova os arquivos temporários
    rm "$tempFileList"
    rm "$tempArchive"
fi
