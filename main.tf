provider "aws" {
  region = "ap-south-1"
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name = "node-server-repo"

  tags = {
    Environment = "DEV"
  }
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

resource "aws_iam_role_policy" "ecr_policy" {
  name = "ecr-policy"
  role = aws_iam_role.my_instance_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken"  # Added permission
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "my_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.my_instance_role.name
}

resource "aws_instance" "my_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = "NodeJSCicd"

  tags = {
    Name = "node-server-instance"
  }

  iam_instance_profile = aws_iam_instance_profile.my_instance_profile.name
}
