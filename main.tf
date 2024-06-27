provider "aws" {
  region = "ap-south-1"
}

resource "aws_iam_role" "my_instance_role" {
  name = "ec2-instance-role"  
  
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_instance" "my_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = {
    Name = "node-server-instance"
  }
  
  iam_instance_profile =aws_iam_role.my_instance_role.name 
  
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name = "node-server-repo"
  
  tags = {
    Environment = "Dev"
  }
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    
    resources = [
      aws_ecr_repository.my_ecr_repo.arn 
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.my_instance_role.name
  policy_arn = aws_iam_policy_document.ecr_policy.arn 
}
