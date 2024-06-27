pipeline{
    agent any
    environment{
        TF_CLI_ARGS_INIT = "-input=false"
        AWS_DEFAULT_REGION = "ap-south-1"
        DOCKER_IMAGE_TAG = "my-node-app:latest"
        ECR_REGISTRY_URL = "PlaceHolder"
        AWS_ACCOUNT_ID = "939533572395"
        EC2_INSTANCE_IP = "PlaceHolder"
        SSH_USER = "ec2-user"
        SSH_KEY = credentials('ec2-ssh-key')

    }

    stages{

        stage("Checkout")
        {
           steps{
               checkout scm
           }
            
        }

        stage("Build docekr image")
        {
            steps{
                script{
                    docker.build("${DOCKER_IMAGE_TAG}", ".")
                }
            }
            
        }

        stage("Apply Terraform")
        {
            steps{
                script{
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'

                    EC2_INSTANCE_IP = sh(script: 'terraform output -json ec2_instance_ip', returnStdout: true).trim()
                    ECR_REPOSITORY_URL = sh(script: 'terraform output -json ecr_repository_url', returnStdout: true).trim()

                    // echo "EC2 Instance IP: ${EC2_INSTANCE_IP}"
                    // echo "ECR Repository URL: ${ECR_REPOSITORY_URL}"
                }
            }
        }

         stage('Push Docker Image to ECR') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'aws-ecr-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY_URL}"
                    }

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
                        sh "ssh -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_INSTANCE_IP} 'docker pull ${ECR_REGISTRY_URL}/${DOCKER_IMAGE_TAG} && docker run -d -p 8100:8100 ${ECR_REGISTRY_URL}/${DOCKER_IMAGE_TAG}'"
                    }
                }
            }





    }
}

}