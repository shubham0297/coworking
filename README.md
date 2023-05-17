# Coworking Space Service Extension
The Coworking Space Service is a set of APIs that enables users to request one-time tokens and administrators to authorize access to a coworking space. This service follows a microservice pattern and the APIs are split into distinct services that can be deployed and managed independently of one another.

For this project, you are a DevOps engineer who will be collaborating with a team that is building an API for business analysts. The API provides business analysts basic analytics data on user activity in the service. The application they provide you functions as expected locally and you are expected to help build a pipeline to deploy it in Kubernetes.

## Getting Started

### Dependencies
#### Local Environment
1. Python Environment - run Python 3.6+ applications and install Python dependencies via `pip`
2. Docker CLI - build and run Docker images locally
3. `kubectl` - run commands against a Kubernetes cluster
4. `helm` - apply Helm Charts to a Kubernetes cluster

#### Remote Resources
1. AWS CodeBuild - build Docker images remotely
2. AWS ECR - host Docker images
3. Kubernetes Environment with AWS EKS - run applications in k8s
4. AWS CloudWatch - monitor activity and logs in EKS
5. GitHub - pull and clone code

### Setup
#### 1. Configure a Database
Set up a Postgres database using a Helm Chart.

1. Install [AWS-EBS CSI Driver Add-On](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html) for your Cluster (if cluster version is 1.23 or above) 
2. Set up Bitnami Repo
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

3. Install PostgreSQL Helm Chart
```
helm install postgres bitnami/postgresql
```

This should set up a Postgre deployment at `postgres-postgresql.default.svc.cluster.local` in the Kubernetes cluster. 
By default, it will create a username `postgres`. The password can be retrieved with the following command:
```bash
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default <SERVICE_NAME>-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

echo $POSTGRES_PASSWORD
```


3. Test Database Connection
The database is accessible within the cluster. This means that when you will have some issues connecting to it via your local environment. You can either connect to a pod that has access to the cluster _or_ connect remotely via [`Port Forwarding`](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

* Connecting Via Port Forwarding
```bash
kubectl port-forward --namespace default svc/<SERVICE_NAME>-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
```

* Connecting Via a Pod
```bash
kubectl exec -it <POD_NAME> bash
PGPASSWORD="<PASSWORD HERE>" psql postgres://postgres@<SERVICE_NAME>:5432/postgres -c <COMMAND_HERE>
```

4. Run Seed Files
We will need to run the seed files in `db/` in order to create the tables and populate them with data.

```bash
kubectl port-forward --namespace default svc/<SERVICE_NAME>-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < <FILE_NAME.sql>
```

### 2. Building Image for analytics application
* Wrote a Dockerfile to convert the analytics app.py code to a Docker image.
* Created an ECR repository.
* Created a CodeBuild project and a buildspec file, that would build and push the image from the latest commit to ECR.


### 3. Kubernetes Deployments
1. Create a configMap to store Database plaintext variables
```
kubectl apply -f db_configMap.yml
```

2. Create a configMap to store Database secret variables (like username and password)
```
kubectl apply -f db_secrets.yml
```

3. Create the deployment i.e. the analytics application. It runs 2 pods for analytics application.
```
kubectl apply -f deployment.yml
```

4. Create service for the deployment. Anyone inside the cluster can reach the application using the service's Cluster IP
```
kubectl apply -f service.yml
```

5. Verifying The Application
* Generate report for check-ins grouped by dates
`curl <SERVICE_IP>:5153/api/reports/daily_usage`
OR
`kubectl exec -it <pod_name> -- curl localhost:5153/api/reports/daily_usage`

* Generate report for check-ins grouped by users
`curl <SERVICE_IP>:5153/api/reports/user_visits`
OR
`kubectl exec -it <pod_name> -- curl localhost:5153/api/reports/user_visits`

### 4. CloudWatch Logging
1. Create a CloudWatch log Group for storing the application logs
2. Configure Fluent bit to export the logs to the CloudWatch Log Group
* Create secret for AWS credentials ➡️ `kubectl apply -f fluent-bit-aws-secrets.yml`
* Configure the fluent-bit ➡️ ` kubectl apply -f fluent-bit-manifest.yml` 
