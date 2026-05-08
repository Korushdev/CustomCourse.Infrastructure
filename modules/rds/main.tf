resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for Aurora Serverless"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    description = "Allow Access from ANYWHERE"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allowed_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = lower("${var.project_name}-${var.environment}-aurora-cluster")
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned" 
  engine_version          = "17.9"        
  database_name           = var.db_name
  master_username         = var.master_username
  master_password         = var.master_password
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  apply_immediately       = true

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-aurora-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
  publicly_accessible = true
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-aurora-instance"
    Environment = var.environment
    Project     = var.project_name
  }
}

output "rds_cluster_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}
