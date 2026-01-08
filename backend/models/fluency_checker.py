import difflib
from typing import List, Dict
import Levenshtein
import re
import time

class FluencyChecker:
    """
    Checks reading fluency by evaluating both pronunciation accuracy and reading speed.
    Provides comprehensive feedback for dyslexia support.
    """

    def __init__(self, speech_model):
        self.speech_model = speech_model
        self.audio_start_time = None
        self.audio_end_time = None

    def normalize_text(self, text: str) -> str:
        """Normalize text for comparison."""
        # Convert to lowercase
        text = text.lower()
        # Remove punctuation
        text = re.sub(r'[^\w\s]', '', text)
        # Remove extra whitespace
        text = ' '.join(text.split())
        return text

    def calculate_pronunciation_score(self, text1: str, text2: str) -> float:
        """
        Calculate pronunciation accuracy score between two texts.

        Returns:
            Pronunciation score between 0 and 1
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

        # Combine metrics with weights (pronunciation focused)
        pronunciation_score = (
            seq_similarity * 0.3 +
            lev_similarity * 0.3 +
            word_accuracy * 0.4
        )

        return pronunciation_score

    def calculate_reading_speed(self, text: str, audio_duration: float) -> Dict:
        """
        Calculate reading speed metrics using research-backed relative bands.

        Uses dyslexia-friendly WPM bands that avoid harsh penalties:
        - ≥ 90 WPM: 100% (Fluent)
        - 70-89 WPM: 80% (Good)
        - 50-69 WPM: 60% (Developing)
        - < 50 WPM: 40% (Needs support)

        Args:
            text: The text that was read
            audio_duration: Duration of audio in seconds

        Returns:
            Dictionary containing WPM, speed score, and speed rating
        """
        word_count = len(self.normalize_text(text).split())

        # Avoid division by zero
        if audio_duration <= 0:
            return {
                "wpm": 0,
                "speed_score": 0.0,
                "speed_rating": "No audio detected",
                "duration": 0
            }

        # Calculate Words Per Minute (WPM)
        wpm = (word_count / audio_duration) * 60

        # Research-backed relative speed bands (dyslexia-friendly)
        # These avoid harsh penalties and focus on supportive feedback
        if wpm >= 90:
            speed_score = 1.0  # 100%
            speed_rating = "Fluent Speed! 🚀"
        elif wpm >= 70:
            speed_score = 0.8  # 80%
            speed_rating = "Good Speed! 🌟"
        elif wpm >= 50:
            speed_score = 0.6  # 60%
            speed_rating = "Developing! 👍"
        else:  # < 50
            speed_score = 0.4  # 40%
            speed_rating = "Take Your Time! 📚"

        return {
            "wpm": round(wpm, 1),
            "speed_score": round(speed_score, 2),
            "speed_rating": speed_rating,
            "duration": round(audio_duration, 2)
        }

    def combine_scores(self, pronunciation_score: float, speed_score: float) -> Dict:
        """
        Combine pronunciation and speed scores into final fluency score.

        Pronunciation is weighted higher (70%) than speed (30%) because
        accuracy is more important than speed for dyslexia support.

        Returns:
            Dictionary with combined score and breakdown
        """
        # Weight pronunciation more heavily (70%) vs speed (30%)
        final_score = (pronunciation_score * 0.70) + (speed_score * 0.30)

        return {
            "final_score": round(final_score * 100),  # Convert to 0-100 scale
            "pronunciation_score": round(pronunciation_score * 100),
            "speed_score": round(speed_score * 100),
            "pronunciation_weight": 70,
            "speed_weight": 30
        }

    def get_overall_rating(self, final_score: int) -> str:
        """Get child-friendly overall performance rating."""
        if final_score >= 90:
            return "🌟 Amazing! You're a reading star!"
        elif final_score >= 80:
            return "🎉 Excellent work! Keep it up!"
        elif final_score >= 70:
            return "👍 Great job! You're doing well!"
        elif final_score >= 60:
            return "😊 Good effort! You're improving!"
        elif final_score >= 50:
            return "💪 Nice try! Keep practicing!"
        else:
            return "📚 Keep going! Practice makes perfect!"

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

    def check_fluency(self, audio_path: str, expected_text: str, audio_duration: float = None) -> Dict:
        """
        Check reading fluency by evaluating both pronunciation and speed.

        Args:
            audio_path: Path to the audio file
            expected_text: The text that should have been read
            audio_duration: Duration of audio in seconds (optional, will be calculated if not provided)

        Returns:
            Dictionary containing:
            - transcription: What the user said
            - pronunciation_score: Accuracy score (0-100)
            - speed_metrics: WPM, speed score, rating
            - final_score: Combined fluency score (0-100)
            - overall_rating: Child-friendly performance message
            - feedback: Word-by-word feedback
        """
        # Start timing if duration not provided
        start_time = time.time()

        # Transcribe the audio
        transcription = self.speech_model.transcribe_audio(audio_path)

        # Calculate audio duration if not provided
        if audio_duration is None:
            try:
                import librosa
                y, sr = librosa.load(audio_path)
                audio_duration = librosa.get_duration(y=y, sr=sr)
            except:
                # Fallback: use processing time as rough estimate (not accurate)
                audio_duration = time.time() - start_time

        if not transcription:
            return {
                "transcription": "",
                "pronunciation_score": 0,
                "speed_metrics": {
                    "wpm": 0,
                    "speed_score": 0,
                    "speed_rating": "No audio detected",
                    "duration": 0
                },
                "final_score": 0,
                "overall_rating": "No speech detected. Please try again!",
                "feedback": [],
                "error": "Could not transcribe audio. Please try speaking more clearly."
            }

        # Calculate pronunciation accuracy
        pronunciation_score = self.calculate_pronunciation_score(transcription, expected_text)

        # Calculate reading speed metrics
        speed_metrics = self.calculate_reading_speed(expected_text, audio_duration)

        # Combine scores
        combined_scores = self.combine_scores(pronunciation_score, speed_metrics["speed_score"])

        # Get overall rating
        overall_rating = self.get_overall_rating(combined_scores["final_score"])

        # Get word-by-word feedback
        feedback = self.get_word_feedback(transcription, expected_text)

        return {
            "transcription": transcription,
            "pronunciation_score": combined_scores["pronunciation_score"],
            "speed_metrics": speed_metrics,
            "final_score": combined_scores["final_score"],
            "score_breakdown": {
                "pronunciation_contribution": combined_scores["pronunciation_score"] * 0.70,
                "speed_contribution": speed_metrics["speed_score"] * 0.30,
                "weights": {
                    "pronunciation": "70%",
                    "speed": "30%"
                }
            },
            "overall_rating": overall_rating,
            "feedback": feedback,
            "expected": expected_text
        }
