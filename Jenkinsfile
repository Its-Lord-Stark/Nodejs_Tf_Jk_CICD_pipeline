pipeline {
    agent any
    
    environment {
        TF_CLI_ARGS_INIT = "-input=false"
        AWS_DEFAULT_REGION = "ap-south-1"
        DOCKER_IMAGE_TAG = "my-node-app:latest"
        ECR_REGISTRY_URL = "PlaceHolder" // Update this with your ECR Registry URL
        AWS_ACCOUNT_ID = "939533572395"
        EC2_INSTANCE_IP = "PlaceHolder" // Update this with your EC2 instance IP
        SSH_USER = "ec2-user"
        SSH_KEY = credentials('ec2-ssh-key') // Update this with your SSH key credential ID
    }

    stages {
        stage("Checkout") {
            steps {
                checkout scm
            }
        }

        stage("Build Docker Image") {
            steps {
                script {
                    // Use bat for Windows shell commands
                    bat 'docker build -t ${DOCKER_IMAGE_TAG} .'
                }
            }
        }

        stage("Apply Terraform") {
            steps {
                withCredentials([string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                                 string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        // Use bat for Windows shell commands
                        bat 'terraform init'
                        bat 'terraform apply -auto-approve'

                        EC2_INSTANCE_IP = bat(script: 'terraform output -json ec2_instance_ip', returnStdout: true).trim()
                        ECR_REGISTRY_URL = bat(script: 'terraform output -json ecr_repository_url', returnStdout: true).trim()

                        // echo "EC2 Instance IP: ${EC2_INSTANCE_IP}"
                        // echo "ECR Repository URL: ${ECR_REGISTRY_URL}"
                    }
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'aws-ecr-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        bat "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY_URL}"
                    }

                    // Use docker.withRegistry to push image to ECR
                    docker.withRegistry("${ECR_REGISTRY_URL}", "ecr:ap-south-1:${AWS_ACCESS_KEY_ID}") {
                        docker.image("${DOCKER_IMAGE_TAG}").push()
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sshagent(credentials: ['ec2-ssh-key']) {
                        // SSH command to pull and run Docker image on Linux EC2
                        sh "ssh -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_INSTANCE_IP} 'docker pull ${ECR_REGISTRY_URL}/${DOCKER_IMAGE_TAG} && docker run -d -p 8100:8100 ${ECR_REGISTRY_URL}/${DOCKER_IMAGE_TAG}'"
                    }
                }
            }
        }
    }
}
