#!/bin/bash
set -e
GITLABFILE=./.gitlab-ci.yml
if test -f "$GITLABFILE"; then
    echo "Pre-check run ..."
    echo "$GITLABFILE exists."
    exit
fi

DEPLOYDIR=./deploy/development.config
if test -f "$DEPLOYDIR"; then
    echo "Pre-check run ..."
    echo "Deploy directory exists."
    exit
fi

echo "Please Enter the project name: | e.g singelsmsapi NOTE: DO NOT use underscores or spaces. | "
read projectname
export PROJECTNAME=$projectname

echo "Please Enter the project group: | e.g messaging this is the software group the project belongs to. NOTE: DO NOT use underscores or spaces.| "
read projectgroup
export PROJECTGROUP=$projectgroup

PS3="Enter number for Pipeline type: | e.g |1. docker |2. jib-maven |3. jib-gradle | "
options=("docker" "jib-maven" "jib-gradle")
select opt in "${options[@]}"
do
    case $opt in
        "docker")
            echo "$REPLY: $opt pipeline seclected."
            export PIPELINETYPESELECT=$opt
            break
            ;;
        "jib-maven")
            echo "$REPLY: $opt pipeline seclected."
            export PIPELINETYPESELECT=$opt
            break
            ;;
        "jib-gradle")
            echo "$REPLY: $opt pipeline seclected."
            export PIPELINETYPESELECT=$opt
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done


# Download latest ci/cd project from Gitlab

EXT=".git"

BRANCH="master"

DOWNLOAD_URL="git.prod.cellulant.com/ops-templates/ci-cd-workflows/rok8s-scripts/getting-started"

COMMAND="git clone --depth 1 -b $BRANCH https://$DOWNLOAD_URL$EXT ."

echo "Setting Up CI/CD base project from $DOWNLOAD_URL"


mkdir ./deploy
cd ./deploy
$COMMAND
cd ./deploy

echo ""
echo "extracting CI/CD template to project root"
mv * ../
cd ../
mv .gitlab-ci.yml ../

echo "phase1: cleaning up"
rm -rf $EXT
rm -rf ./deploy
rm -f ./template.gitlab-ci.yml
cd ../

if [[ "$OSTYPE" == "linux-gnu" ]]; then
	OS="linux"
    export SED='sed -i' 
    echo "OS | '$OS'. sed | '$SED'. "
elif [[ "$OSTYPE" == "darwin"* ]]; then
	OS="darwin"
    export SED="sed -i '' -e"
    echo "OS | '$OS'. sed | '$SED'. "
elif [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] ; then
	OS="windows"
	export SED='sed -i ' 
    echo "OS | '$OS'. sed | '$SED'. "
else
	echo "No sed command available for OS '$OSTYPE'. using default."
    export SED='sed -i '
    echo "OS | '$OS'. sed | '$SED'. " 
  exit
fi


echo "executing CI/CD config"
#configure gitlab yml
$SED 's@PROJECT@'"$PROJECTNAME"'@g' ./.gitlab-ci.yml
$SED 's@GROUP@'"$PROJECTGROUP"'@g' ./.gitlab-ci.yml
$SED 's@PIPELINETYPE@'"$PIPELINETYPESELECT"'@g' ./.gitlab-ci.yml

#configure config variables
$SED 's@PROJECT@'"$PROJECTNAME"'@g' ./deploy/*.config
$SED 's@GROUP@'"$PROJECTGROUP"'@g' ./deploy/*.config

#configure helm chart variables
for i in ./deploy/charts/demo/*.yaml; do
    $SED 's@demo@'"$PROJECTNAME"'@g' $i
done

for i in ./deploy/charts/demo/templates/*.yaml; do
    $SED 's@demo@'"$PROJECTNAME"'@g' $i
done

echo "phase2: cleaning up"
cd ./deploy/charts
mv demo $PROJECTNAME
cd ../../

echo ""
echo "CI/CD template successfully installed to project"
echo ""