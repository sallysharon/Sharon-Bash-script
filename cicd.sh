#!/bin/bash
set -e

echo "Please Enter the project name: e.g singelsmsapi NOTE: DO NOT use underscores or spaces."
read projectname

echo "Please Enter the project group: e.g messaging this is the software group the project belongs to. NOTE: DO NOT use underscores or spaces."
read projectgroup

PS3="Select Pipeline type e.g | docker | jib-maven | jib-gradle |"
options=("docker" "jib-maven" "jib-gradle" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "docker")
            echo "$REPLY: $opt pipeline seclected."
            export PIPELINETYPESELECT=$opt
           
            ;;
        "jib-maven")
            echo "$REPLY: $opt pipeline seclected."
            export PIPELINETYPESELECT=$opt
           
            ;;
        "jib-gradle")
            echo "$REPLY: $opt pipeline seclected."
            export PIPELINETYPESELECT=$opt
            ;;
        "Quit")
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

GITLABFILE=./.gitlab-ci.yml
if test -f "$GITLABFILE"; then
    echo "$GITLABFILE exists."
    exit
fi

DEPLOYDIR=./deploy/development.config
if test -f "$DEPLOYDIR"; then
    echo "Deploy directory exists."
    exit
fi

mkdir ./deploy
cd ./deploy
$COMMAND
cd ./deploy

echo ""
echo "extracting CI/CD template to project root"
mv * ../
cd ../
mv .gitlab-ci.yml ../

echo "cleaning up"
rm -rf $EXT
rm -rf ./deploy
cd ../


#configure gitlab yml
sed -i 's@PROJECT@'"$projectname"'@g' ./.gitlab-ci.yml
sed -i 's@GROUP@'"$projectgroup"'@g' ./.gitlab-ci.yml
sed -i 's@PIPELINETYPE@'"$PIPELINETYPESELECT"'@g' ./.gitlab-ci.yml

#configure config variables
sed -i 's@PROJECT@'"$projectname"'@g' ./deploy/*.config
sed -i 's@GROUP@'"$projectgroup"'@g' ./deploy/*.config

#configure helm chart variables
for i in ./deploy/charts/demo/*; do
    sed -i 's@demo@'"$projectname"'@g' $i
done

cd ./deploy/charts
mv demo $projectname
cd ../../

echo ""
echo "CI/CD template successfully installed to project"
echo ""