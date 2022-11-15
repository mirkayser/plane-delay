# plane-delay

## 1. API Rest

The serialized model is served with a simple Api using flask &flask-restful.

Run in development environment using virtualenv:
```
python3 -m venv .venv
source .venv/bin/activate
cd api/
pip install -r requirements.txt
DEBUG=True PORT=5000 python app.py
```

Or run in docker container:
```
# build image
docker build -t plane-delay:latest -f Dockerfile ./api/

# run image in container
docker container run -it -p 5000:80 --env DEBUG=True plane-delay:latest
```

Test api using curl:
```
curl -H 'Content-Type: application/json' -X GET "http://localhost:5000/" -d' 
{
  "x": [1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0]
}
'
```


## 2. Deploy to cloud

### Create infrastructure

Requirements: aws-cli, terraform-cli

Infrastructure is created on AWS using Terraform. All required resources are described in `main.tf`.
Required resources include ECR repository, ECS cluster with task to run image in container and other necesary resources.

Ultimately the application will run in a container on ECS.

Create infrastructure:
```
terraform init
terraform apply
```


### Build & deploy image

Requirements: docker
(docker needs permission to access AWS: https://aws.amazon.com/blogs/compute/authenticating-amazon-ecr-repositories-for-docker-cli-with-credential-helper/)

Api is built as docker image and pushed to ECR repository. The the ECS service is restarted to pull updated image.
All required steps are defined in Makefile.

IMPORTANT: Makefile pulls som variables like ecr-repository-name, cluster-name and service-name from terraform.
Therefore `terraform apply` must be run before `make`.

Build & deploy:
```
make deploy
```

Get IP of ECS task from AWS console or run `make public_ip`.


### Improvements

Since ECS assigns a new IP any time the task is updated, this setup is not feasible for production.
This can be solved by adding a load balancer to reroute incoming requests to the container,
also the cluster could be scaled up to run several tasks in parallel.


## 3. Stress test

Stress tests were performed using wrk (https://github.com/wg/wrk).

On a machine with 8 cores the optimal config to run stress tests with wrk was found to be 8 threads with 400 connections.
With the current setup only ~7k requests were sent in 45 s.
Benchmark current:
```
Running 45s test @ http://18.116.26.86:80/predict
  8 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     1.17s   273.90ms   2.00s    79.29%
    Req/Sec    20.87     12.96   101.00     80.40%
  6817 requests in 45.08s, 1.59MB read
  Socket errors: connect 0, read 42, write 0, timeout 1486
Requests/sec:    151.20
Transfer/sec:     36.19KB
```

### Improvements

Increasing the CPU of the container in ECS to 1024,
latency was reduced significantly and ~28k requests were sent in the same timeframe.
Benchmark high-cpu:
```
Running 45s test @ http://3.138.125.122:80/predict
  8 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   366.47ms   94.05ms   1.97s    91.86%
    Req/Sec    82.81     43.22   343.00     71.22%
  28304 requests in 45.08s, 6.61MB read
  Socket errors: connect 0, read 0, write 0, timeout 49
Requests/sec:    627.84
Transfer/sec:    150.23KB
```

Further increasing CPU had no considerable effect.
To optimize performance tasks should be scaled horizontally and traffic managed by a load balancer.
To minimize idle resources an autoscaler should adjust cluster size considering current traffic.


## 4. Create infrastructure using Terraform

see 2.


## 5. Authentication

Authentication can be accomplished by requiring that a token or key/secret pair is sent with every request
 in the body or header.
Token or key-pair are then validated against register of authorized users usually stored in database.

Authentication method will increase latency as a query has to be run on database to validate token/key-pair.

Access could be managed by the security group allowing only traffic from within VPC.
This method will not (noticably) affect latency but has the disadvantage that permissions must be set for IPs,
unless all consumers reside in the same VPC.


## 6. SLO & SLI

SLO should be defined by the business requirements.
In order to minimize operational costs SLO should be defined as the lowest level of reliability acceptable for consumers.

The SLIs for the 2 different setups tested are 78.2 % and 99.8 % for the current and the high-cpu setup respectively.
If SLO is defined as 99 %, the current setup is unacceptable as it is below specified SLO.
