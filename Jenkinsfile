pipeline {
    agent any

    stages {
        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                ]) {
                    dir('terraform') {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                            terraform init
                        '''
                    }
                }
            }
        }

        stage('Terraform Plan & Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                ]) {
                    dir('terraform') {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                            terraform plan -out=tfplan
                            yes | terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Get Terraform Outputs') {
            steps {
                dir('terraform') {
                    script {
                        def output = sh(script: 'terraform output -json instance_private_ips', returnStdout: true).trim()
                        writeFile file: '../wordpress_ansible/hosts.json', text: output
                    }
                }
            }
        }
	stage('Run Ansible Playbook') {
            steps {
                dir('wordpress_ansible') {
                    withCredentials([
                        sshUserPrivateKey(
                            credentialsId: 'ansible-key',
                            keyFileVariable: 'SSH_KEY_FILE',
                            usernameVariable: 'SSH_USER'
                        )
                    ]) {
                        script {
                            def ips = readJSON file: 'hosts.json'
                            def inventory = "[ec2]\n"
                            for (ip in ips) {
                                inventory += "${ip} ansible_user=${env.SSH_USER} ansible_ssh_private_key_file=${env.SSH_KEY_FILE}\n"
                            }
                            writeFile file: 'inventory.ini', text: inventory
                        }

                        sh '''
                            export ANSIBLE_HOST_KEY_CHECKING=False
                            export LD_LIBRARY_PATH=/usr/lib64
                            ansible-playbook -i inventory.ini mywebsite.yaml
                        '''
                    }
                }
            }
        }

    }
}

