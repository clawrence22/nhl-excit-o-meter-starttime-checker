import sys
import logging
import requests

logger = logging.getLogger()
logger.setLevel("INFO")

def handler(event, context):
    nhl_api_today = "https://api-web.nhle.com/v1/schedule/now"

    nhl_resonse = requests.get(nhl_api_today)
    if nhl_resonse.status_code != 200:
        logger.error(f"Failed to fetch NHL schedule: {nhl_resonse.status_code}")
        return f"Error fetching NHL schedule: {nhl_resonse.status_code}"
    
    raw_data = nhl_resonse.json()

    if not raw_data.get("dates"):
        logger.info("No games scheduled for today.")
        return "No games scheduled for today."
    

    first_state_timestamp_utc = raw_data["dates"][0]["games"][0]["startTimeUTC"]

    logger.info(f"NHL Game Data fetch will start at: {first_state_timestamp_utc}")
    return 'Successfully fetched NHL schedule and logged first game start time.'