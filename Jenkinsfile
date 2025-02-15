pipeline {
    agent any

    environment {
        APP_REPO_NAME = "esenkaya123/real_estate-team1"
    }

    stages {
        stage('Create AWS Resources') {
            steps {
                sh """
                    cd terraform
                    terraform init
                    terraform apply -auto-approve
                """
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
                sh """
                    docker login -u esenkaya123 -p Canahmet63
                    docker push "${IMAGE_TAG_FE}"
                    docker push "${IMAGE_TAG_BE}"
                """
            }
        }

        stage('Wait for the Instance') {
            steps {
                script {
                    echo 'Waiting for the instance'

                    // Terraform çıktısından instance ID'yi al ve ortam değişkeni olarak ata
                    dir('terraform') {
                        env.INSTANCE_ID = sh(script: "terraform output -raw instance_id", returnStdout: true).trim()
                    }

                    echo "Instance ID: ${env.INSTANCE_ID}"

                    // AWS CLI ile instance'ın status-ok olmasını bekle
                    sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID}"
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

                    // Terraform’dan oluşturulan makinenin IP’sini al
                    dir('terraform') {
                        env.NODE_IP = sh(script: 'terraform output -raw public_ip', returnStdout: true).trim()
                    }

                    echo "New EC2 Instance IP: ${env.NODE_IP}"

                    // SSH ile yeni makineye bağlan ve kubectl apply komutlarını çalıştır
                    sh """
                        ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/.ssh/aws-key.pem ubuntu@${NODE_IP} <<EOF
                        export KUBECONFIG=/var/lib/jenkins/kubeconfig.yaml
                        cd /home/ubuntu/kub_manifest
                        envsubst < kustomization-template.yaml > kustomization.yml
                        kubectl apply -k .
                        EOF
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up local Docker images'
            sh 'docker image prune -af'
        }

        success {
            echo 'Pipeline successfully completed.'
            timeout(time: 5, unit: 'DAYS') {
                input message: 'Pipeline tamamlandı. Sonlandırmak istiyor musunuz?'
            }
            echo 'Pipeline sonlandırıldı.'
        }

        failure {
            echo 'Pipeline failed.'
            timeout(time: 5, unit: 'DAYS') {
                input message: 'Pipeline başarısız oldu. Sonlandırmak istiyor musunuz?'
            }
            echo 'Pipeline sonlandırıldı.'
        }
    }
}