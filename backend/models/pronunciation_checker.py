import Levenshtein
import re
from typing import Dict
from .wav2vec2_pronunciation_checker import Wav2Vec2PronunciationChecker

class PronunciationChecker:
    """
    Enhanced pronunciation checker using Wav2Vec2 for phoneme-level analysis.
    Combines traditional methods with advanced Wav2Vec2 model for industry-standard accuracy.
    """
    
    def __init__(self, speech_model):
        self.speech_model = speech_model
        # Initialize Wav2Vec2 for advanced pronunciation analysis
        try:
            self.wav2vec2_checker = Wav2Vec2PronunciationChecker()
            print("Wav2Vec2 pronunciation checker initialized successfully!")
        except Exception as e:
            print(f"Wav2Vec2 not available, falling back to traditional methods: {e}")
            self.wav2vec2_checker = None
    
    def normalize_word(self, word: str) -> str:
        """Normalize word for comparison."""
        # Convert to lowercase and remove special characters
        word = word.lower()
        word = re.sub(r'[^\w]', '', word)
        return word
    
    def calculate_pronunciation_accuracy(self, spoken: str, expected: str) -> float:
        """
        Calculate pronunciation accuracy using phonetic similarity.
        
        Returns:
            Accuracy score between 0 and 1
        """
        spoken_norm = self.normalize_word(spoken)
        expected_norm = self.normalize_word(expected)
        
        # Exact match
        if spoken_norm == expected_norm:
            return 1.0
        
        # Levenshtein distance similarity
        max_len = max(len(spoken_norm), len(expected_norm))
        if max_len == 0:
            return 0.0
        
        distance = Levenshtein.distance(spoken_norm, expected_norm)
        similarity = 1 - (distance / max_len)
        
        # Jaro-Winkler similarity (good for pronunciation)
        jaro_sim = Levenshtein.jaro_winkler(spoken_norm, expected_norm)
        
        # Combine metrics
        final_score = (similarity * 0.4) + (jaro_sim * 0.6)
        
        return final_score
    
    def check_pronunciation(self, audio_path: str, word: str) -> Dict:
        """
        Check pronunciation using Wav2Vec2 for phoneme-level analysis.
        
        Args:
            audio_path: Path to the audio file
            word: The word that should have been pronounced
            
        Returns:
            Dictionary containing comprehensive pronunciation analysis
        """
        # Use Wav2Vec2 if available (preferred method)
        if self.wav2vec2_checker:
            try:
                result = self.wav2vec2_checker.check_pronunciation(audio_path, word)
                # Add fallback info
                result["analysis_method"] = "Wav2Vec2 (phoneme-level)"
                return result
            except Exception as e:
                print(f"Wav2Vec2 failed, falling back to traditional method: {e}")
        
        # Fallback to traditional method
        return self._traditional_pronunciation_check(audio_path, word)
    
    def _traditional_pronunciation_check(self, audio_path: str, word: str) -> Dict:
        """
        Traditional pronunciation checking method (fallback).
        
        Args:
            audio_path: Path to the audio file
            word: The word that should have been pronounced
            
        Returns:
            Dictionary with pronunciation analysis using traditional methods
        """
        # Transcribe the audio with confidence
        result = self.speech_model.transcribe_with_confidence(audio_path)
        transcription = result["text"].strip()
        speech_confidence = result["confidence"]
        
        if not transcription:
            return {
                "is_correct": False,
                "confidence": 0.0,
                "transcription": "",
                "expected": word,
                "analysis_method": "Traditional (text-based)",
                "error": "Could not transcribe audio. Please try again."
            }
        
        # Calculate pronunciation accuracy
        accuracy = self.calculate_pronunciation_accuracy(transcription, word)
        
        # Combine speech recognition confidence with pronunciation accuracy
        final_confidence = (speech_confidence + accuracy) / 2
        
        # Consider it correct if accuracy is above threshold
        threshold = 0.75  # 75% similarity required
        is_correct = accuracy >= threshold
        
        return {
            "is_correct": is_correct,
            "confidence": round(final_confidence, 2),
            "transcription": transcription,
            "expected": word,
            "accuracy": round(accuracy, 2),
            "analysis_method": "Traditional (text-based)"
        }
