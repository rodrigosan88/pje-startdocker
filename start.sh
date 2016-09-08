#!/bin/bash

### Rodrigo Santos Menezes
### Conselho Nacional de Justica
### PJe

WF_DEPLOY_FOLDER=/server/wildfly/standalone/deployments
WF_STANDALONE_CONFIG_FILE=/server/wildfly/standalone/configuration/standalone.xml
JAVA_OPTS = -Xms128m -Xmx1024m -XX:MaxPermSize=512m

prop () {
    grep "${1}" /pje_config/pje_config.properties|cut -d'=' -f2
}

DB_USER=$(prop 'db.usuario')
DB_HOST=$(prop 'db.servidor')
DB_PORT=$(prop 'db.porta')
DB_PASS=$(prop 'db.senha')
DB_NAME=$(prop 'db.nome')

DB_BIN_USER=$(prop 'db.bin.usuario')
DB_BIN_HOST=$(prop 'db.bin.servidor')
DB_BIN_PORT=$(prop 'db.bin.porta')
DB_BIN_PASS=$(prop 'db.bin.senha')
DB_BIN_NAME=$(prop 'db.bin.nome')

DB_LOG_USER=$(prop 'db.log.usuario')
DB_LOG_HOST=$(prop 'db.log.servidor')
DB_LOG_PORT=$(prop 'db.log.porta')
DB_LOG_PASS=$(prop 'db.log.senha')
DB_LOG_NAME=$(prop 'db.log.nome')

GIT_BRANCH_DEV_PJE1=$(prop 'pje.git.branch.desenvolvedor')
GIT_BRANCH_DEV_PJE2=$(prop 'pje2.git.branch.desenvolvedor')
GIT_BRANCH_MASTER_PJE1=$(prop 'pje.git.branch.master')
GIT_BRANCH_MASTER_PJE2=$(prop 'pje2.git.branch.master')

### Verifica se todas as variáveis obrigatórias foram informadas
echo "CONFIGURANDO ARQUIVO DE CONEXAO COM O BANCO DE DADOS"
if [ "$DB_USER" != "" ] && [ "$DB_HOST" != "" ] && [ "$DB_PORT" != "" ] && [ "$DB_PASS" != "" ] && [ "$DB_NAME" != "" ]; then
	sed -i "s/##DB_USER##/$DB_USER/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_HOST##/$DB_HOST/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_PORT##/$DB_PORT/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_PASS##/$DB_PASS/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_NAME##/$DB_NAME/g" $WF_STANDALONE_CONFIG_FILE
else
	exit 1
fi

if [ "$DB_BIN_USER" != "" ] && [ "$DB_BIN_HOST" != "" ] && [ "$DB_BIN_PORT" != "" ] && [ "$DB_BIN_PASS" != "" ] && [ "$DB_BIN_NAME" != "" ]; then
	sed -i "s/##DB_BIN_USER##/$DB_BIN_USER/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_BIN_HOST##/$DB_BIN_HOST/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_BIN_PORT##/$DB_BIN_PORT/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_BIN_PASS##/$DB_BIN_PASS/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_BIN_NAME##/$DB_BIN_NAME/g" $WF_STANDALONE_CONFIG_FILE
else
	echo "Nao foram iformadas credenciais para conexao com o banco binario :("
fi

if [ "$DB_LOG_USER" != "" ] && [ "$DB_LOG_HOST" != "" ] && [ "$DB_LOG_PORT" != "" ] && [ "$DB_LOG_PASS" != "" ] && [ "$DB_LOG_NAME" != "" ]; then
	sed -i "s/##DB_LOG_USER##/$DB_LOG_USER/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_LOG_HOST##/$DB_LOG_HOST/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_LOG_PORT##/$DB_LOG_PORT/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_LOG_PASS##/$DB_LOG_PASS/g" $WF_STANDALONE_CONFIG_FILE
	sed -i "s/##DB_LOG_NAME##/$DB_LOG_NAME/g" $WF_STANDALONE_CONFIG_FILE
else
	echo "Nao foram iformadas credenciais para conexao com o banco de log :("
fi

if [ "$GIT_BRANCH_MASTER_PJE1" = "" ]; then 
	GIT_BRANCH_MASTER_PJE1=master.2.x_WF
fi

if [ "$GIT_BRANCH_MASTER_PJE2" = "" ]; then 
	GIT_BRANCH_MASTER_PJE2=master
fi

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no git@git.cnj.jus.br
ssh-keyscan -t rsa git.cnj.jus.br > ~/.ssh/known_hosts

### Clonando repositórios do git
echo "CLONANDO REPOSITORIOS"
cd /git 
git clone git@git.cnj.jus.br:pje/pje.git 
cd /git 
git clone git@git.cnj.jus.br:pje-2/pje2.git

### Preparando branches PJe 1.x
cd /git/pje
if [ "$GIT_BRANCH_DEV_PJE1" != "" ]; then
	echo "Fazendo checkout do branch $GIT_BRANCH_DEV_PJE1"
	git checkout -b $GIT_BRANCH_DEV_PJE1 origin/$GIT_BRANCH_DEV_PJE1
	echo "Realizando rebase com o branch $GIT_BRANCH_MASTER_PJE1"
	git rebase origin/$GIT_BRANCH_MASTER_PJE1
else
	echo "Nenhum branch de desenvolvimento foi informado! O ambiente será montado a partir do branch master"
	git checkout -b $GIT_BRANCH_MASTER_PJE1 origin/$GIT_BRANCH_MASTER_PJE1
fi

### Preparando branches PJe 1.x
cd /git/pje2
if [ "$GIT_BRANCH_DEV_PJE2" != "" ]; then
	echo "Fazendo checkout do branch $GIT_BRANCH_DEV_PJE2"
	git checkout -b $GIT_BRANCH_DEV_PJE2 origin/$GIT_BRANCH_DEV_PJE2
	echo "Realizando rabase com o branch $GIT_BRANCH_MASTER_PJE2"
	git rebase origin/$GIT_BRANCH_MASTER_PJE2
else
	echo "Nenhum branch de desenvolvimento foi informado! O ambiente será montado a partir do branch master"
	git checkout -b $GIT_BRANCH_MASTER_PJE2 origin/$GIT_BRANCH_MASTER_PJE2
fi

### Montando pacote do projeto PJe1
echo "MONTANDO PACOTE PJe"
cd /git/pje 
mvn -P db-storage-postgres clean package -DskipTests -Dmaven.test.skip=true -q
mv /git/pje/pje-web/target/pje.war $WF_DEPLOY_FOLDER/pje-web.war 
cd /$WF_DEPLOY_FOLDER 
touch pje-web.dodeploy 

### Montando pacote do projeto PJe2
echo "MONTANDO PACOTE PJe 2.0"
cd /git/pje2 
mvn clean package -q
mv /git/pje2/pje2-ear/target/pje2-ear-2.0.1-SNAPSHOT.ear $WF_DEPLOY_FOLDER/pje2-ear-2.0.1-SNAPSHOT.ear 
cd /$WF_DEPLOY_FOLDER 
touch pje2-ear-2.0.1-SNAPSHOT.dodeply

### iniciando servidor de aplicacao
echo "INICIANDO SERVIDOR DE APLICACAO"
/server/wildfly/bin/standalone.sh -b=0.0.0.0

