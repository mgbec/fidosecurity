# ============================================================================
# S3 Buckets — Agent Source Code Storage
# ============================================================================

resource "aws_s3_bucket" "orchestrator_source" {
  bucket_prefix = "sa-orch-src-"
  force_destroy = true
  tags          = { Name = "${var.stack_name}-orchestrator-source", Agent = "Orchestrator" }
}

resource "aws_s3_bucket" "research_analyst_source" {
  bucket_prefix = "sa-research-src-"
  force_destroy = true
  tags          = { Name = "${var.stack_name}-research-analyst-source", Agent = "ResearchAnalyst" }
}

resource "aws_s3_bucket" "portfolio_advisor_source" {
  bucket_prefix = "sa-portfolio-src-"
  force_destroy = true
  tags          = { Name = "${var.stack_name}-portfolio-advisor-source", Agent = "PortfolioAdvisor" }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "orchestrator_source" {
  bucket                  = aws_s3_bucket.orchestrator_source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "research_analyst_source" {
  bucket                  = aws_s3_bucket.research_analyst_source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "portfolio_advisor_source" {
  bucket                  = aws_s3_bucket.portfolio_advisor_source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "orchestrator_source" {
  bucket = aws_s3_bucket.orchestrator_source.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "research_analyst_source" {
  bucket = aws_s3_bucket.research_analyst_source.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "portfolio_advisor_source" {
  bucket = aws_s3_bucket.portfolio_advisor_source.id
  versioning_configuration { status = "Enabled" }
}

# ============================================================================
# Archive & Upload Agent Source Code
# ============================================================================

data "archive_file" "orchestrator_source" {
  type        = "zip"
  source_dir  = "${path.module}/agents/orchestrator"
  output_path = "${path.module}/.terraform/orchestrator-code.zip"
}

data "archive_file" "research_analyst_source" {
  type        = "zip"
  source_dir  = "${path.module}/agents/research-analyst"
  output_path = "${path.module}/.terraform/research-analyst-code.zip"
}

data "archive_file" "portfolio_advisor_source" {
  type        = "zip"
  source_dir  = "${path.module}/agents/portfolio-advisor"
  output_path = "${path.module}/.terraform/portfolio-advisor-code.zip"
}

resource "aws_s3_object" "orchestrator_source" {
  bucket = aws_s3_bucket.orchestrator_source.id
  key    = "orchestrator-${data.archive_file.orchestrator_source.output_md5}.zip"
  source = data.archive_file.orchestrator_source.output_path
  etag   = data.archive_file.orchestrator_source.output_md5
}

resource "aws_s3_object" "research_analyst_source" {
  bucket = aws_s3_bucket.research_analyst_source.id
  key    = "research-analyst-${data.archive_file.research_analyst_source.output_md5}.zip"
  source = data.archive_file.research_analyst_source.output_path
  etag   = data.archive_file.research_analyst_source.output_md5
}

resource "aws_s3_object" "portfolio_advisor_source" {
  bucket = aws_s3_bucket.portfolio_advisor_source.id
  key    = "portfolio-advisor-${data.archive_file.portfolio_advisor_source.output_md5}.zip"
  source = data.archive_file.portfolio_advisor_source.output_path
  etag   = data.archive_file.portfolio_advisor_source.output_md5
}
