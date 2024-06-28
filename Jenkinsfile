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

                        echo "Working good"
                    }
                }
            }
        }



stage('Deploy to EC2') {
    steps {
        script {
            echo "Deploying to EC2 with ECR Registry URL: ${ECR_REGISTRY_URL}, TAG: ${TAG}, SSH_USER: ${env.SSH_USER}, SSH_KEY: **** , EC2_INSTANCE_IP: ${EC2_INSTANCE_IP}"
            
            // Check if critical variables are null or undefined
            if (!env.SSH_KEY || !env.SSH_USER || !EC2_INSTANCE_IP || !ECR_REGISTRY_URL || !TAG) {
                error "One or more required variables are null or undefined."
            }

            
            withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key')]) {
                def remoteCommand = """
                    aws ecr get-login-password --region ${env.AWS_DEFAULT_REGION} | sudo docker login --username AWS --password-stdin ${ECR_REGISTRY_URL}:${env.TAG} &&
                    sudo docker pull ${ECR_REGISTRY_URL}:${env.TAG} &&
                    sudo docker run -d -p 8100:8100 ${ECR_REGISTRY_URL}:${env.TAG}
                """
                
                echo "Executing SSH command:"
                // echo "ssh -i ${env.SSH_KEY} -o StrictHostKeyChecking=no ${env.SSH_USER}@${EC2_INSTANCE_IP} '${remoteCommand}'"
                
                // Execute SSH command
                sh """
                    ssh -i ${env.SSH_KEY} -o StrictHostKeyChecking=no ${env.SSH_USER}@${EC2_INSTANCE_IP} '${remoteCommand}'
                """
                
                echo "SSH command executed successfully."
            }
        }
    }
}



    }
}
