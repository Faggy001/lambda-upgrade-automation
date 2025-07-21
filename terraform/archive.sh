#!/bin/bash
cd lambda
pip install -r requirements.txt -t .
zip -r ../terraform/lambda.zip .
cd ..
echo "Lambda function zipped as terraform/lambda.zip"
