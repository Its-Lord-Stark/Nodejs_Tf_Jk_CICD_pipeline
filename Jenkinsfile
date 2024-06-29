pipeline {
    agent any
    
    environment {
        TF_CLI_ARGS_INIT = "-input=false"
        AWS_DEFAULT_REGION = "ap-south-1"
        DOCKER_IMAGE_TAG = "node-server-repo:latest"
        TAG = "latest"
        ECR_REGISTRY_URL = "placeholder"  // Placeholder for now
        AWS_ACCOUNT_ID = "939533572395"
        EC2_INSTANCE_IP = "placeholder"  // Placeholder for now
        SSH_USER = "ec2-user"
        SSH_KEY = credentials('ec2-ssh-key')  // Assuming 'ec2-ssh-key' is the ID of your SSH private key credential
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

                        // Capture the outputs from Terraform
                        def ec2InstanceIp = bat(script: 'terraform output -raw aws_instance_ip', returnStdout: true).trim()
                        def ecrRegistryUrl = bat(script: 'terraform output -raw ecr_repository_url', returnStdout: true).trim()

                        EC2_INSTANCE_IP = ec2InstanceIp.split("\n")[-1].trim()
                        ECR_REGISTRY_URL = ecrRegistryUrl.split("\n")[-1].trim()
                        env.EC2_INSTANCE_IP = ec2InstanceIp.split("\n")[-1].trim()
                        env.ECR_REGISTRY_URL = ecrRegistryUrl.split("\n")[-1].trim()
                    }
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    echo "ECR Registry URL before login: ${ECR_REGISTRY_URL}"

                    withCredentials([string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'), 
                                     string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')]) {
                        bat "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY_URL}"
                    }

                    echo "ECR Registry URL after login: ${ECR_REGISTRY_URL}"

                    retry(3) {
                        docker.withRegistry("https://${ECR_REGISTRY_URL}") {
                            docker.image("${DOCKER_IMAGE_TAG}").push()
                        }

                        echo "Push to ECR successfully done."
                    }
                }
            }
        }
    
        stage('Deploy to EC2') {
            steps {
                script {
                    try {
                        sshagent(['ec2-ssh-key']) {
                            def remoteCommand = """
                                aws ecr get-login-password --region ${env.AWS_DEFAULT_REGION} | sudo docker login --username AWS --password-stdin ${ECR_REGISTRY_URL}:${env.TAG} &&
                                sudo docker pull ${ECR_REGISTRY_URL}:${env.TAG} &&
                                sudo docker run -d -p 8100:8100 ${ECR_REGISTRY_URL}:${env.TAG}
                            """

                            sh """
                                ssh -o StrictHostKeyChecking=no ${env.SSH_USER}@${EC2_INSTANCE_IP} '${remoteCommand}'
                            """
                            
                            echo "SSH command executed successfully."
                        }
                    } catch (Exception e) {
                        echo "Failed to deploy to EC2: ${e.message}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        
    }
    }
}
