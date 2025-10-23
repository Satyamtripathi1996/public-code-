region                = "us-east-1"
project_name          = "north-eval-eda"
allowed_ingress_cidrs = ["165.1.207.240/32"]  
acm_certificate_arn   = "arn:aws:acm:us-east-1:518249229033:certificate/e1f50669-b43a-4929-b122-91f70e458120"
instance_type         = "t3.micro"

db_name               = "appdb"
db_username           = "dbadmin"
db_password           = "Eda.top@eval12345"        # printable ASCII only

key_name              = "eda.terraform.key"
