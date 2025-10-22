# Required
allowed_ingress_cidrs = [
  "165.1.207.240/32"        #current public IP
]

# ACM (N. Virginia) for sbox.nabancard.io
acm_certificate_arn = "arn:aws:acm:us-east-1:518249229033:certificate/e1f50669-b43a-4929-b122-91f70e458120"

# Strong PostgreSQL password (change if you like)
db_password = "eda12345"

# Optional overrides (already defaulted in code)
region        = "us-east-1"
project_name  = "north-eval-eda"
instance_type = "t3.micro"

