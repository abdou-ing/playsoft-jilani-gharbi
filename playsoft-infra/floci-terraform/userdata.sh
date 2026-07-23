#!/bin/bash

# Update system
yum update -y

# Install Nginx
yum install nginx -y

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx

# Create custom index.html with your message
echo "<h1>Hello from Floci Terraform EC2</h1>" > /usr/share/nginx/html/index.html

# Add more information
cat >> /usr/share/nginx/html/index.html <<EOF
<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
<p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
<p>Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</p>
<p>Deployed at: $(date)</p>
EOF

# Ensure Nginx is running
systemctl status nginx