import sys
import logging
from datetime import datetime, timedelta
import requests
import boto3

logger = logging.getLogger()
logger.setLevel("INFO")

def handler(event, context):
    nhl_api_today = "https://api-web.nhle.com/v1/schedule/now"

    nhl_resonse = requests.get(nhl_api_today)
    if nhl_resonse.status_code != 200:
        logger.error(f"Failed to fetch NHL schedule: {nhl_resonse.status_code}")
        return f"Error fetching NHL schedule: {nhl_resonse.status_code}"
    
    raw_data = nhl_resonse.json()

    if len(raw_data["gameWeek"][0]["games"]) == 0:
        logger.info("No games scheduled for today.")
        return "No games scheduled for today."
    

    actual_start_time = raw_data["gameWeek"][0]["games"][0]["startTimeUTC"]

    actual_start_time_minus_5_minutes = datetime.strptime(actual_start_time, "%Y-%m-%dT%H:%M:%SZ") + timedelta(minutes=105)

    scheduled_time = actual_start_time_minus_5_minutes.strftime("%Y-%m-%dT%H:%M:%S")

    logger.info(f"Time Calculated: {scheduled_time} UTC")

    # create scheduler with boto3 to trigger lambda at scheduled_time
    scheduler = boto3.client('scheduler')
    
    try:
        scheduler.create_schedule(
            ActionAfterCompletion='DELETE',
            Name='NHLGameStartTimeTrigger',
            ScheduleExpression=f"at({scheduled_time})",
            ScheduleExpressionTimezone='UTC',
            Target={
                
                'Arn': 'arn:aws:ecs:us-east-1:871806636838:cluster/nhl-excite-o-meter-data-cluster',
                'RoleArn': 'arn:aws:iam::871806636838:role/nhl-excit-o-meter-starttime-checker-role',
                'EcsParameters': {
                    'TaskDefinitionArn': 'arn:aws:ecs:us-east-1:871806636838:task-definition/nhl-excite-o-meter-data-task',
                    'TaskCount': 1,
                    'LaunchType': 'FARGATE',
                    'NetworkConfiguration' :{
                    'awsvpcConfiguration': {
                        'Subnets': [
                            'subnet-036d25c00629af481'
                            'subnet-0cc61dc319782a5dd'
                        ],
                        'SecurityGroups' : [
                            'sg-0dd61ca2df34bf514'
                        ],
                        'AssignPublicIp': 'ENABLED'
                    }
                }
                },
            },
            State='ENABLED',
            FlexibleTimeWindow={
                'Mode': 'OFF'
            }
        )
    except Exception as e:
        logger.error(f"Failed to create schedule: {e}")
        return f"Error creating schedule: {e}"

    logger.info(f"NHL Game Data fetch will start at: {scheduled_time} UTC")
    return 'Successfully fetched NHL schedule and logged first game start time.'