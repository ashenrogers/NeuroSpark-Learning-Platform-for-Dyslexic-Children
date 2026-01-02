import speech_recognition as sr
import whisper
import torch
from typing import Optional

class SpeechRecognitionModel:
    """
    Handles speech-to-text conversion using multiple engines.
    Uses Google Speech Recognition as primary and Whisper as fallback.
    """
    
    def __init__(self, use_whisper: bool = True):
        self.recognizer = sr.Recognizer()
        self.use_whisper = use_whisper
        
        # Load Whisper model if enabled
        if use_whisper:
            print("Loading Whisper model...")
            # Use 'base' model for balance between speed and accuracy
            # Options: tiny, base, small, medium, large
            self.whisper_model = whisper.load_model("base")
            print("Whisper model loaded!")
        else:
            self.whisper_model = None
    
    def transcribe_audio(self, audio_path: str, language: str = "en-US") -> Optional[str]:
        """
        Transcribe audio file to text.
        
        Args:
            audio_path: Path to the audio file
            language: Language code (default: en-US)
            
        Returns:
            Transcribed text or None if transcription fails
        """
        try:
            # First try with Google Speech Recognition
            with sr.AudioFile(audio_path) as source:
                audio_data = self.recognizer.record(source)
                
            try:
                # Try Google Speech Recognition first (faster)
                text = self.recognizer.recognize_google(audio_data, language=language)
                return text
            except sr.UnknownValueError:
                print("Google Speech Recognition could not understand audio")
            except sr.RequestError as e:
                print(f"Could not request results from Google: {e}")
            
            # Fallback to Whisper if Google fails
            if self.use_whisper and self.whisper_model is not None:
                print("Using Whisper for transcription...")
                result = self.whisper_model.transcribe(audio_path)
                return result["text"].strip()
            
            return None
            
        except Exception as e:
            print(f"Error transcribing audio: {e}")
            return None
    
    def transcribe_with_confidence(self, audio_path: str) -> dict:
        """
        Transcribe audio and return with confidence score.
        
        Returns:
            Dictionary with 'text' and 'confidence' keys
        """
        try:
            with sr.AudioFile(audio_path) as source:
                audio_data = self.recognizer.record(source)
            
            # Try Google Speech Recognition
            try:
                text = self.recognizer.recognize_google(audio_data, show_all=False)
                return {
                    "text": text,
                    "confidence": 0.9  # Google doesn't provide confidence by default
                }
            except Exception:
                pass
            
            # Fallback to Whisper
            if self.use_whisper and self.whisper_model is not None:
                result = self.whisper_model.transcribe(audio_path)
                # Calculate average confidence from segments
                segments = result.get("segments", [])
                if segments:
                    avg_confidence = sum(s.get("no_speech_prob", 0) for s in segments) / len(segments)
                    confidence = 1.0 - avg_confidence  # Invert no_speech_prob
                else:
                    confidence = 0.5
                
                return {
                    "text": result["text"].strip(),
                    "confidence": confidence
                }
            
            return {
                "text": "",
                "confidence": 0.0
            }
            
        except Exception as e:
            print(f"Error in transcription with confidence: {e}")
            return {
                "text": "",
                "confidence": 0.0
            }
