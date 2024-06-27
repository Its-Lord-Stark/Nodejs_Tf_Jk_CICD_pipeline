pipeline {
    agent any
    environment {
        TF_CLI_ARGS_INIT = "-input=false"
        AWS_DEFAULT_REGION = "ap-south-1"
        DOCKER_IMAGE_TAG = "my-node-app:latest"
        ECR_REGISTRY_URL = "PlaceHolder"
        AWS_ACCOUNT_ID = "939533572395"
        EC2_INSTANCE_IP = "PlaceHolder"
        SSH_USER = "ec2-user"
        SSH_KEY = credentials('ec2-ssh-key')
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
                    docker.build("${DOCKER_IMAGE_TAG}", ".")
                }
            }
        }

        stage("Apply Terraform") {
            steps {
                withCredentials([string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                                 string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        bat 'terraform init'
                        bat 'terraform apply -auto-approve'

                        def ec2InstanceIp = bat(script: 'terraform output -raw ec2_instance_ip', returnStdout: true).trim()
                        def ecrRegistryUrl = bat(script: 'terraform output -raw ecr_repository_url', returnStdout: true).trim()

                        env.EC2_INSTANCE_IP = ec2InstanceIp
                        env.ECR_REGISTRY_URL = ecrRegistryUrl
                    }
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'), 
                                     string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')]) {
                        bat "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY_URL}"
                    }

                    docker.withRegistry("https://${ECR_REGISTRY_URL}", "ecr:ap-south-1:${AWS_ACCESS_KEY_ID}") {
                        docker.image("${DOCKER_IMAGE_TAG}").push()
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sshagent(credentials: ['ec2-ssh-key']) {
                        bat "ssh -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_INSTANCE_IP} 'docker pull ${ECR_REGISTRY_URL}/${DOCKER_IMAGE_TAG} && docker run -d -p 8100:8100 ${ECR_REGISTRY_URL}/${DOCKER_IMAGE_TAG}'"
                    }
                }
            }
        }
    }
}
