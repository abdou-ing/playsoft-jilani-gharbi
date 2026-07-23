#!/bin/bash
echo "========================================="
echo "     FLOCI TERRAFORM DEPLOYMENT CHECK    "
echo "========================================="

echo -e "\n📌 1. TESTING ALB ENDPOINT"
echo "-----------------------------------------"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://nginx-alb-bdb416d107c64696.elb.localhost.floci.io
echo -e "\nFirst 5 lines of response:"
curl -s http://nginx-alb-bdb416d107c64696.elb.localhost.floci.io | head -5

echo -e "\n📌 2. AUTO SCALING GROUP STATUS"
echo "-----------------------------------------"
aws autoscaling describe-auto-scaling-groups --endpoint-url=http://localhost:4566 --auto-scaling-group-names nginx-asg

echo -e "\n📌 3. EC2 INSTANCES"
echo "-----------------------------------------"
aws ec2 describe-instances --endpoint-url=http://localhost:4566 --filters "Name=tag:aws:autoscaling:groupName,Values=nginx-asg"

echo -e "\n📌 4. TARGET GROUP HEALTH"
echo "-----------------------------------------"
aws elbv2 describe-target-health --endpoint-url=http://localhost:4566 --target-group-arn arn:aws:elasticloadbalancing:us-east-1:000000000000:targetgroup/nginx-target/77bf4183d34345a4

echo -e "\n📌 5. LOAD BALANCER DETAILS"
echo "-----------------------------------------"
aws elbv2 describe-load-balancers --endpoint-url=http://localhost:4566 --names nginx-alb --query 'LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]' --output table

echo -e "\n📌 6. VPC INFORMATION"
echo "-----------------------------------------"
aws ec2 describe-vpcs --endpoint-url=http://localhost:4566 --vpc-ids vpc-abe9a86a --query 'Vpcs[*].[VpcId,CidrBlock,State]' --output table

echo -e "\n📌 7. SUBNETS"
echo "-----------------------------------------"
aws ec2 describe-subnets --endpoint-url=http://localhost:4566 --filters "Name=vpc-id,Values=vpc-abe9a86a" --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch]' --output table

echo -e "\n📌 8. ROUTE TABLES"
echo "-----------------------------------------"
aws ec2 describe-route-tables --endpoint-url=http://localhost:4566 --filters "Name=vpc-id,Values=vpc-abe9a86a" --query 'RouteTables[*].{RT:RouteTableId,VPC:VpcId,Routes:Routes[?GatewayId!=`local`]|[?DestinationCidrBlock]}' --output table

echo -e "\n📌 9. SECURITY GROUPS"
echo "-----------------------------------------"
aws ec2 describe-security-groups --endpoint-url=http://localhost:4566 --filters "Name=vpc-id,Values=vpc-abe9a86a" --query 'SecurityGroups[*].[GroupId,GroupName,Description]' --output table

echo -e "\n📌 10. S3 BUCKET CONTENT"
echo "-----------------------------------------"
aws s3 ls floci-demo-backup --endpoint-url=http://localhost:4566 2>/dev/null || echo "Bucket is empty or not accessible"

echo -e "\n📌 11. LOAD TEST (10 requests)"
echo "-----------------------------------------"
for i in {1..10}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://nginx-alb-bdb416d107c64696.elb.localhost.floci.io)
  echo "Request $i: HTTP $STATUS"
done

echo -e "\n📌 12. GET INSTANCE PUBLIC IPs"
echo "-----------------------------------------"
for instance in $(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --filters "Name=tag:aws:autoscaling:groupName,Values=nginx-asg" --query 'Reservations[*].Instances[*].InstanceId' --output text); do
  IP=$(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --instance-ids $instance --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
  STATE=$(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --instance-ids $instance --query 'Reservations[*].Instances[*].State.Name' --output text)
  echo "Instance $instance: $STATE, IP: $IP"
done

echo -e "\n📌 13. CURL INDIVIDUAL INSTANCES"
echo "-----------------------------------------"
for instance in $(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --filters "Name=tag:aws:autoscaling:groupName,Values=nginx-asg" --query 'Reservations[*].Instances[*].InstanceId' --output text); do
  IP=$(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --instance-ids $instance --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
  if [ ! -z "$IP" ]; then
    echo "Testing instance $instance ($IP):"
    curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$IP
  fi
done

echo -e "\n========================================="
echo "     CHECK COMPLETE!                       "
echo "========================================="