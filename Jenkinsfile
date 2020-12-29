@Library('jenkins-joylib@v1.0.1') _

pipeline {

    agent {
        label 'nested-virt:qemu-kvm'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timestamps()
    }

    stages {
        stage('centos-7') {
            steps {
                sh('./create-image -r 7')
                sh('./create-image -r 7 upload')
            }
        }
        stage('centos-8') {
            steps {
                sh('./create-image -r 8')
                sh('./create-image -r 8 upload')
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '*.artifacts-in-manta'
            joyMattermostNotification()
        }
    }
}
