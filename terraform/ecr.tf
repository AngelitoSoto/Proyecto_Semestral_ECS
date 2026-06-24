resource "aws_ecr_repository" "frontend" {
  name                 = "semestral-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "semestral-frontend-repo"
  }
}

resource "aws_ecr_repository" "ventas" {
  name                 = "semestral-ventas"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "semestral-ventas-repo"
  }
}

resource "aws_ecr_repository" "despachos" {
  name                 = "semestral-despachos"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "semestral-despachos-repo"
  }
}
