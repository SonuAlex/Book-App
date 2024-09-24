from fastapi.responses import JSONResponse
import pymongo
import logging
import requests
from dotenv import load_dotenv
import os

load_dotenv()
MONGODB_API = os.environ.get("MONGODB_API_STRING")

# MongoDB connection
client = pymongo.MongoClient(MONGODB_API)
db = client["bookstore"]
collection = db["cache"]

def caching(title):
    # Caching logic here
    if collection.find_one({"title": title}):
        return True
    else:
        return False

def get_book_data(query, title, OL_API_STRING) -> JSONResponse:
    # Default request
    try:
        response = requests.get(query)
    except Exception as e:
        logging.error(f"Error processing default request: {e}")
        return JSONResponse(status_code=500, content={"message": "Internal Server Error"})

    # Check for errors
    if response.status_code != 200:
        logging.error(f"Error processing request: {response.text}")
        return JSONResponse(status_code=500, content={"message": "Internal Server Error"})
    
    # Check for empty response
    book_data = response.json()
    if len(book_data["docs"]) == 0:
        logging.error(f"Book not found: {title}")
        return JSONResponse(status_code=404, content={"message": "Book not found"})
    
    # Processing response
    book = book_data["docs"][0]

    if not caching(title):
        work_id = book["key"].split("/")[-1]
        image = OL_API_STRING + "/b/olid/" + work_id + "-L.jpg"
        work = OL_API_STRING + "/works/" + work_id + ".json"
        
        # Work request
        try:
            workResponse = requests.get(work)
        except Exception as e:
            logging.error(f"Error processing work request: {e}")
            return JSONResponse(status_code=500, content={"message": "Internal Server Error"})
        
        print(workResponse)

        # Compiling result
        result = {
            "coverImage": image,
            "title": book["title"],
            "author": book["author_name"][0],
            "description": workResponse.json()["description"]
        }
        collection.insert_one(result.copy())
    
    else:
        data = collection.find_one({"title": title})
        result = {
            "coverImage": data["coverImage"],
            "title": data["title"],
            "author": data["author"],
            "description": data["description"]
        }
    
    return result