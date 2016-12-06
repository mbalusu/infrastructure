#!/bin/bash -v
apt-get update -y

apt-get install -y python-pip
pip install awscli
apt-get install git

ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id | tr -d 'i-'`

aws ec2 create-tags --region ${aws_region} --resources "i-$${ID}" --tags Key=Name,Value=${service}-$${ID} Key=Environment,Value=${environment}

echo ${regions} > /tmp/aws_regions
echo ${service} > /tmp/service

mkdir -p /root/.ssh
chmod 700 /root/.ssh
cat > /root/.ssh/id_rsa <<EOF
${private_key}
EOF
chmod 400 /root/.ssh/id_rsa
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts

# Install chef and berkshelf
curl -L https://www.opscode.com/chef/install.sh | sudo bash

cd /tmp; git clone git@github.com:mbalusu/infrastructure.git

SERVICE="default"
grep 'openvpn' /tmp/service
if [ $? -eq 0 ]; then
  SERVICE="openvpn"
fi
grep 'mongo' /tmp/service
if [ $? -eq 0 ]; then
  SERVICE="mongo"
fi

if [ $SERVICE == 'openvpn' ]; then
cat > /tmp/nodes.json <<EOF
{
  "aws_region": "${aws_region}",
  "environment": "${environment}",
  "service": "${service}",
  "openvpn" : {
    "server": {
      "ip_block": "${openvpn_server_ip_block}",
      "netmask": "${openvpn_server_netmask}"
    },
    "route": {
      "ip_block": "${openvpn_route_ip_block}",
      "netmask": "${openvpn_route_netmask}"
    },
    "client": {
      "remote_ip" : "${remote_ip}"
    }
  }
}
EOF
elif [ $SERVICE == 'mongo' ]; then
cat > /tmp/nodes.json <<EOF
{
  "aws_region": "${aws_region}",
  "environment": "${environment}",
  "service": "${service}",
  "filesystems": [
    {
      "name": "mongo",
      "type": "ext4",
      "device": "/dev/xvdf",
      "mount": "/data/mongo"
    }
  ]
}
EOF
else
cat > /tmp/nodes.json <<EOF
{
  "aws_region": "${aws_region}",
  "environment": "${environment}",
  "service": "${service}"
}
EOF
fi
chef-solo -c /tmp/infrastructure/chef/solo.rb -o ${run_list}

grep 'mongo-master' /tmp/service
if [ $? -eq 0 ]; then
sleep 300
SLAVE_IP=`aws ec2 describe-instances --region ${aws_region} --filters 'Name=instance-state-name,Values=running' 'Name=tag:Name,Values=mongo-slave*' --query 'Reservations[0].Instances[0].PrivateIpAddress'`
ARBITER_IP=`aws ec2 describe-instances --region ${aws_region} --filters 'Name=instance-state-name,Values=running' 'Name=tag:Name,Values=mongo-arbiter*' --query 'Reservations[0].Instances[0].PrivateIpAddress'`
while [ "x$SLAVE_IP" == "x" ]; do
  sleep 300
  SLAVE_IP=`aws ec2 describe-instances --region ${aws_region} --filters 'Name=instance-state-name,Values=running' 'Name=tag:Name,Values=mongo-slave*' --query 'Reservations[0].Instances[0].PrivateIpAddress'`
done
while [ "x$ARBITER_IP" == "x" ]; do
  sleep 300
  ARBITER_IP=`aws ec2 describe-instances --region ${aws_region} --filters 'Name=instance-state-name,Values=running' 'Name=tag:Name,Values=mongo-arbiter*' --query 'Reservations[0].Instances[0].PrivateIpAddress'`
done

echo "Initiating ReplicaSet"
mongo <<EOF
rs.initiate()
EOF

sleep 10
echo "Adding slave $SLAVE_IP"
mongo <<EOF
rs.add($SLAVE_IP)
EOF

sleep 10
echo "Adding arbiter $ARBITER_IP"
mongo <<EOF
rs.addArb($ARBITER_IP)
EOF
fi
