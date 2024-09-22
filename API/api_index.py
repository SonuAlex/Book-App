from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from datetime import datetime
from dotenv import load_dotenv
import pymongo
import uvicorn
import logging
import ol_data_format as ol
import os

# Initializing the logger
logging.basicConfig(filename='api_logs.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

load_dotenv()
app = FastAPI()

MONGODB_API = os.environ.get('MONGODB_API_STRING')

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
    coverImageEmbedding: list[float]
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

try:
    client = pymongo.MongoClient(MONGODB_API)
    db = client["bookstore"]
    collection = db["books"]
    userCollection = db["users"]
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

@app.get("/status")
def read_root():
    logging.info("API status check")
    return {"status": "OK", "timestamp": datetime.now().isoformat()}

# Example request: {"user_id": "123", "title": "The Great Gatsby"}
@app.post('/book')  # POST request to /book
def handle_book_request(request: BookRequest):
    logging.info(f"User: {request.user_id} - Book: {request.title}")

    # Search logic here
    OL_API_STRING = os.environ.get("OPENLIB_API_STRING")
    query = OL_API_STRING + "/search.json?title=" + request.title + "&limit=1"
    
    result = ol.get_book_data(query, request.title, OL_API_STRING)
    return result

@app.post('/cover') # POST request to /cover
def handle_cover_request(request: CoverRequest):
    logging.info(f"User: {request.user_id} - Cover")

    # Cover search logic here


    return {"status": "OK", "timestamp": datetime.now().isoformat(), "user_id": request.user_id, "coverImageEmbedding": request.coverImageEmbedding}

@app.post('/submit')
def handle_submit_request(request: BookDetails):
    logging.info(f"User: {request.user_id} - Submit")
    # Submit logic here
    if collection.find_one({"title": request.title}):
        return {"status":400, "message": "Book already exists"}
    else:
        userCollection.update_one({"user_id": request.user_id}, {"$inc": {"hosted_books": 1}})
        collection.insert_one(request.model_dump())
        return {"status":200, "message": "Book submitted successfully"}

@app.post('/user')
def handle_user_creation(user: userDetails):
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
def handle_borrow_request(user_id: str, title: str):
    logging.info(f"User: {user_id} - Borrow: {title}")

    # Borrow logic here
    if collection.find_one({"title": title}):
        book = collection.find_one({"title": title})
        if book["available"]:
            userCollection.update_one({"user_id": user_id}, {"$inc": {"borrowed_books": 1}, "$push": {"borrowed_titles": title}})
            collection.update_one({"title": title}, {"$set": {"available": False, "borrowed_by": user_id}})
            return {"status":200, "message": "Book borrowed successfully"}
        else:
            return {"status":400, "message": "Book not available"}
    else:
        return {"status":400, "message": "Book not found"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)