import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    filters = [{'Name': 'tag:Dev_key', 'Values': ['True']}]
    instances = ec2.describe_instances(Filters=filters)
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            ec2.start_instances(InstanceIds=[instance['InstanceId']])
    return 'EC2 instances started successfully'

