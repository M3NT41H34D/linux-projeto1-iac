#!/bin/bash

echo "=== Iniciando a criação da infraestrutura de usuários ==="

echo "1. Criando diretórios públicos e restritos..."
mkdir /publico
mkdir /adm
mkdir /ven
mkdir /sec

echo "2. Criando grupos de usuários..."
groupadd GRP_ADM
groupadd GRP_VEN
groupadd GRP_SEC

echo "3. Criando usuários e associando aos seus respectivos grupos..."
# Especificamos o shell padrão (-s) e forçamos a criação do diretório home (-m)
# Além disso, já adicionamos o usuário ao grupo principal (-g)

# Grupo ADM
useradd carlos -m -s /bin/bash -g GRP_ADM
useradd maria -m -s /bin/bash -g GRP_ADM
useradd joao -m -s /bin/bash -g GRP_ADM

# Grupo VEN
useradd debora -m -s /bin/bash -g GRP_VEN
useradd sebastiana -m -s /bin/bash -g GRP_VEN
useradd roberto -m -s /bin/bash -g GRP_VEN

# Grupo SEC
useradd josefina -m -s /bin/bash -g GRP_SEC
useradd amanda -m -s /bin/bash -g GRP_SEC
useradd rogerio -m -s /bin/bash -g GRP_SEC

echo "4. Definindo os donos e grupos dos diretórios (chown)..."
# O dono de todas as pastas será o root
chown root:root /publico
chown root:GRP_ADM /adm
chown root:GRP_VEN /ven
chown root:GRP_SEC /sec

echo "5. Ajustando as permissões de acesso (chmod)..."
# /publico: Todos podem ler, escrever e executar (777 ou rwxrwxrwx)
chmod 777 /publico

# Pastas restritas: Dono e Grupo têm acesso total. Demais usuários não veem nada (770 ou rwxrwx---)
chmod 770 /adm
chmod 770 /ven
chmod 770 /sec

echo "=== Infraestrutura criada com sucesso! ==="
