#!/bin/bash
set -e

echo "Building Lambda packages..."

# Build post_confirmation lambda
echo "Building post_confirmation lambda..."
mkdir -p tmp_post_confirmation
cp ../lambdas/post_confirmation.py tmp_post_confirmation/
cd tmp_post_confirmation
pip install psycopg2-binary==2.9.9 -t .
zip -r ../post_confirmation.zip .
cd ..
rm -rf tmp_post_confirmation

# Build messaging_stream lambda
echo "Building messaging_stream lambda..."
mkdir -p tmp_messaging_stream
cp ../lambdas/messaging_stream.py tmp_messaging_stream/
cd tmp_messaging_stream
pip install boto3==1.34.101 -t .
zip -r ../messaging_stream.zip .
cd ..
rm -rf tmp_messaging_stream

echo "Lambda packages built successfully!"
echo "  - post_confirmation.zip"
echo "  - messaging_stream.zip"