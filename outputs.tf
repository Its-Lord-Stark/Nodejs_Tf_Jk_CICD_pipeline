output "aws_instance_ip" {
    value = aws_instance.my_instance.public_ip
}

output "ecr_repository_url" {
    value = aws_ecr_repository.my_ecr_repo.repository_url
}
