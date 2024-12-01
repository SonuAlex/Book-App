import os
import csv
import pymongo
from fastapi import Request
from datetime import datetime

try:
    client = pymongo.MongoClient('mongodb://localhost:27017')
    db = client["bookstore"]
    apiMetrics = db["apiMetrics"]
except:
    print("Error: Could not connect to MongoDB")

class Metrics:
    def __init__(self, request: Request):
        self.client_ip = request.client.host
        self.path = request.url.path

        os.makedirs('logs', exist_ok=True)
        self.csv_file_path = f"logs/request_log_{datetime.now().strftime('%d-%m-%Y')}.csv"

    def saveMongoDBMetrics(self):
        apiMetrics.update_one({'client_ip': self.client_ip},{'$inc': {f'paths.{self.path}': 1},'$setOnInsert': {'client_ip': self.client_ip}},upsert=True)
    
    def saveCSVMetrics(self):
        timestamp = datetime.now().isoformat() 
        if not os.path.exists(self.csv_file_path):
            with open(self.csv_file_path, 'w', newline='') as csvfile:
                csv_writer = csv.writer(csvfile)
                csv_writer.writerow(['client_ip', 'path', 'timestamp'])
        
        with open(self.csv_file_path, 'a', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            csv_writer.writerow([self.client_ip, self.path, timestamp])
