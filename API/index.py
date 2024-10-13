from fastapi import FastAPI, File, UploadFile, Form, Request
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
from bson import ObjectId

def convert_objectid(data):
    if isinstance(data, list):
        return [convert_objectid(item) for item in data]
    elif isinstance(data, dict):
        return {key: convert_objectid(value) for key, value in data.items()}
    elif isinstance(data, ObjectId):
        return str(data)
    else:
        return data

# Initializing the logger
s = f"logs/{datetime.now().strftime('%d-%m-%Y')}.log"
logging.basicConfig(filename=s, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

load_dotenv()
app = FastAPI()

MONGODB_API = os.environ.get('MONGODB_API_STRING')
local_host = 'mongodb://localhost:27017'

# Initializing classes
class RequestModel(BaseModel):
    title: str
    user_id: str
    owner_id: str
    response: int
class verifyUser(BaseModel):
    user_id: str
class userDetails(BaseModel):
    user_id: str
    name: str
    email: str
    phone: int
    flat_no: str
    role: str = Field(default="user")
    isVerified: bool = Field(default=False)
    hosted_books: int = Field(default=0)
    borrowed_books: int = Field(default=0)
    requests: list[dict[str, list[dict[str, bool]]]] = Field(default=[])
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
    registerCollection = db["history"]
    requestCollection = db["requests"]
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

@app.get('/allBooks')
def get_all_books():
    logging.info("All Books Request")
    books = collection.find()
    books_list = list(books)
    books_serializable = convert_objectid(books_list)
    books_serializable.reverse()
    return books_serializable

@app.get('/borrowedBooks')
def get_borrowed_books(user_id: str):
    logging.info(f"User: {user_id} - Borrowed Books")
    books = collection.find({"borrowed_by": user_id})
    books_list = list(books)
    books_serializable = convert_objectid(books_list)
    return books_serializable

@app.get('/ownedBooks')
def get_owned_books(user_id: str):
    logging.info(f"User: {user_id} - Owned Books")
    books = collection.find({"user_id": user_id})
    books_list = list(books)
    books_serializable = convert_objectid(books_list)
    return books_serializable

@app.get('/book')  # POST request to /book
def handle_book_request(user_id: str, title: str):  # When a user wants to search for a book detail by title
    logging.info(f"User: {user_id} - Book: {title}")

    # Search logic here
    # OL_API_STRING = os.environ.get("OPENLIB_API_STRING")
    # query = OL_API_STRING + "/search.json?title=" + title + "&limit=3"

    GOOGLE_API_STRING = os.environ.get("GOOGLE_API_STRING")
    query = GOOGLE_API_STRING + title
    
    result = ol.get_book_by_title(query)
    return result

# Example request: {"user_id": "123", "title": "The Great Gatsby"}
@app.post('/book')  # POST request to /book
def handle_book_request(request: BookRequest):  # When a user wants to search for a book detail by title
    logging.info(f"User: {request.user_id} - Book: {request.title}")

    # Search logic here
    # OL_API_STRING = os.environ.get("OPENLIB_API_STRING")
    # query = OL_API_STRING + "/search.json?title=" + request.title + "&limit=3"

    GOOGLE_API_STRING = os.environ.get("GOOGLE_API_STRING")
    query = GOOGLE_API_STRING + request.title
    
    result = ol.get_book_by_title(query)
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

@app.post('/deleteBook')
def handle_delete_request(request: BookRequest):    # When a user wants to delete a book
    logging.info(f"User: {request.user_id} - wants to delete : {request.title}")

    # Delete logic here
    book = collection.find_one({"title": request.title})
    if book:
        if book["user_id"] == request.user_id:
            collection.delete_one({"title": request.title, "user_id": request.user_id})
            userCollection.update_one({"user_id": request.user_id}, {"$inc": {"hosted_books": -1}})
            logging.info(f"Book {request.title} deleted by {request.user_id}")
            return {"status":200, "message": "Book deleted successfully"}
    else:
        return {"status":400, "message": "Book not found"}

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

@app.post('/verify')
def handle_verified_request(abc: verifyUser):    # When a user wants to verify
    logging.info(f"User: {abc.user_id} - Verification complete")

    # Verification logic here
    user = userCollection.find_one({"user_id": abc.user_id})
    if user:
        userCollection.update_one({"user_id": abc.user_id}, {"$set": {"isVerified": True}})
        return {"status":200, "message": "User Verified"}
    else:
        return {"status":400, "message": "User not found"}

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
        requestCollection.delete_one({"title": title, "user_id": user_id})
        logging.info(f"Book {title} returned by {user_id}")
        return {"status":200, "message": "Book returned successfully"}
    except Exception as e:
        logging.error(f"Error returning book: {e}")
        return {"status":400, "message": "Book Return Failed"}

@app.get('/userDetails')
def get_user_details(user_id: str):   # When a user wants to get details
    logging.info(f"User: {user_id} - Requested Details")

    # User details logic here
    user = userCollection.find_one({"user_id": user_id})
    user = convert_objectid(user)
    if user:
        return user
    else:
        return {"status":400, "message": "User not found"}

@app.post('/requestBorrow')
def handle_request_borrow(data: BookRequest):    # When a user wants to request a borrow
    logging.info(f"User: {data.user_id} - Requested Borrow: {data.title}")

    # Request borrow logic here
    bookData = collection.find_one({"title": data.title})
    if data.user_id == bookData['user_id']:
        return {"status": 400, "message": "You cannot borrow your own book"}
    if not bookData:
        return {"status": 400, "message": "Book not found"}
    request = requestCollection.find()
    for req in request:
        if req['title'] == data.title and req['user_id'] == data.user_id:
            return {"status": 400, "message": "Request already sent"}
                
    bookRequest = RequestModel(title=data.title, user_id=data.user_id, owner_id=bookData['user_id'], response=0)
    requestCollection.insert_one(bookRequest.model_dump())
    return {"status": 200, "message": "Request sent"}

@app.post('/acceptRequest')
def handle_accept_request(request: BookRequest):    # When a user wants to accept a request
    logging.info(f"User: {request.user_id} - Accept Request: {request.title}")

    # Accept request logic here
    doc = requestCollection.find()
    for data in doc:
        if data['title'] == request.title and data['user_id'] == request.user_id:
            if data['response'] == 1:
                return {"status": 400, "message": "Request already accepted"}
            else:
                requestCollection.update_one({"title": request.title, "user_id": request.user_id}, {"$set": {"response": 1}})
                collection.update_one({"title": request.title}, {"$set": {"borrowed_by": request.user_id}})
                registerCollection.insert_one({"user_id": request.user_id, "title": request.title, "borrowed_on": datetime.now().isoformat(), "returned": ""})
                return {"status": 200, "message": "Request accepted"}
    return {"status": 400, "message": "Request not found"}

@app.post('/cancelRequest')
def handle_cancel_request(request: BookRequest):    # When a user wants to cancel a request
    logging.info(f"User: {request.user_id} - Cancel Request: {request.title}")

    # Cancel request logic here
    doc = requestCollection.find()
    for data in doc:
        if data['title'] == request.title and data['user_id'] == request.user_id:
            if data['response'] == 1:
                return {"status": 400, "message": "Request already accepted"}
            elif data['response'] == -1:
                return {"status": 400, "message": "Request already rejected"}
            else:
                requestCollection.delete_one({"title": request.title, "user_id": request.user_id})
                return {"status": 200, "message": "Request cancelled"}
    return {"status": 400, "message": "Request not found"}

@app.post('/rejectRequest')
def handle_reject_request(request: BookRequest):    # When a user wants to reject a request
    logging.info(f"User: {request.user_id} - Reject Request: {request.title}")

    # Reject request logic here
    doc = requestCollection.find()
    for data in doc:
        if data['title'] == request.title and data['user_id'] == request.user_id:
            if data['response'] == 1:
                return {"status": 400, "message": "Request already accepted"}
            elif data['response'] == -1:
                return {"status": 400, "message": "Request already rejected"}
            else:
                requestCollection.update_one({"title": request.title, "user_id": request.user_id}, {"$set": {"response": -1}})
                return {"status": 200, "message": "Request rejected"}
    return {"status": 400, "message": "Request not found"}

@app.get('/requests')
def get_requests(user_id: str):   # When a user wants to get requests
    logging.info(f"User: {user_id} - Requests")

    # Get requests logic here
    incoming = []
    data = requestCollection.find({"owner_id": user_id}, {'_id': 0}).sort("title", 1)
    for req in data:
        if req['response'] == 0:
            incoming.append(req)
    outgoing = []
    data = requestCollection.find({"user_id": user_id}, {'_id': 0}).sort("title", 1)
    for req in data:
        outgoing.append(req)
    return {"incoming": incoming, "outgoing": outgoing}

@app.post('/updateUserSchema')
def update_user_schema():   # When a user wants to update the schema
    logging.info("Updating user schema with new keys")

    # Get the fields from the userDetails class
    user_details_fields = userDetails.__fields__

    # Prepare the new keys and their default values
    new_keys = {field: field_info.default for field, field_info in user_details_fields.items()}

    # Update all documents in the userCollection
    try:
        for user in userCollection.find():
            update_fields = {key: value for key, value in new_keys.items() if key not in user}
            if update_fields:
                userCollection.update_one({"_id": user["_id"]}, {"$set": update_fields})
        logging.info("User schema updated successfully")
        return {"status": 200, "message": "User schema updated successfully"}
    except Exception as e:
        logging.error(f"Error updating user schema: {e}")
        return {"status": 500, "message": "Error updating user schema"}

@app.get('/userName')
def get_user_name(user_id: str):    # When a user wants to get the name
    logging.info(f"User: {user_id} - Name")

    # Get user name logic here
    user = userCollection.find_one({"user_id": user_id})
    if user:
        return {"name": user["name"]}
    else:
        return {"status": 400, "message": "User not found"}

@app.get('/response')
def get_response(user_id: str, title: str):   # When a user wants to get the response
    logging.info(f"User: {user_id} - Response for: {title}")

    # Get response logic here
    response = requestCollection.find_one({"user_id": user_id, "title": title})
    if response:
        return {"response": response["response"]}
    else:
        return {"status": 400, "message": "Request not found"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
    # os.system('ngrok http --url=ghoul-nearby-daily.ngrok-free.app 8000')