*** This is Udacity Capstone Project***


cloud formation:

create the stack for vpc ->vpc.yaml
create the stack for eks ->eks.yaml
create the stack for ecr ->ecr.yaml


Kubectl & aws Cli, helm config:

kubectl should be installed in the local machine
awscli should be installed in the local machine
create the user in IAM. for example - i created user called 'reshma' in IAM and attached admin policy to the user to get all aws resources access from command line
Place the secret key and access key from AWS in the bash_profile or cd ~/.aws/config.

for example - my bash profile settings for AWS
aws_reshma() {
    unset AWS_SESSION_TOKEN
    unset AWS_SECURITY_TOKEN
    export AWS_ACCESS_KEY_ID=''
    export AWS_SECRET_ACCESS_KEY=''
    echo "aws profile switched to resh account"
}

Load the function aws_reshma() before you create any resources or it would fail for authentication

for this exercise, I am using us-west-2 region in AWS

aws eks --region us-west-2 update-kubeconfig --name <clustername from eks that you gave from cloudformation stack - eks-eks-cluster >
you config will be added the kube config locally, so that you will have complete control to eks cluster from your local machine
kube config will be present in cd ~/.kube/config
* kubectl config get-contexts
* kubeclt config use-context <context-name>

Now we can deploy the applications to eks cluster from the local machine from client kubectl


Then Look for the eks worker nodes are attached to the cluster or not -> kubectl get nodes - you wont see any resources

Then looks for the pods - kubectl get pods --all-namespaces
NAMESPACE     NAME                       READY     STATUS    RESTARTS   AGE
kube-system   coredns-855d869666-82blh   0/1       Pending   0          9m38s
kube-system   coredns-855d869666-bxgdc   0/1       Pending   0          9m38s

it will say status is pending - if you look at the logs of these pods -> kubectl logs -f coredns-855d869666-82blh -n=kube-system ->it will say `no nodes were part of the cluster`



eks worker nodes won't attached to the cluster until give authorization to the cluster form the config map (aws-auth-cm.yaml)- this config map contains eks service policy and system node policy

I created a role "arn:aws:iam::305115181912:role/eks-EKS-Worker-Node-Role" manually not from cloudformation. here is the ARN for the role
arn:aws:iam::305115181912:role/eks-EKS-Worker-Node-Role

Now run this configmap from local machine -> kubectl apply -f aws-auth-cm.yaml

╰─ kubectl apply -f aws-auth-cm.yaml                                                                                                                     configmap/aws-auth created

Kubectl get pods:

NAMESPACE     NAME                       READY     STATUS              RESTARTS   AGE
kube-system   aws-node-2vgbc             0/1       ContainerCreating   0          3s
kube-system   aws-node-j9rkw             0/1       ContainerCreating   0          4s
kube-system   coredns-855d869666-82blh   0/1       Pending             0          10m
kube-system   coredns-855d869666-bxgdc   0/1       Pending             0          10m
kube-system   kube-proxy-g8plk           0/1       ContainerCreating   0          4s
kube-system   kube-proxy-z6t9z           0/1       ContainerCreating   0          3s

kubectl get nodes

NAME                                          STATUS     ROLES     AGE       VERSION
ip-10-192-20-253.us-west-2.compute.internal   NotReady   <none>    13s       v1.12.7
ip-10-192-21-182.us-west-2.compute.internal   NotReady   <none>    14s       v1.12.7

give 1 or 2mins: these pods will be in running state

NAMESPACE     NAME                       READY     STATUS    RESTARTS   AGE
kube-system   aws-node-2vgbc             1/1       Running   0          56s
kube-system   aws-node-j9rkw             1/1       Running   0          57s
kube-system   coredns-855d869666-82blh   1/1       Running   0          11m
kube-system   coredns-855d869666-bxgdc   1/1       Running   0          11m
kube-system   kube-proxy-g8plk           1/1       Running   0          57s
kube-system   kube-proxy-z6t9z           1/1       Running   0          56s

Now you can see the nodes are attached to the cluster - by having dns, aws-node, kube-proxy pods

kubectl get nodes

NAME                                          STATUS     ROLES     AGE       VERSION
ip-10-192-20-253.us-west-2.compute.internal   Ready      <none>    11s       v1.12.7
ip-10-192-21-182.us-west-2.compute.internal   Ready      <none>    12s       v1.12.7


HELM: 
helm should be installed locally

Now we are going to use helm charts to deploy the jenkins application 


kubectl create serviceccount tiller -n=kube-system
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller

$HELM_HOME has been configured at /Users/kalaia/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation

kubectl get pods: now you can see tiller pod created on the server side: tiller communicates to kube API server from helm

NAMESPACE     NAME                             READY     STATUS    RESTARTS   AGE
kube-system   aws-node-2vgbc                   1/1       Running   0          10h
kube-system   aws-node-j9rkw                   1/1       Running   0          10h
kube-system   coredns-855d869666-82blh         1/1       Running   0          11h
kube-system   coredns-855d869666-bxgdc         1/1       Running   0          11h
kube-system   kube-proxy-g8plk                 1/1       Running   0          10h
kube-system   kube-proxy-z6t9z                 1/1       Running   0          10h
kube-system   tiller-deploy-779784fbd6-7k25d   1/1       Running   0          19s

Now its time to install jenkins using helm

* helm search jenkins to get the recent chart version of jenkins

* We are not going to use the default values
helm inspect values stable/jenkins >/tmp/jenkins/values

* Now default installation installs as ingress i guess - here i am installing jenkins in node port of the eks cluster


helm install stable/jenkins --values jenkins.values --name  myjnekins                                                                                                                                    ─╯
NAME:   myjnekins
LAST DEPLOYED: Sat Nov  9 09:23:50 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                     DATA  AGE
myjnekins-jenkins        5     1s
myjnekins-jenkins-tests  1     1s

==> v1/Deployment
NAME               READY  UP-TO-DATE  AVAILABLE  AGE
myjnekins-jenkins  0/1    1           0          1s

==> v1/PersistentVolumeClaim
NAME               STATUS   VOLUME  CAPACITY  ACCESS MODES  STORAGECLASS  AGE
myjnekins-jenkins  Pending  gp2     1s

==> v1/Pod(related)
NAME                                READY  STATUS   RESTARTS  AGE
myjnekins-jenkins-568465cfc9-mjzsk  0/1    Pending  0         1s

==> v1/Role
NAME                               AGE
myjnekins-jenkins-schedule-agents  1s

==> v1/RoleBinding
NAME                               AGE
myjnekins-jenkins-schedule-agents  1s

==> v1/Secret
NAME               TYPE    DATA  AGE
myjnekins-jenkins  Opaque  2     1s

==> v1/Service
NAME                     TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)         AGE
myjnekins-jenkins        NodePort   172.20.60.40   <none>       8080:31111/TCP  1s
myjnekins-jenkins-agent  ClusterIP  172.20.217.98  <none>       50000/TCP       1s

==> v1/ServiceAccount
NAME               SECRETS  AGE
myjnekins-jenkins  1        1s


NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace default myjnekins-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services myjnekins-jenkins)
  export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT/login

3. Login with the password from step 1 and the username: admin


For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine


Docker file:

build docker file: docker build -t resh-image .
Authenticate to docker registry: aws ecr get-login --no-include-email --region us-west-2
tag -> docker tag resh-image:latest 305115181912.dkr.ecr.us-west-2.amazonaws.com/test-repository:latest
push to registry : docker push 305115181912.dkr.ecr.us-west-2.amazonaws.com/test-repository:latest


Docker deployment:
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-svc.yaml
