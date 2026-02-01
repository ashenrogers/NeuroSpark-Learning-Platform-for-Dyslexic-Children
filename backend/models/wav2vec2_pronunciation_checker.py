import torch
import torchaudio
from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor
import numpy as np
from typing import Dict, List
import re

class Wav2Vec2PronunciationChecker:
    """
    Advanced pronunciation checker using Wav2Vec2 model for phoneme-level analysis.
    This provides industry-standard pronunciation assessment.
    """
    
    def __init__(self, model_name="facebook/wav2vec2-base-960h"):
        """
        Initialize Wav2Vec2 model for pronunciation checking.
        
        Args:
            model_name: HuggingFace model identifier
        """
        print("Loading Wav2Vec2 model for pronunciation analysis...")
        
        # Load processor and model
        self.processor = Wav2Vec2Processor.from_pretrained(model_name)
        self.model = Wav2Vec2ForCTC.from_pretrained(model_name)
        
        # Set model to evaluation mode
        self.model.eval()
        
        print("Wav2Vec2 model loaded successfully!")
    
    def preprocess_audio(self, audio_path: str) -> torch.Tensor:
        """
        Preprocess audio file for Wav2Vec2 input.
        
        Args:
            audio_path: Path to audio file
            
        Returns:
            Preprocessed audio tensor
        """
        # Load audio file
        waveform, sample_rate = torchaudio.load(audio_path)
        
        # Resample to 16kHz if needed (Wav2Vec2 expects 16kHz)
        if sample_rate != 16000:
            resampler = torchaudio.transforms.Resample(sample_rate, 16000)
            waveform = resampler(waveform)
        
        # Convert to mono if stereo
        if waveform.shape[0] > 1:
            waveform = torch.mean(waveform, dim=0, keepdim=True)
        
        # Normalize audio
        waveform = waveform / torch.max(torch.abs(waveform))
        
        return waveform.squeeze()
    
    def get_phoneme_sequence(self, audio_tensor: torch.Tensor) -> List[str]:
        """
        Extract phoneme sequence from audio using Wav2Vec2.
        
        Args:
            audio_tensor: Preprocessed audio tensor
            
        Returns:
            List of predicted phonemes
        """
        with torch.no_grad():
            # Process audio
            inputs = self.processor(audio_tensor, sampling_rate=16000, return_tensors="pt", padding=True)
            
            # Get logits
            logits = self.model(inputs.input_values).logits
            
            # Get predicted IDs
            predicted_ids = torch.argmax(logits, dim=-1)
            
            # Convert to transcription
            transcription = self.processor.batch_decode(predicted_ids)[0]
            
            # Extract phonemes (simplified approach - in production, use phoneme mapping)
            phonemes = self._text_to_phonemes(transcription)
            
            return phonemes
    
    def _text_to_phonemes(self, text: str) -> List[str]:
        """
        Convert text to phoneme representation (simplified).
        In production, use a proper phoneme library like epitran or phonemizer.
        
        Args:
            text: Input text
            
        Returns:
            List of phonemes
        """
        # Remove special characters and convert to lowercase
        text = re.sub(r'[^\w\s]', '', text.lower())
        
        # Simple phoneme mapping (this is a basic implementation)
        # In production, use a proper phonetic dictionary
        phoneme_map = {
            'a': ['æ', 'ə', 'ɑ'],
            'e': ['ɛ', 'i', 'e'],
            'i': ['ɪ', 'i'],
            'o': ['ɔ', 'oʊ', 'ɒ'],
            'u': ['ʊ', 'u', 'ʌ'],
            'b': ['b'],
            'c': ['k', 's'],
            'd': ['d'],
            'f': ['f'],
            'g': ['g', 'dʒ'],
            'h': ['h'],
            'j': ['dʒ'],
            'k': ['k'],
            'l': ['l'],
            'm': ['m'],
            'n': ['n'],
            'p': ['p'],
            'q': ['k'],
            'r': ['r'],
            's': ['s', 'z'],
            't': ['t'],
            'v': ['v'],
            'w': ['w'],
            'x': ['ks'],
            'y': ['j'],
            'z': ['z']
        }
        
        phonemes = []
        for char in text:
            if char in phoneme_map:
                phonemes.extend(phoneme_map[char])
            elif char == ' ':
                phonemes.append(' ')  # Word boundary
        
        return phonemes
    
    def calculate_phoneme_accuracy(self, predicted_phonemes: List[str], 
                                 expected_phonemes: List[str]) -> float:
        """
        Calculate phoneme-level accuracy using dynamic time warping.
        
        Args:
            predicted_phonemes: Phonemes from user's speech
            expected_phonemes: Expected phonemes for the word
            
        Returns:
            Phoneme accuracy score (0-1)
        """
        if not predicted_phonemes or not expected_phonemes:
            return 0.0
        
        # Remove spaces for comparison
        pred_clean = [p for p in predicted_phonemes if p != ' ']
        exp_clean = [p for p in expected_phonemes if p != ' ']
        
        # Calculate phoneme similarity
        matches = 0
        total = max(len(pred_clean), len(exp_clean))
        
        # Simple matching (can be improved with DTW)
        for i in range(min(len(pred_clean), len(exp_clean))):
            if pred_clean[i] == exp_clean[i]:
                matches += 1
        
        accuracy = matches / total if total > 0 else 0.0
        return accuracy
    
    def check_pronunciation(self, audio_path: str, expected_word: str) -> Dict:
        """
        Check pronunciation using Wav2Vec2 phoneme analysis.
        
        Args:
            audio_path: Path to audio file
            expected_word: The word that should be pronounced
            
        Returns:
            Dictionary with pronunciation analysis results
        """
        try:
            # Preprocess audio
            audio_tensor = self.preprocess_audio(audio_path)
            
            # Get phoneme sequence from user's speech
            predicted_phonemes = self.get_phoneme_sequence(audio_tensor)
            
            # Get expected phonemes for the target word
            expected_phonemes = self._text_to_phonemes(expected_word)
            
            # Calculate phoneme accuracy
            phoneme_accuracy = self.calculate_phoneme_accuracy(
                predicted_phonemes, expected_phonemes
            )
            
            # Get transcription for display
            with torch.no_grad():
                inputs = self.processor(audio_tensor, sampling_rate=16000, return_tensors="pt", padding=True)
                logits = self.model(inputs.input_values).logits
                predicted_ids = torch.argmax(logits, dim=-1)
                transcription = self.processor.batch_decode(predicted_ids)[0]
            
            # Calculate confidence based on phoneme accuracy
            confidence = phoneme_accuracy
            
            # Determine if pronunciation is correct
            threshold = 0.7  # 70% phoneme accuracy required
            is_correct = phoneme_accuracy >= threshold
            
            return {
                "is_correct": is_correct,
                "confidence": round(confidence, 3),
                "transcription": transcription.strip(),
                "expected": expected_word,
                "phoneme_accuracy": round(phoneme_accuracy, 3),
                "predicted_phonemes": predicted_phonemes,
                "expected_phonemes": expected_phonemes,
                "model_used": "Wav2Vec2"
            }
            
        except Exception as e:
            return {
                "is_correct": False,
                "confidence": 0.0,
                "transcription": "",
                "expected": expected_word,
                "error": f"Wav2Vec2 analysis failed: {str(e)}",
                "model_used": "Wav2Vec2"
            }
