#!/bin/bash

echo "=== Iniciando a exclusão da infraestrutura ==="

echo "1. Removendo usuários e seus respectivos diretórios padrão..."
userdel -r -f carlos
userdel -r -f maria
userdel -r -f joao
userdel -r -f debora
userdel -r -f sebastiana
userdel -r -f roberto
userdel -r -f josefina
userdel -r -f amanda
userdel -r -f rogerio

echo "2. Removendo grupos de usuários..."
groupdel GRP_ADM
groupdel GRP_VEN
groupdel GRP_SEC

echo "3. Removendo diretórios criados..."
rm -rf /publico
rm -rf /adm
rm -rf /ven
rm -rf /sec

echo "=== Limpeza concluída com sucesso! ==="
