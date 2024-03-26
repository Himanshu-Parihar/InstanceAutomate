import boto3
import os

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    tag_key = os.environ['tag_key']
    tag_value = os.environ['tag_value']

    # Describe EC2 instances with the specified tag
    response = ec2.describe_instances(Filters=[
        {'Name': f'tag:{tag_key}', 'Values': [tag_value]}
    ])

    instance_ids = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])

    # Start EC2 instances
    ec2.start_instances(InstanceIds=instance_ids)
    print(f'Started instances: {instance_ids}')
