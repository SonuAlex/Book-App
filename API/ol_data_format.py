from fastapi.responses import JSONResponse
import pymongo
import logging
import requests
from dotenv import load_dotenv
import os

load_dotenv()
MONGODB_API = os.environ.get("MONGODB_API_STRING")
local_host = "mongodb://localhost:27017"

# MongoDB connection
client = pymongo.MongoClient(local_host)
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
        cover_i = None
        work_id = None
        # Iterate through the list of dictionaries in "docs"
        for doc in book_data.get("docs", []):
            if "cover_i" in doc:
                cover_i = doc["cover_i"]
                work_id = book["key"].split("/")[-1]
                book = doc
                break  # Exit the loop once we find the first occurrence
        if cover_i is not None:
            image = "https://covers.openlibrary.org/b/id/" + str(cover_i) + "-L.jpg?default=false"
        else:
            logging.info("Cover image not found for book: {title}")
            image = None
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
            "description": workResponse.json().get("description", "Description not available")
        }
        collection.insert_one(result.copy())
    
    else:
        data = collection.find_one({"title": title})
        desc = data["description"].replace('\r', '').replace('\n', '').replace('\t', '')
        result = {
            "coverImage": data["coverImage"],
            "title": data["title"],
            "author": data["author"],
            "description": desc
        }
    
    return result

def get_book_by_title(query, i=0) -> JSONResponse:
    try:
        response = requests.get(query)
    except Exception as e:
        logging.error(f"Error processing default request: {e}")
        return JSONResponse(status_code=500, content={"message": "Internal Server Error"})
    
    if response.status_code != 200:
        logging.error(f"{i}. Error processing request: {response.text}")
        return JSONResponse(status_code=500, content={"message": "Internal Server Error"})
    
    book_data = response.json()
    volumes = book_data['items']
    book = None
    for item in volumes:
        if "description" in item['volumeInfo']:
            book = item['volumeInfo']            
            break


    if book is not None:
        if len(book['description'].split(' ')) > 150 and i < 7:
            return get_book_by_title(query, i+1)
        result = {
            "coverImage": book["imageLinks"]["thumbnail"],
            "title": book['title'],
            "author": book['authors'][0],
            "description": book["description"]
        }
        return result
    else:
        return JSONResponse(status_code=404, content={"message": "Book not found"})

def get_book_by_cover(query) -> JSONResponse:
    # Default request
    try:
        response = requests.get('https://openlibrary.org/search.json?q= title: "' + query + '"&limit=2')
    except Exception as e:
        logging.error(f"Error processing default request: {e}")
        return JSONResponse(status_code=500, content={"message": "Internal Server Error"})
    
    # Check for errors
    if response.status_code != 200:
        logging.error(f"Error processing request: {response.text}")
        return JSONResponse(status_code=500, content={"message": "Internal Server Error"})
    # Check for empty response
    book_data = response.json()
    
    if book_data["numFound"] == 0:
        logging.error(f"Book not found by title: {query}")
        logging.info("Searching by author")
        response = requests.get('https://openlibrary.org/search.json?author=' + query + "&limit=2")
        book_data = response.json()
        if book_data["numFound"] == 0:
            logging.error(f"Book not found by author: {query}")
            return JSONResponse(status_code=404, content={"message": "Book not found"})
    
    # Processing response
    book = book_data["docs"][0]

    cover_i = None
    work_id = None
    # Iterate through the list of dictionaries in "docs"
    for doc in book_data.get("docs", []):
        if "cover_i" in doc:
            cover_i = doc["cover_i"]
            work_id = book["key"].split("/")[-1]
            book = doc
            break  # Exit the loop once we find the first occurrence
    if cover_i is not None:
        image = "https://covers.openlibrary.org/b/id/" + str(cover_i) + "-L.jpg?default=false"
    else:
        logging.info("Cover image not found for book: {title}")
        image = None
    
    work = "https://openlibrary.org/works/" + work_id + ".json"

    # Work request
    try:
        workResponse = requests.get(work)
    except Exception as e:
        logging.error(f"Error processing work request: {e}")
        return JSONResponse(status_code=500, content={"message": "Internal Server Error"})
    
    # Compiling result
    desc = workResponse.json().get("description", "Description not available")
    if desc != "Description not available":
        desc = desc['value'][:desc['value'].find("\r")]
    result = {
        "coverImage": image,
        "title": book["title"],
        "author": book["author_name"][0],
        "description": desc
    }
    return result