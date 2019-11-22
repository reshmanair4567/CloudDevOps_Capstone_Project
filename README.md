This project contains code that creates the following in AWS  

* Standard AWS infra ( VPC , NAT-GW, IGW , etc) 

* Jenkins server on Kubernetes cluster 

* EKS cluster  

Jenkins Rolling Deployment has been implemented 

Linting is added as a step in Jenkins Pipeline 


Pipeline Structure:
Start > Clone repository > kubectl contexts > kubectl nginx deployment > kubectl rollout status > End
