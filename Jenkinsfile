pipeline {
    agent any

    environment {
        APP_REPO_NAME = "esenkaya123/real_estate-team1"
    }


    stages {
        stage('Create Key Pair for AWS instance') {
            steps {
                echo "Creating Key Pair "
                sh """
                    aws ec2 create-key-pair --region us-east-1 --key-name k3sKey --query KeyMaterial --output text > k3sKey
                    chmod 400 k3sKey
                """
            }
        
        stage('Create AWS Resources') {
            steps {
                dir('terraform') {
                    sh """
                        terraform init
                        terraform apply -auto-approve
                    """
                }
            }
        }

        stage('Prepare Tags for Docker Images') {
            steps {
                echo 'Preparing Tags for Docker Images'
                script {
                    env.IMAGE_TAG_FE = "${APP_REPO_NAME}:f.${BUILD_NUMBER}"
                    env.IMAGE_TAG_BE = "${APP_REPO_NAME}:b.${BUILD_NUMBER}"
                }
            }
        }

        stage('Build App Docker Images') {
            steps {
                echo 'Building App Dev Images'
                sh """
                    pwd
                    docker build --force-rm -t "${IMAGE_TAG_FE}" "${WORKSPACE}/True-Roots-Frontend"
                    docker build --force-rm -t "${IMAGE_TAG_BE}" "${WORKSPACE}/True-Roots-Backend"
                    docker image ls
                """
            }
        }

        stage('Push Images to Docker Hub') {
            steps {
                echo "Pushing App Images to Docker Hub"
                withCredentials([string(credentialsId: 'docker-hub-password', variable: 'DOCKER_PASSWORD')]) {
                    sh """
                        echo "$DOCKER_PASSWORD" | docker login -u esenkaya123 --password-stdin
                        docker push "${IMAGE_TAG_FE}"
                        docker push "${IMAGE_TAG_BE}"
                    """
                }
            }
        }
        
        stage('wait the instance') {
            steps {
                script {
                    echo 'Waiting for the instance'
                    id = sh(script: 'aws ec2 describe-instances --filters Name=tag-value,Values="K3s-Server" Name=instance-state-name,Values=running --query Reservations[*].Instances[*].[InstanceId] --output text',  returnStdout:true).trim()
                    sh 'aws ec2 wait instance-status-ok --instance-ids $id'
                }
            }
        }


        stage('ENV REACT UPDATE') {
            steps {
                echo 'Updating environment variables'
                dir('terraform') {
                    script {
                        env.NODE_IP = sh(script: 'terraform output -raw public_ip', returnStdout: true).trim()
                    }
                }
                echo "Node IP: ${env.NODE_IP}"
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    echo 'Deploying Application to Kubernetes on the new instance'

                    dir('terraform') {
                        env.NODE_IP = sh(script: 'terraform output -raw public_ip', returnStdout: true).trim()
                    }

                    echo "New EC2 Instance IP: ${env.NODE_IP}"

                    sh """
                        cd kub_manifest
                        sed -i 's/127.0.0.1/${NODE_IP}/g' /var/lib/jenkins/kubeconfig.yaml
                        export KUBECONFIG=/var/lib/jenkins/kubeconfig.yaml
                        envsubst < kustomization-template.yaml > kustomization.yaml
                        kubectl apply -k .
                        EOF
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
        }

        success {
            echo 'Pipeline successfully completed.'
            timeout(time: 5, unit: 'DAYS') {
                script {
                    def userInput = input message: 'Pipeline tamamlandı. Terraform’u destroy etmek istiyor musunuz?', 
                        parameters: [booleanParam(defaultValue: false, description: '', name: 'Destroy')]

                    if (userInput) {
                        echo 'Terraform destroy işlemi başlatılıyor...'
                        dir('terraform') { 
                            sh 'terraform destroy -auto-approve'
                        }
                    } else {
                        echo 'Terraform destroy işlemi iptal edildi.'
                    }
                }
            }
        }

        failure {
            echo 'Pipeline failed. Terraform destroy işlemi başlatılıyor...'
            dir('terraform') { 
                sh 'terraform destroy -auto-approve'
            }
        }
    }
}
