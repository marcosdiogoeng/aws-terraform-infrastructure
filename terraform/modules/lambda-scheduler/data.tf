data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = local.zip_path
}