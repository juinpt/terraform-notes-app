resource "aws_db_instance" "postgres" {
  identifier              = "notes-db"
  engine                  = "postgres"
  engine_version          = "15.13"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_name                 = "notesdb"
  username                = var.postgres_user
  password                = var.postgres_password
  multi_az                = false # for saving costs, turn on for hot-standby redudancy
  backup_retention_period = 7
  backup_window           = "15:00-16:00" # 00:00-01:00 JST
  vpc_security_group_ids  = [var.security_group_id]
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
  skip_final_snapshot     = true # So a final snapshot is taken on destroy
  publicly_accessible     = true # For testing purposes

  tags = {
    Name = "notes-postgres"
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = "notes-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "notes-db-subnet-group"
  }
}
