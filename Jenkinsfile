pipeline {
    agent any
    environment {
        TF_CLI_ARGS_INIT = "-input=false"
        AWS_DEFAULT_REGION = "ap-south-1"
        DOCKER_IMAGE_TAG = "node-server-repo:latest"
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

                        // Set the environment variables dynamically
                        EC2_INSTANCE_IP = ec2InstanceIp.split("\n")[-1].trim()
                        ECR_REGISTRY_URL = ecrRegistryUrl.split("\n")[-1].trim()

                        // Print out the IP and URL for debugging
                        // echo "EC2 Instance IP: ${env.EC2_INSTANCE_IP}"
                        // echo "ECR Registry URL: ${env.ECR_REGISTRY_URL}"
                    }
                }
            }
        }

        // stage('Push Docker Image to ECR') {
        //     steps {
        //         script {
        //             echo "ECR Registry URL before login: ${ECR_REGISTRY_URL}"

        //             withCredentials([string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'), 
        //                              string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')]) {
        //                 bat "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY_URL}"
        //             }

        //             echo "ECR Registry URL after login: ${ECR_REGISTRY_URL}"

        //             docker.withRegistry("https://${ECR_REGISTRY_URL}") {
        //                 docker.image("${DOCKER_IMAGE_TAG}").push()

        //             echo "Work until here"
        //             }
        //         }
        //     }
        // }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    echo "ECR Registry URL before login: ${ECR_REGISTRY_URL}"

                    withCredentials([string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'), 
                                     string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')]) {
                        // Login to ECR
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
            withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY_PATH')]) {
                def remoteCommand = """
                    aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | sudo docker login --username AWS --password-stdin ${ECR_REGISTRY_URL} &&
                    sudo docker pull ${ECR_REGISTRY_URL}/${DOCKER_IMAGE_TAG} &&
                    sudo docker run -d -p 8100:8100 ${ECR_REGISTRY_URL}/${DOCKER_IMAGE_TAG}
                """
                sh """
                    ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_INSTANCE_IP} '${remoteCommand}'
                """
            }
        }
    }
}






    }
}
