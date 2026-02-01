from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import os
import tempfile
from typing import List, Dict, Optional
import uuid

# Import our custom modules
from models.speech_recognition_model import SpeechRecognitionModel
from models.fluency_checker import FluencyChecker
from models.pronunciation_checker import PronunciationChecker
from models.vocabulary_generator import VocabularyGenerator

# Initialize FastAPI app
app = FastAPI(
    title="Dyslexia Support API",
    description="Backend API for dyslexia support mobile application",
    version="1.0.0"
)


# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize AI models
print("Loading AI models...")
speech_model = SpeechRecognitionModel()
fluency_checker = FluencyChecker(speech_model)
pronunciation_checker = PronunciationChecker(speech_model)
vocabulary_generator = VocabularyGenerator()
print("Models loaded successfully!")

# Store for questions (in production, use a database)
active_questions: Dict[str, Dict] = {}


# Pydantic models
class VocabularyAnswer(BaseModel):
    question_id: str
    answer: str


# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "message": "API is running"}


# Reading Fluency Endpoints
@app.post("/api/fluency/check")
async def check_fluency(
    audio: UploadFile = File(...),
    expected_text: str = Form(...)
):
    """
    Check reading fluency by comparing audio transcription with expected text.
    
    Returns:
    - transcription: What the user said
    - score: Similarity percentage (0-100)
    - feedback: List of words with correctness status
    """
    try:
        # Save uploaded audio to temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_audio:
            content = await audio.read()
            temp_audio.write(content)
            temp_audio_path = temp_audio.name
        
        # Process the audio
        result = fluency_checker.check_fluency(temp_audio_path, expected_text)
        
        # Clean up temporary file
        os.unlink(temp_audio_path)
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing audio: {str(e)}")


# Pronunciation Endpoints
@app.post("/api/pronunciation/check")
async def check_pronunciation(
    audio: UploadFile = File(...),
    word: str = Form(...)
):
    """
    Check pronunciation of a single word.
    
    Returns:
    - is_correct: Boolean indicating if pronunciation is correct
    - confidence: Confidence score (0-1)
    - transcription: What the user said
    """
    try:
        # Save uploaded audio to temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_audio:
            content = await audio.read()
            temp_audio.write(content)
            temp_audio_path = temp_audio.name
        
        # Check pronunciation
        result = pronunciation_checker.check_pronunciation(temp_audio_path, word)
        
        # Clean up temporary file
        os.unlink(temp_audio_path)
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing audio: {str(e)}")


# Vocabulary Endpoints
@app.get("/api/vocabulary/question")
async def get_vocabulary_question(difficulty: str = "easy"):
    """
    Generate an AI-powered vocabulary question.

    Returns:
    - question_id: Unique identifier for the question
    - question: The question text
    - options: List of answer options
    - question_type: Type of question (context, confusing_pair, etc.)
    - sentence_context: Full sentence for audio support (if available)
    - target_word: The word being tested (if available)
    """
    try:
        question_data = vocabulary_generator.generate_question(difficulty)
        question_id = str(uuid.uuid4())

        # Store the question with its correct answer
        active_questions[question_id] = question_data

        # Build response with additional context for audio support
        response = {
            "question_id": question_id,
            "question": question_data["question"],
            "options": question_data["options"],
            "question_type": question_data.get("question_type", "standard"),
        }

        # Add optional fields for context-based questions
        if "sentence_context" in question_data:
            response["sentence_context"] = question_data["sentence_context"]
        if "target_word" in question_data:
            response["target_word"] = question_data["target_word"]

        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating question: {str(e)}")


@app.post("/api/vocabulary/check")
async def check_vocabulary_answer(answer_data: VocabularyAnswer):
    """
    Check if the submitted answer is correct.
    
    Returns:
    - is_correct: Boolean indicating if answer is correct
    - correct_answer: The correct answer
    - explanation: Explanation of the answer
    """
    try:
        question_id = answer_data.question_id
        user_answer = answer_data.answer
        
        if question_id not in active_questions:
            raise HTTPException(status_code=404, detail="Question not found")
        
        question_data = active_questions[question_id]
        correct_answer = question_data["correct_answer"]
        
        is_correct = user_answer.lower().strip() == correct_answer.lower().strip()
        
        # Clean up the question from memory
        del active_questions[question_id]
        
        return {
            "is_correct": is_correct,
            "correct_answer": correct_answer,
            "explanation": question_data.get("explanation", "")
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error checking answer: {str(e)}")


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
