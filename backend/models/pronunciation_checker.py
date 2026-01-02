import Levenshtein
import re
from typing import Dict

class PronunciationChecker:
    """
    Checks pronunciation of individual words.
    """
    
    def __init__(self, speech_model):
        self.speech_model = speech_model
    
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
        Check pronunciation of a single word.
        
        Args:
            audio_path: Path to the audio file
            word: The word that should have been pronounced
            
        Returns:
            Dictionary containing:
            - is_correct: Boolean indicating if pronunciation is correct
            - confidence: Confidence score (0-1)
            - transcription: What the user said
            - expected: The word that was expected
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
            "accuracy": round(accuracy, 2)
        }
