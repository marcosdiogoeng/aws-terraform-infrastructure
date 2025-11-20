locals {
  oidc                 = split("/", var.oidc)[4]
  iam_role_name        = var.iam_role_name != "" ? var.iam_role_name : "${var.cluster_name}-${var.chart_name}-irsa"
  create_custom_policy = var.create_iam_role && (length(var.iam_policy_statements) > 0 || var.iam_policy_json_file != "")
  policy_document = var.iam_policy_json_file != "" ? file(var.iam_policy_json_file) : (
    length(var.iam_policy_statements) > 0 ? jsonencode({
      Version   = "2012-10-17"
      Statement = var.iam_policy_statements
    }) : ""
  )
}