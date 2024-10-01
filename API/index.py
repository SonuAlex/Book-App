from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse, FileResponse
from pydantic import BaseModel, Field
from datetime import datetime, timedelta
from dotenv import load_dotenv
import pymongo
import uvicorn
import logging
import ol_data_format as ol
import os
import ReadCover
import numpy as np
import cv2

# Initializing the logger
logging.basicConfig(filename='api_logs.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

load_dotenv()
app = FastAPI()

MONGODB_API = os.environ.get('MONGODB_API_STRING')
local_host = 'mongodb://localhost:27017'

# Initializing classes
class userDetails(BaseModel):
    user_id: str
    name: str
    email: str
    phone: int
    password: str
    hosted_books: int = Field(default=0)
    borrowed_books: int = Field(default=0)
    flat_no: str
    role: str = Field(default="user")
    borrowed_titles: list[str] = Field(default=[])
class CoverRequest(BaseModel):
    user_id: str
class BookRequest(BaseModel):
    user_id: str
    title: str
class BookDetails(BaseModel):
    user_id: str
    title: str
    author: str
    coverImage: str
    description: str
    available: bool = Field(default=True)
    borrowed_by: str = Field(default="")
class validateUser(BaseModel):
    user_id: str
    password: str

try:
    client = pymongo.MongoClient(local_host)
    db = client["bookstore"]
    collection = db["books"]
    userCollection = db["users"]
    registerCollection = db["register"]
except Exception as e:
    logging.error(f"Error connecting to MongoDB: {e}")
    raise

@app.middleware("http")
async def log_requests(request, call_next):
    try:
        response = await call_next(request)
    except Exception as e:
        logging.error(f"Error processing request: {e}")
        return JSONResponse(status_code=500, content={"message": "Internal Server Error"})
    log_message = f"{request.method} {request.url} - Status: {response.status_code}"
    logging.info(log_message)
    return response

@app.get('/')
def root():
    return {"status": 200, "message": "Welcome to the Bookstore API"}

@app.get('/favicon.ico', include_in_schema=False)
async def favicon():
    return FileResponse('favicon.ico')

@app.get("/status")
def read_root():
    logging.info("API status check")
    return {"status": "OK", "timestamp": datetime.now().isoformat()}

@app.get('/book')  # POST request to /book
def handle_book_request(user_id: str, title: str):  # When a user wants to search for a book detail by title
    logging.info(f"User: {user_id} - Book: {title}")

    # Search logic here
    OL_API_STRING = os.environ.get("OPENLIB_API_STRING")
    query = OL_API_STRING + "/search.json?title=" + title + "&limit=3"
    
    result = ol.get_book_data(query, title, OL_API_STRING)
    return result

# Example request: {"user_id": "123", "title": "The Great Gatsby"}
@app.post('/book')  # POST request to /book
def handle_book_request(request: BookRequest):  # When a user wants to search for a book detail by title
    logging.info(f"User: {request.user_id} - Book: {request.title}")

    # Search logic here
    OL_API_STRING = os.environ.get("OPENLIB_API_STRING")
    query = OL_API_STRING + "/search.json?title=" + request.title + "&limit=3"
    
    result = ol.get_book_data(query, request.title, OL_API_STRING)
    return result

@app.post('/cover') # POST request to /cover
async def handle_cover_request(user_id: str = Form(...), file: UploadFile = File(...)):    # When a user wants to search for a book detail by cover
    logging.info(f"User: {user_id} - Cover Request")

    # Cover search logic here
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    bookTitle = ReadCover.extract_book_title(image)
    print(f'Extracted Image Title is: {bookTitle}')
    result = ol.get_book_by_cover(bookTitle)

    return result

@app.post('/submit')
def handle_submit_request(request: BookDetails):    # When a user wants to submit a book
    logging.info(f"User: {request.user_id} - Submit")
    # Submit logic here
    if collection.find_one({"title": request.title}):
        return {"status":400, "message": "Book already exists"}
    else:
        userCollection.update_one({"user_id": request.user_id}, {"$inc": {"hosted_books": 1}})
        collection.insert_one(request.model_dump())
        return {"status":200, "message": "Book submitted successfully"}

@app.post('/user')
def handle_user_creation(user: userDetails):    #Creating new user in the system
    logging.info(f"User: {user.user_id} - User Created")

    # User creation logic here
    if userCollection.find_one({"user_id": user.user_id}):
        return {"status":400, "message": "User already exists"}
    elif userCollection.find_one({"email": user.email}):
        return {"status":400, "message": "Email already exists"}
    elif userCollection.find_one({"phone": user.phone}):
        return {"status":400, "message": "Phone number already exists"}
    else:
        userCollection.insert_one(user.model_dump())
        return {"status":200, "message": "User created successfully"}

@app.get('/borrow')
def handle_borrow_request(user_id: str, title: str):    # When a user whants to borrow a book
    logging.info(f"User: {user_id} - Borrow: {title}")

    # Borrow logic here
    if collection.find_one({"title": title}):
        book = collection.find_one({"title": title})
        if book["available"]:
            userCollection.update_one({"user_id": user_id}, {"$inc": {"borrowed_books": 1}, "$push": {"borrowed_titles": title}})
            collection.update_one({"title": title}, {"$set": {"available": False, "borrowed_by": user_id}})
            registerCollection.insert_one({"user_id": user_id, "title": title, "borrowed_on": datetime.now().isoformat(), "deadline": (datetime.now() + timedelta(days=7)).isoformat(), "returned": ""})
            logging.info(f"Book {title} borrowed by {user_id}")
            return {"status":200, "message": "Book borrowed successfully", "deadline": (datetime.now() + timedelta(days=7)).isoformat()}
        else:
            return {"status":400, "message": "Book not available"}
    else:
        return {"status":400, "message": "Book not found"}

@app.get('/return')
def handle_return_request(user_id: str, title: str):    # When a user wants to return
    logging.info(f"User: {user_id} - Return: {title}")

    # Return logic here
    book = collection.find_one({"title": title})
    try:
        userCollection.update_one({"user_id": user_id}, {"$inc": {"borrowed_books": -1}, "$pull": {"borrowed_titles": title}})
        collection.update_one({"title": title}, {"$set": {"available": True, "borrowed_by": ""}})
        registerCollection.update_one({"title": title}, {"$set": {"returned": datetime.now().isoformat()}})
        logging.info(f"Book {title} returned by {user_id}")
        return {"status":200, "message": "Book returned successfully"}
    except Exception as e:
        logging.error(f"Error returning book: {e}")
        return {"status":400, "message": "Book Return Failed"}

@app.post('/login')
def handle_login_request(request: validateUser):    # When a user wants to login
    logging.info(f"User: {request.user_id} - Login")

    # Login logic here
    user = userCollection.find_one({"user_id": request.user_id, "password": request.password})
    if user:
        return {"status":200, "message": "Login Successful", "user_id": user["user_id"], "name": user["name"], "role": user["role"]}
    else:
        return {"status":400, "message": "Login Failed"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)