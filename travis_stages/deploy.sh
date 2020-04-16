docker build -t freakency/devops_minitwit_app app/
docker build -t freakency/devops_minitwit_api api/
docker build -t freakency/devops_minitwit_stalker stalker/
echo "$docker_password" | docker login -u "$docker_user" --password-stdin
docker push freakency/devops_minitwit_app
docker push freakency/devops_minitwit_api
docker push freakency/devops_minitwit_stalker
openssl aes-256-cbc -K $encrypted_9a76d64de8ba_key -iv $encrypted_9a76d64de8ba_iv -in deploy_key.enc -out ./deploy_key -d
eval "$(ssh-agent -s)"
chmod 600 ./deploy_key
echo -e "Host $SERVER_IP_ADDRESS\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
ssh-add ./deploy_key
# ssh -i ./deploy_key -o "StrictHostKeyChecking no" root@janschill.de "docker images |grep -v REPOSITORY|awk '{print $1}'|xargs -L1 docker pull && docker-compose -f /root/minitwit/docker-compose.yml down && docker-compose -f /root/minitwit/docker-compose.yml up -d && docker-compose -f /root/minitwit/logging_elk/docker-compose.yml down && docker-compose -f /root/minitwit/logging_elk/docker-compose.yml up -d"
ssh -i ./deploy_key -o "StrictHostKeyChecking no" root@janschill.de "docker-compose -f /root/minitwit/docker-compose.yml down && docker-compose -f /root/minitwit/docker-compose.yml up -d && docker-compose -f /root/minitwit/logging_elk/docker-compose.yml down && docker-compose -f /root/minitwit/logging_elk/docker-compose.yml up -d"

# Keeping this line here for debug purpose
# ssh -i ./deploy_key -o "StrictHostKeyChecking no" root@janschill.de "docker rm -f minitwit && docker pull freakency/devops && docker run --name minitwit -v /root/db:/var/www/db -p 80:80 -p 1337:1337 --rm -d freakency/devops"