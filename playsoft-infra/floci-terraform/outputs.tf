output "vpc_id" {
  value = aws_vpc.main.id
}

output "alb_dns" {
  value = aws_lb.web.dns_name
}

output "s3_bucket" {
  value = aws_s3_bucket.backup.bucket
}