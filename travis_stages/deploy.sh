docker build -t freakency/devops .
echo "$docker_password" | docker login -u "$docker_user" --password-stdin
docker push freakency/devops
openssl aes-256-cbc -K $encrypted_9a76d64de8ba_key -iv $encrypted_9a76d64de8ba_iv -in deploy_key.enc -out ./deploy_key -d
eval "$(ssh-agent -s)"
chmod 600 ./deploy_key
echo -e "Host $SERVER_IP_ADDRESS\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
ssh-add ./deploy_key
ssh -i ./deploy_key -o "StrictHostKeyChecking no" root@janschill.de "docker rm -f minitwit && docker pull freakency/devops && docker run --name minitwit -p 80:80 -p 1337:1337 --rm -d freakency/devops"