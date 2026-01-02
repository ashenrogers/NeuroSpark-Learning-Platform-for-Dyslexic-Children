import random
from typing import Dict, List

class VocabularyGenerator:
    """
    Generates vocabulary questions with multiple choice answers.
    In a production environment, this would integrate with an LLM API like OpenAI or Claude.
    For this demo, we use a pre-defined question bank.
    """
    
    def __init__(self):
        # Question bank organized by difficulty
        self.question_bank = {
            "easy": [
                {
                    "question": "What is the meaning of 'happy'?",
                    "options": ["Feeling joy", "Feeling sad", "Feeling angry", "Feeling tired"],
                    "correct_answer": "Feeling joy",
                    "explanation": "Happy means feeling pleasure and contentment."
                },
                {
                    "question": "What does 'big' mean?",
                    "options": ["Large in size", "Small in size", "Medium size", "No size"],
                    "correct_answer": "Large in size",
                    "explanation": "Big means of considerable size or extent."
                },
                {
                    "question": "What is a 'friend'?",
                    "options": ["Someone you know and like", "A stranger", "An enemy", "A teacher"],
                    "correct_answer": "Someone you know and like",
                    "explanation": "A friend is a person with whom you have a bond of mutual affection."
                },
                {
                    "question": "What does 'fast' mean?",
                    "options": ["Moving quickly", "Moving slowly", "Not moving", "Moving backwards"],
                    "correct_answer": "Moving quickly",
                    "explanation": "Fast means moving or capable of moving at high speed."
                },
                {
                    "question": "What is 'water'?",
                    "options": ["A clear liquid we drink", "A solid food", "A type of air", "A color"],
                    "correct_answer": "A clear liquid we drink",
                    "explanation": "Water is a clear liquid that is essential for life."
                },
            ],
            "medium": [
                {
                    "question": "What does 'curious' mean?",
                    "options": ["Eager to learn", "Not interested", "Sleepy", "Hungry"],
                    "correct_answer": "Eager to learn",
                    "explanation": "Curious means having a desire to learn or know about something."
                },
                {
                    "question": "What is 'courage'?",
                    "options": ["Bravery in facing danger", "Being afraid", "Running away", "Hiding"],
                    "correct_answer": "Bravery in facing danger",
                    "explanation": "Courage is the ability to do something that frightens you."
                },
                {
                    "question": "What does 'ancient' mean?",
                    "options": ["Very old", "Brand new", "Medium aged", "Future"],
                    "correct_answer": "Very old",
                    "explanation": "Ancient means belonging to the very distant past."
                },
                {
                    "question": "What is 'harmony'?",
                    "options": ["Things working well together", "Conflict", "Noise", "Silence"],
                    "correct_answer": "Things working well together",
                    "explanation": "Harmony is a pleasing arrangement or agreement."
                },
                {
                    "question": "What does 'grateful' mean?",
                    "options": ["Feeling thankful", "Feeling angry", "Feeling bored", "Feeling scared"],
                    "correct_answer": "Feeling thankful",
                    "explanation": "Grateful means feeling or showing appreciation for something."
                },
            ],
            "hard": [
                {
                    "question": "What does 'perseverance' mean?",
                    "options": ["Continuing despite difficulties", "Giving up easily", "Being lazy", "Avoiding work"],
                    "correct_answer": "Continuing despite difficulties",
                    "explanation": "Perseverance means persistence in doing something despite difficulty."
                },
                {
                    "question": "What is 'empathy'?",
                    "options": ["Understanding others' feelings", "Ignoring others", "Being selfish", "Being cruel"],
                    "correct_answer": "Understanding others' feelings",
                    "explanation": "Empathy is the ability to understand and share the feelings of another."
                },
                {
                    "question": "What does 'profound' mean?",
                    "options": ["Very deep or intense", "Shallow", "Simple", "Ordinary"],
                    "correct_answer": "Very deep or intense",
                    "explanation": "Profound means having deep insight or great significance."
                },
                {
                    "question": "What is 'resilience'?",
                    "options": ["Ability to recover from difficulties", "Weakness", "Fragility", "Confusion"],
                    "correct_answer": "Ability to recover from difficulties",
                    "explanation": "Resilience is the capacity to recover quickly from difficulties."
                },
                {
                    "question": "What does 'eloquent' mean?",
                    "options": ["Speaking fluently and persuasively", "Unable to speak", "Speaking rudely", "Whispering"],
                    "correct_answer": "Speaking fluently and persuasively",
                    "explanation": "Eloquent means fluent or persuasive in speaking or writing."
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
