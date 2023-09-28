resource "aws_s3_bucket" "log_bucket" {
  bucket   = "demo-centralized-logging"
  provider = aws.logging
  tags = {
    environment = "logging"
  }
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  provider = aws.logging
  bucket = "demo-centralized-logging"
  depends_on = [ 
    aws_s3_bucket.log_bucket,
   ]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
          AWS = "arn:aws:iam::231299874646:user/akhil"
        },
        Action = "s3:PutObject",
        Resource = [
          "arn:aws:s3:::demo-centralized-logging",
          "arn:aws:s3:::demo-centralized-logging/*"
        ],
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "231299874646",
            "s3:x-amz-acl"      = "bucket-owner-full-control"
          },
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:us-east-2:231299874646:*"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryCheck",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ],
        Resource = [
            "arn:aws:s3:::demo-centralized-logging",
            "arn:aws:s3:::demo-centralized-logging/*"

        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "231299874646"
          },
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:us-east-2:231299874646:*"
          }
        }   
      },
    ]
  })
}

resource "aws_iam_policy" "flow_logs_policy" {
    name = "flow_logs_policy"
    description = "IAM policy for flow logs"
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Sid = "GrantReadAccess",
                Action = [
                    "ec2:CreateFlowLogs",
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                ],
                Effect = "Allow"
                Resource = "*",
            },
            {
                Action = [
                    "s3:PutObject",
                ],
                Effect = "Allow"
                Resource = [
                    aws_s3_bucket.log_bucket.arn,
                    "${aws_s3_bucket.log_bucket.arn}/*",
                ],
            },
        ],
    })
  
}
resource "aws_iam_role" "flow_logs_role" {
    name = "flow_logs_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "s3.amazonaws.com"
                },
            },
        ],

    })  
}
resource "aws_iam_role_policy_attachment" "flow_logs_policy_attaachment" {
    policy_arn = aws_iam_policy.flow_logs_policy.arn
    role = aws_iam_role.flow_logs_role.name
}
