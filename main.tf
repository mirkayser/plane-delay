# create ecr repo
resource "aws_ecr_repository" "plane_delay" {
  name = "plane-delay"
}

# create ecs cluster & task definition
resource "aws_ecs_cluster" "plane_delay_cluster" {
  name = "plane-delay-cluster"

  setting {
    name = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_task_definition" "plane_delay_task" {
  family = "plane-delay-task"
  container_definitions = <<DEFINITION
  [
    {
      "name": "plane-delay-task",
      "image": "${aws_ecr_repository.plane_delay.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/plane-delay-task",
          "awslogs-region": "us-east-2",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  memory = 512
  cpu = 256
  execution_role_arn = "${aws_iam_role.execution_role.arn}"
}

# create task policy
data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    sid = "EcsTaskPolicy"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = [
      "*" # you could limit this to only the ECR repo you want
    ]
  }
  statement {

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = [
      "*"
    ]
  }

  statement {

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }

}

# create iam role
resource "aws_iam_role" "execution_role" {
  name = "ecsExecution-1"
  assume_role_policy = data.aws_iam_policy_document.role_policy.json

  inline_policy {
    name   = "EcsTaskExecutionPolicy"
    policy = data.aws_iam_policy_document.ecs_task_policy.json
  }
}

# create iam policy
data "aws_iam_policy_document" "role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# create security group (open port to public)
resource "aws_security_group" "ecs_task_sg" {
  name = "lb-sg"
  description = "controls access to the Application Load Balancer (ALB)"

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create service
resource "aws_ecs_service" "plane_delay_service" {
  name = "plane-delay-service"
  cluster = "${aws_ecs_cluster.plane_delay_cluster.id}"
  task_definition = "${aws_ecs_task_definition.plane_delay_task.arn}"
  launch_type = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets = [
      "${aws_default_subnet.default_subnet_a.id}",
      "${aws_default_subnet.default_subnet_b.id}",
      "${aws_default_subnet.default_subnet_c.id}"
  ]
  assign_public_ip = true
  security_groups = [aws_security_group.ecs_task_sg.id]
  }
}

# create vpc & subnets
resource "aws_default_vpc" "default_vpc" {}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-2a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-2b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "us-east-2c"
}
