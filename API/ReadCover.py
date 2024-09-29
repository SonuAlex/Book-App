import cv2
from ultralytics import YOLO
import easyocr
from transformers import DistilBertTokenizerFast, DistilBertForSequenceClassification
import torch
import pandas as pd

# Load the fine-tuned model
model = YOLO("D:/notebooks/BookTitleDetection/custom-model/best.pt")
ocr_reader = easyocr.Reader(['en'])
tokenizer = DistilBertTokenizerFast.from_pretrained("./title_classifier_model")
title_classifier = DistilBertForSequenceClassification.from_pretrained("./title_classifier_model")

def verify_title(text):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    with torch.no_grad():
        outputs = title_classifier(**inputs)
    probabilities = torch.softmax(outputs.logits, dim=1)
    return probabilities[0][1].item() > 0.5  # Assuming label 1 is for "title"

def preprocess_image(image):
    results = model.predict(image)
    for result in results:
        a = result.boxes.data
        px = pd.DataFrame(a).astype('float')
        for _, row in px.iterrows():
            x1 = int(row[0])
            y1 = int(row[1])
            x2 = int(row[2])
            y2 = int(row[3])
            d = int(row[5])
    
            if d == 1:
                crop = image[y1:y2, x1:x2]
                #cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 1)
                text = ocr_reader.readtext(crop)
                return text
    return None

def extract_book_title(image):
    # Load and preprocess image
    preprocessed = preprocess_image(image)
    if preprocessed == None:
        return None
    
    extracted_text = ' '.join([text for _, text, conf in preprocessed if conf > 0.5])
    
    # Verify title using fine-tuned model
    if verify_title(extracted_text):
        return extracted_text
    else:
        return None

# path_to_image = "D:/notebooks/BookTitleDetection/images/0000071602.jpg"
# title = extract_book_title(path_to_image)
# print(f'Extracted Image Title is: {title}')