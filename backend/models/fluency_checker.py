import difflib
from typing import List, Dict
import Levenshtein
import re

class FluencyChecker:
    """
    Checks reading fluency by comparing transcribed text with expected text.
    """
    
    def __init__(self, speech_model):
        self.speech_model = speech_model
    
    def normalize_text(self, text: str) -> str:
        """Normalize text for comparison."""
        # Convert to lowercase
        text = text.lower()
        # Remove punctuation
        text = re.sub(r'[^\w\s]', '', text)
        # Remove extra whitespace
        text = ' '.join(text.split())
        return text
    
    def calculate_similarity(self, text1: str, text2: str) -> float:
        """
        Calculate similarity between two texts using multiple metrics.
        
        Returns:
            Similarity score between 0 and 1
        """
        text1_norm = self.normalize_text(text1)
        text2_norm = self.normalize_text(text2)
        
        # Sequence matcher similarity
        seq_similarity = difflib.SequenceMatcher(None, text1_norm, text2_norm).ratio()
        
        # Levenshtein similarity
        max_len = max(len(text1_norm), len(text2_norm))
        if max_len == 0:
            lev_similarity = 1.0
        else:
            lev_distance = Levenshtein.distance(text1_norm, text2_norm)
            lev_similarity = 1 - (lev_distance / max_len)
        
        # Word-level accuracy
        words1 = text1_norm.split()
        words2 = text2_norm.split()
        
        if len(words2) == 0:
            word_accuracy = 0.0
        else:
            correct_words = sum(1 for w1, w2 in zip(words1, words2) if w1 == w2)
            word_accuracy = correct_words / len(words2)
        
        # Combine metrics with weights
        final_similarity = (
            seq_similarity * 0.3 +
            lev_similarity * 0.3 +
            word_accuracy * 0.4
        )
        
        return final_similarity
    
    def get_word_feedback(self, transcribed: str, expected: str) -> List[Dict]:
        """
        Get word-by-word feedback comparing transcribed vs expected text.
        
        Returns:
            List of dictionaries with word and correctness status
        """
        transcribed_words = self.normalize_text(transcribed).split()
        expected_words = self.normalize_text(expected).split()
        
        feedback = []
        
        # Use sequence matcher to align words
        matcher = difflib.SequenceMatcher(None, transcribed_words, expected_words)
        
        for tag, i1, i2, j1, j2 in matcher.get_opcodes():
            if tag == 'equal':
                # Words match
                for i in range(i1, i2):
                    feedback.append({
                        "word": transcribed_words[i],
                        "correct": True
                    })
            elif tag == 'replace':
                # Words don't match
                for i in range(i1, i2):
                    feedback.append({
                        "word": transcribed_words[i] if i < len(transcribed_words) else "",
                        "correct": False
                    })
            elif tag == 'delete':
                # User said extra words
                for i in range(i1, i2):
                    feedback.append({
                        "word": transcribed_words[i],
                        "correct": False
                    })
            elif tag == 'insert':
                # User skipped words
                for j in range(j1, j2):
                    feedback.append({
                        "word": f"[missing: {expected_words[j]}]",
                        "correct": False
                    })
        
        return feedback
    
    def check_fluency(self, audio_path: str, expected_text: str) -> Dict:
        """
        Check reading fluency by transcribing audio and comparing with expected text.
        
        Args:
            audio_path: Path to the audio file
            expected_text: The text that should have been read
            
        Returns:
            Dictionary containing:
            - transcription: What the user said
            - score: Similarity percentage (0-100)
            - feedback: Word-by-word feedback
        """
        # Transcribe the audio
        transcription = self.speech_model.transcribe_audio(audio_path)
        
        if not transcription:
            return {
                "transcription": "",
                "score": 0,
                "feedback": [],
                "error": "Could not transcribe audio. Please try again."
            }
        
        # Calculate similarity
        similarity = self.calculate_similarity(transcription, expected_text)
        score = round(similarity * 100)
        
        # Get word-by-word feedback
        feedback = self.get_word_feedback(transcription, expected_text)
        
        return {
            "transcription": transcription,
            "score": score,
            "feedback": feedback,
            "expected": expected_text
        }
