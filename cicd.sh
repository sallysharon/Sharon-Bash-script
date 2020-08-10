#!/bin/bash
set -e
CICD_GITLABFILE=./.gitlab-ci.yml
if test -f "$CICD_GITLABFILE"; then
    echo "Pre-check run ..."
    echo "$CICD_GITLABFILE exists."
    exit
fi

CICD_DEPLOYDIR=./deploy/development.config
if test -f "$CICD_DEPLOYDIR"; then
    echo "Pre-check run ..."
    echo "Deploy directory exists."
    exit
fi

echo "Please Enter the project name: | e.g singelsmsapi NOTE: DO NOT use underscores or spaces. | "
read projectname
export CICD_PROJECTNAME=$projectname

echo "Please Enter the project group: | e.g messaging this is the software group the project belongs to. NOTE: DO NOT use underscores or spaces.| "
read projectgroup
export CICD_PROJECTGROUP=$projectgroup

PS3="Enter number for Pipeline type: | e.g |1. docker |2. jib-maven |3. jib-gradle | "
options=("docker" "jib-maven" "jib-gradle")
select opt in "${options[@]}"
do
    case $opt in
        "docker")
            echo "$REPLY: $opt pipeline seclected."
            export CICD_PIPELINETYPESELECT=$opt
            break
            ;;
        "jib-maven")
            echo "$REPLY: $opt pipeline seclected."
            export CICD_PIPELINETYPESELECT=$opt
            break
            ;;
        "jib-gradle")
            echo "$REPLY: $opt pipeline seclected."
            export CICD_PIPELINETYPESELECT=$opt
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done


# Download latest ci/cd project from Gitlab

CICD_EXT=".git"

CICD_BRANCH="master"

CICD_DOWNLOAD_URL="git.prod.cellulant.com/ops-templates/ci-cd-workflows/rok8s-scripts/getting-started"

CICD_COMMAND="git clone --depth 1 -b $CICD_BRANCH https://$CICD_DOWNLOAD_URL$EXT ."

echo "Setting Up CI/CD base project from $CICD_DOWNLOAD_URL"


mkdir ./deploy
cd ./deploy
if ! $CICD_COMMAND; then
    exit
fi
cd ./deploy

echo ""
echo "extracting CI/CD template to project root"
mv * ../
cd ../
mv .gitlab-ci.yml ../

echo "phase1: cleaning up"
rm -rf $CICD_EXT
rm -rf ./deploy
cd ../

if [[ "$OSTYPE" == "linux-gnu" ]]; then
	OS="linux"
    export CICD_SED='sed -i' 
    echo "OS | '$OS'. sed | '$CICD_SED'. "
elif [[ "$OSTYPE" == "darwin"* ]]; then
	OS="darwin"
    export CICD_SED="sed"
    echo "OS | '$OS'. sed | '$CICD_SED'. "
elif [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] ; then
	OS="windows"
	export CICD_SED='sed -i ' 
    echo "OS | '$OS'. sed | '$CICD_SED'. "
else
	echo "No sed command available for OS '$OSTYPE'. using default."
    export CICD_SED='sed -i '
    echo "OS | '$OS'. sed | '$CICD_SED'. " 
  exit
fi


echo "executing CI/CD config"
#configure gitlab yml
$CICD_SED 's@PROJECT@'"$CICD_PROJECTNAME"'@g' ./.gitlab-ci.yml
$CICD_SED 's@GROUP@'"$CICD_PROJECTGROUP"'@g' ./.gitlab-ci.yml
$CICD_SED 's@PIPELINETYPE@'"$CICD_PIPELINETYPESELECT"'@g' ./.gitlab-ci.yml

#configure config variables
$CICD_SED 's@PROJECT@'"$CICD_PROJECTNAME"'@g' ./deploy/*.config
$CICD_SED 's@GROUP@'"$CICD_PROJECTGROUP"'@g' ./deploy/*.config

#configure helm chart variables
for i in ./deploy/charts/demo/*.yaml; do
    $CICD_SED 's@demo@'"$CICD_PROJECTNAME"'@g' $i
done

for i in ./deploy/charts/demo/templates/*.yaml; do
    $CICD_SED 's@demo@'"$CICD_PROJECTNAME"'@g' $i
done
$CICD_SED 's@demo@'"$CICD_PROJECTNAME"'@g' ./deploy/charts/demo/templates/tests/*.yaml
$CICD_SED 's@demo@'"$CICD_PROJECTNAME"'@g' ./deploy/charts/demo/templates/_helpers.tpl

echo "phase2: cleaning up"
rm -f ./deploy/template.gitlab-ci.yml
rm -f ./deploy/cicd.sh
cd ./deploy/charts
mv demo $CICD_PROJECTNAME
cd ../../

echo ""
echo "CI/CD template successfully installed to project"
echo ""