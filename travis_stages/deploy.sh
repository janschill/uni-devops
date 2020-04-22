echo "Writing database password from Travis CI"
sed -i "s/REDACTED/$mysql_password/g" app/config/database.yml
sed -i "s/REDACTED/$mysql_password/g" api/config/database.yml

echo "Building Docker images"
docker build -t freakency/devops_minitwit_app app/
docker build -t freakency/devops_minitwit_api api/
docker build -t freakency/devops_minitwit_stalker stalker/

echo "Setting up deployment to Docker Hub"
echo "$docker_password" | docker login -u "$docker_user" --password-stdin
docker push freakency/devops_minitwit_app
docker push freakency/devops_minitwit_api
docker push freakency/devops_minitwit_stalker

echo "Setting up deployment to production server"
openssl aes-256-cbc -K $encrypted_9a76d64de8ba_key -iv $encrypted_9a76d64de8ba_iv -in deploy_key.enc -out ./deploy_key -d
eval "$(ssh-agent -s)"
chmod 600 ./deploy_key
echo -e "Host $SERVER_IP_ADDRESS\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
ssh-add ./deploy_key
ssh -i ./deploy_key -o "StrictHostKeyChecking no" root@janschill.de "docker-compose -f /root/minitwit/docker-compose.yml down && docker-compose -f /root/minitwit/docker-compose.yml up -d"
ssh -i ./deploy_key -o "StrictHostKeyChecking no" root@161.35.23.91 "docker-compose -f /root/minitwit/docker-compose.yml down && docker-compose -f /root/minitwit/docker-compose.yml up -d"
