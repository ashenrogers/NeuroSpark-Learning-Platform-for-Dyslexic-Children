import random
from typing import Dict, List

class VocabularyGenerator:
    """
    Generates vocabulary questions with multiple choice answers.
    Features context-based questions, confusing word pairs, and audio support.
    Organized into progressive difficulty levels for adaptive learning.
    """

    def __init__(self):
        # Question bank organized by difficulty with context-based and confusing word pairs
        self.question_bank = {
            "easy": [
                # Simple common words with context
                {
                    "question": "The cat is sleeping on the _____.",
                    "sentence_context": "The cat is sleeping on the bed.",
                    "target_word": "bed",
                    "options": ["🛏️ a place to sleep", "🍕 a food", "🚗 a vehicle", "📚 a book"],
                    "correct_answer": "🛏️ a place to sleep",
                    "explanation": "A bed is furniture that we sleep on. Cats love to sleep on soft, cozy places!",
                    "question_type": "context"
                },
                {
                    "question": "My dog likes to _____ in the park.",
                    "sentence_context": "My dog likes to run in the park.",
                    "target_word": "run",
                    "options": ["🏃 move fast", "🛌 sleep", "🍽️ eat", "📖 read"],
                    "correct_answer": "🏃 move fast",
                    "explanation": "Run means to move quickly using your legs. Dogs love to run and play!",
                    "question_type": "context"
                },
                {
                    "question": "The sun is very _____ today.",
                    "sentence_context": "The sun is very bright today.",
                    "target_word": "bright",
                    "options": ["☀️ shining with light", "🌙 dark", "❄️ cold", "🌧️ rainy"],
                    "correct_answer": "☀️ shining with light",
                    "explanation": "Bright means full of light. The sun gives us bright light during the day!",
                    "question_type": "context"
                },
                {
                    "question": "I like to _____ my favorite book.",
                    "sentence_context": "I like to read my favorite book.",
                    "target_word": "read",
                    "options": ["📖 look at words and understand", "✍️ write words", "🎨 draw pictures", "🎵 sing songs"],
                    "correct_answer": "📖 look at words and understand",
                    "explanation": "Reading means looking at words and understanding their meaning. Books are fun to read!",
                    "question_type": "context"
                },
                {
                    "question": "Mom made a _____ cake for my birthday.",
                    "sentence_context": "Mom made a big cake for my birthday.",
                    "target_word": "big",
                    "options": ["📏 large in size", "🔍 tiny", "🎨 colorful", "🍰 sweet"],
                    "correct_answer": "📏 large in size",
                    "explanation": "Big means large in size. A big cake can feed many people at a party!",
                    "question_type": "context"
                },
                # Simple confusing pairs
                {
                    "question": "Choose the correct word: I _____ a new toy yesterday.",
                    "confusing_pair": ["see", "saw"],
                    "options": ["see", "saw"],
                    "correct_answer": "saw",
                    "explanation": "We use 'saw' when talking about the past. 'Yesterday' tells us it happened before, so we say 'saw'!",
                    "question_type": "confusing_pair"
                },
                {
                    "question": "Choose the correct word: Can you _____ me the book?",
                    "confusing_pair": ["give", "gave"],
                    "options": ["give", "gave"],
                    "correct_answer": "give",
                    "explanation": "We use 'give' when asking someone to do something now. 'Can you' means right now!",
                    "question_type": "confusing_pair"
                },
            ],
            "medium": [
                # Academic words with context
                {
                    "question": "Scientists need to _____ the results carefully.",
                    "sentence_context": "Scientists need to examine the results carefully.",
                    "target_word": "examine",
                    "options": ["🔬 look at closely and study", "🏃 run away from", "😴 ignore", "🎨 paint"],
                    "correct_answer": "🔬 look at closely and study",
                    "explanation": "Examine means to look at something very carefully to understand it better.",
                    "question_type": "context"
                },
                {
                    "question": "Please _____ why you chose that answer.",
                    "sentence_context": "Please explain why you chose that answer.",
                    "target_word": "explain",
                    "options": ["💬 make something clear", "🤫 keep it secret", "❌ refuse to answer", "🎮 play a game"],
                    "correct_answer": "💬 make something clear",
                    "explanation": "Explain means to make something easier to understand by giving details.",
                    "question_type": "context"
                },
                {
                    "question": "Let's _____ these two stories.",
                    "sentence_context": "Let's compare these two stories.",
                    "target_word": "compare",
                    "options": ["🔄 see how they are alike or different", "📝 write a new story", "🎭 act them out", "🗑️ throw them away"],
                    "correct_answer": "🔄 see how they are alike or different",
                    "explanation": "Compare means to look at two things and see what is the same or different about them.",
                    "question_type": "context"
                },
                # Medium confusing pairs
                {
                    "question": "Choose the correct word: _____ going to the movies tonight.",
                    "confusing_pair": ["their", "there", "they're"],
                    "options": ["Their", "There", "They're"],
                    "correct_answer": "They're",
                    "explanation": "'They're' is short for 'they are'. 'Their' shows ownership, and 'there' is a place.",
                    "question_type": "confusing_pair"
                },
                {
                    "question": "Choose the correct word: Put the book over _____.",
                    "confusing_pair": ["their", "there", "they're"],
                    "options": ["their", "there", "they're"],
                    "correct_answer": "there",
                    "explanation": "'There' tells us about a place or location. 'Their' shows ownership, and 'they're' means 'they are'.",
                    "question_type": "confusing_pair"
                },
                {
                    "question": "Choose the correct word: The loud music will _____ my concentration.",
                    "confusing_pair": ["affect", "effect"],
                    "options": ["affect", "effect"],
                    "correct_answer": "affect",
                    "explanation": "'Affect' is an action (a verb) - it means to influence something. 'Effect' is the result (a noun).",
                    "question_type": "confusing_pair"
                },
                {
                    "question": "Choose the correct word: Please _____ my apology.",
                    "confusing_pair": ["accept", "except"],
                    "options": ["accept", "except"],
                    "correct_answer": "accept",
                    "explanation": "'Accept' means to receive or agree to something. 'Except' means leaving something out.",
                    "question_type": "confusing_pair"
                },
            ],
            "hard": [
                # Complex academic words with context
                {
                    "question": "The athlete showed great _____ by continuing to train despite the injury.",
                    "sentence_context": "The athlete showed great perseverance by continuing to train despite the injury.",
                    "target_word": "perseverance",
                    "options": ["💪 continuing despite difficulties", "😢 giving up easily", "😴 being lazy", "🏃 running fast"],
                    "correct_answer": "💪 continuing despite difficulties",
                    "explanation": "Perseverance means continuing to work hard even when things are difficult or challenging.",
                    "question_type": "context"
                },
                {
                    "question": "Good teachers show _____ when students struggle.",
                    "sentence_context": "Good teachers show empathy when students struggle.",
                    "target_word": "empathy",
                    "options": ["❤️ understanding others' feelings", "😠 getting angry", "🤷 not caring", "😴 being tired"],
                    "correct_answer": "❤️ understanding others' feelings",
                    "explanation": "Empathy means understanding and sharing the feelings of another person.",
                    "question_type": "context"
                },
                {
                    "question": "The poem had a _____ meaning that made us think deeply.",
                    "sentence_context": "The poem had a profound meaning that made us think deeply.",
                    "target_word": "profound",
                    "options": ["🧠 very deep or intense", "😐 simple", "🤔 confusing", "📄 short"],
                    "correct_answer": "🧠 very deep or intense",
                    "explanation": "Profound means having deep meaning or great importance that makes you think carefully.",
                    "question_type": "context"
                },
                # Advanced confusing pairs
                {
                    "question": "Choose the correct word: The new policy will have a positive _____ on students.",
                    "confusing_pair": ["affect", "effect"],
                    "options": ["affect", "effect"],
                    "correct_answer": "effect",
                    "explanation": "'Effect' is a noun meaning the result of something. 'Affect' is a verb meaning to influence.",
                    "question_type": "confusing_pair"
                },
                {
                    "question": "Choose the correct word: Everyone is invited _____ John.",
                    "confusing_pair": ["accept", "except"],
                    "options": ["accept", "except"],
                    "correct_answer": "except",
                    "explanation": "'Except' means excluding or leaving out. 'Accept' means to receive willingly.",
                    "question_type": "confusing_pair"
                },
                {
                    "question": "Choose the correct word: Please be _____ in the library.",
                    "confusing_pair": ["quiet", "quite"],
                    "options": ["quiet", "quite"],
                    "correct_answer": "quiet",
                    "explanation": "'Quiet' means making little noise. 'Quite' means very or completely.",
                    "question_type": "confusing_pair"
                },
                {
                    "question": "Choose the correct word: I can't _____ the noise anymore.",
                    "confusing_pair": ["bear", "bare"],
                    "options": ["bear", "bare"],
                    "correct_answer": "bear",
                    "explanation": "'Bear' means to tolerate or endure. 'Bare' means uncovered or empty.",
                    "question_type": "confusing_pair"
                },
            ]
        }
    
    def generate_question(self, difficulty: str = "easy") -> Dict:
        """
        Generate a vocabulary question based on difficulty level.
        
        Args:
            difficulty: One of 'easy', 'medium', or 'hard'
            
        Returns:
            Dictionary containing question, options, correct answer, and explanation
        """
        # Validate difficulty level
        if difficulty not in self.question_bank:
            difficulty = "easy"
        
        # Select a random question from the difficulty level
        questions = self.question_bank[difficulty]
        question_data = random.choice(questions)
        
        # Shuffle options to randomize answer positions
        options = question_data["options"].copy()
        random.shuffle(options)
        
        return {
            "question": question_data["question"],
            "options": options,
            "correct_answer": question_data["correct_answer"],
            "explanation": question_data["explanation"],
            "difficulty": difficulty
        }
    
    def add_question(self, difficulty: str, question_data: Dict):
        """
        Add a new question to the question bank.
        
        Args:
            difficulty: Difficulty level
            question_data: Dictionary containing question details
        """
        if difficulty not in self.question_bank:
            self.question_bank[difficulty] = []
        
        self.question_bank[difficulty].append(question_data)
    
    # For future integration with LLM APIs:
    def generate_ai_question(self, difficulty: str, topic: str = None) -> Dict:
        """
        Generate a vocabulary question using an AI model (placeholder).
        In production, this would call OpenAI, Claude, or another LLM API.
        
        Args:
            difficulty: Difficulty level
            topic: Optional topic for the question
            
        Returns:
            Generated question data
        """
        # Placeholder for AI integration
        # In production, you would:
        # 1. Create a prompt for the LLM
        # 2. Call the API (OpenAI, Claude, etc.)
        # 3. Parse the response
        # 4. Return formatted question data
        
        # For now, use the question bank
        return self.generate_question(difficulty)
