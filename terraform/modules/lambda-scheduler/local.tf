locals {
  function_name = var.name
  zip_path      = "${path.module}/.build/${var.name}.zip"
}