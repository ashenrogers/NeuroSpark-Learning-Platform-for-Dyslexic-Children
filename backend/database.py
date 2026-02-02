import os
from pymongo import MongoClient
from dotenv import load_dotenv

# Load .env file
load_dotenv()

def get_db():
    # Get MongoDB URI from .env
    mongo_uri = os.getenv("MONGO_URI")
    client = MongoClient(mongo_uri)
    
    # Connect to the specific database
    db = client["AdaptiveMemoryTrainerDB"]
    return db
