# PostgreSQL
# Run server
Docker run --name TOCDB -e POSTGRES_PASSWORD=strongpassword -d postgres
# Connect to server
docker run --rm -it --name postgresql-client andreswebs/postgresql-client postgresql://postgres:strongpassword@192.168.1.106:5432

# MySQL
# Run server
docker run --name mySQL -e MYSQL_ROOT_PASSWORD=strongpassword -p 3306:3306 -d mysql
# Connect to server
docker run -it --rm mysql mysql -h192.168.1.106 -P 3306 -uroot -pstrongpassword

# MongoDB
# Run server
docker run --name TOCmongo -p 27017:27017 -d mongo
# Connect to server
docker run -it --rm mongo mongosh --host 192.168.1.106 --port 27017

# Redis
# Run server
docker run --name TOCredis -d -p 6379:6379 redis
# Connect to server
docker run -it --rm redis redis-cli -h 192.168.1.106

# Create Dockerfile to run to run simple nginx website based to custom index.html and nginx:alpin  image
# Create a working dir and the custom index and dockerfile

mkdir website && cd website


cat <<EOT > index.html
<!DOCTYPE html>
<html>
<head>
    <title>DevOps Journey</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f0f0f0;
            text-align: center;
            padding: 100px;
        }

        h1 {
            color: #333;
        }

        p {
            font-size: 18px;
            color: #666;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>I am still new in DevOps skills,</h1>
    <p>but I will get there.</p>
    
    <script>
        // JavaScript code can go here if needed
        // For example, you can log a message to the console
        console.log("Keep learning and you'll succeed in DevOps!");
    </script>
</body>
</html>
EOT

# Creating the Dockerfile
cat <<EOT > Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EOT

# Building the image
docker build -t nginx-simple-website .
# Run the container
docker run --name mywebsite -d -p 8080:80 nginx-simple-website

# Upload the image to dockerhub
docker login

# tag the imagege
docker tag nginx-simple-website jymitar/my-website
# push the image
docker push jymitar/my-website

# Run alpine image in background and attach to it and run ls command
docker run --name alpine -itd alpine
docker exec alpine ls

### Task 1.1.7 Docker Environment Variables
mkdir website2 && cd website2

cat <<"EOT" > Dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

# Set NGINX_PORT enviroment variable to default 8080
ENV NGINX_PORT=8080

# Expose the NGINX_PORT port
EXPOSE "$NGINX_PORT"

# Start the Nginx server
CMD ["nginx", "-g", "daemon off;"]
EOT

# Build the custom image
docker build -t custom-nginx .

# Run the container with 8081 port
docker run --name custom-site -d -p 8081:8081 -e NGINX_PORT=8081 custom-nginx


# Task 1.1.8 Docker Volumes
mkdir toc-data
echo "Hello, World!" > ~/toc-data/index.html
docker run -d --name custom-site -v ~/toc-data:/usr/share/nginx/html nginx

docker volumes cannot be manged from the host. if we want to insert something into the volume we need to use a temporary container and mount the volume
docker run -it --rm -v toc-data:/insert -w /insert busybox sh

docker exec -it custom-site sh

# Task 1.1.9 Docker Networks
docker network create toc_network
docker run -itd --network toc_network --name alpine1 alpine
docker run -itd --network toc_network --name alpine2 alpine

docker exec -it alpine1 apk add iputils
docker exec -it alpine2 apk add iputils

docker exec -it alpine1 ping alpine2
docker exec -it alpine2 ping alpine1

#Task 1.1.10 Docker Commit

docker run -itd --name alpine-base alpine
docker exec -it alpine-base apk upgrade && apk add curl

docker commit alpine-base alpine-curl
docker run -itd --name curl alpine-curl
docker exec -it curl curl --version


# Task 1.2.1 Docker Compose Up/Down/Start/Stop

mkdir dockercompose && cd dockercompose

cat <<EOT > compose.yml
> version: '3'
services:
  webserver:
    image: nginx:alpine
    ports:
      - "80:80"
EOT

docker compose up -d
docker compose down -v

docker compose exec webserver ls

docker compose up --scale webserver=3 -d
docker compose down -v

docker compose top

# Task 1.3 Kubernetes

kubectl run my-pod --image=nginx:1.14.2 --restart=Never

# or 

cat <<EOT > my-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
    - name: nginx-container
      image: nginx:1.14.2
EOT

kubectl apply -f my-pod.yaml
# create deployment 
kubectl create deployment my-deployment --image=nginx:1.14.2 --replicas=3

cat <<EOT > my-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx-container
          image: nginx:1.14.2
EOT

kubectl apply -f my-deployment.yaml

# statefulset

cat <<EOT > my-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: my-statefulset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  serviceName: nginx-service
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx-container
          image: nginx:1.14.2
EOT

kubectl apply -f my-statefulset.yaml

# create secret

kubectl create secret generic my-secret --from-literal=username=admin --from-literal=password=secret
kubectl get secrets
kubectl describe secrets my-secret

# configmap

kubectl create configmap my-configmap --from-literal=log_level=info --from-literal=max_connections=100
kubectl get configmaps
kubectl describe configmap my-configmap

# create a service

cat <<EOT > my-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: nginx  # Match the labels of your deployment pods
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOT

kubectl apply -f my-service.yaml 

# or

kubectl expose deployment my-deployment --name=my-service --port=80 --target-port=80 --type=ClusterIP

# create ingress

cat <<EOT > my-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
EOT

kubectl apply -f my-ingress.yaml

 # install ingress controller 

 kubectl create namespace kube-system
 kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

 # rolling restart

 kubectl rollout restart deployment/my-deployment

 # upgrade

 kubectl set image deployment/my-deployment nginx-container=nginx:1.16.1

 # create a PV

cat <<EOT > my-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce # this allow the volume to be mounted by a sincle pvc at a time
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: ~/my-pv
EOT

cat <<EOT > my-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: manual
EOT

kubectl apply -f my-pv.yaml
kubectl apply -f my-pvc.yaml

kubectl describe deployment my-deployment

# creating HPA for my-deployment

cat <<EOT > my-deployment-hpa.yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: my-deployment-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-deployment
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 50
EOT

# Network policy

cat <<EOT > networkpolicy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-traffic-to-my-deployment
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
    - Ingress
  ingress:
    - from:
      - podSelector: {}
EOT

# create a job

cat <<EOT > job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hello-k8s-job
spec:
  template:
    spec:
      containers:
      - name: busybox-container
        image: busybox
        command: ["echo", "Hello, Kubernetes!"]
      restartPolicy: Never
  backoffLimit: 4 # Number of retries in case of failure
EOT

kubectl get jobs
kubectl logs job/my-job
