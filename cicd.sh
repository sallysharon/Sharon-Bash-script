#!/bin/bash
set -e
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

echo "cleaning up"
rm -rf $EXT
rm -rf ./deploy
cd ../


#configure gitlab yml
sed -i 's@PROJECT@'"$PROJECTNAME"'@g' ./.gitlab-ci.yml
sed -i 's@GROUP@'"$PROJECTGROUP"'@g' ./.gitlab-ci.yml
sed -i 's@PIPELINETYPE@'"$PIPELINETYPESELECT"'@g' ./.gitlab-ci.yml

#configure config variables
sed -i 's@PROJECT@'"$PROJECTNAME"'@g' ./deploy/*.config
sed -i 's@GROUP@'"$PROJECTGROUP"'@g' ./deploy/*.config

#configure helm chart variables
for i in ./deploy/charts/demo/*; do
    sed -i 's@demo@'"$PROJECTNAME"'@g' $i
done

cd ./deploy/charts
mv demo $PROJECTNAME
cd ../../

echo ""
echo "CI/CD template successfully installed to project"
echo ""