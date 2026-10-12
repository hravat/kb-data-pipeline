# Key that encrypts the landing bucket; rotates automatically each year
resource "aws_kms_key" "landing" {
  description         = "Encrypts files in the landing bucket"
  enable_key_rotation = true
}

# Friendly name for the key in the console
resource "aws_kms_alias" "landing" {
  name          = "alias/${var.landing_bucket}"
  target_key_id = aws_kms_key.landing.key_id
}
