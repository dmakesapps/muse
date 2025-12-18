import os
import re
import time
from pathlib import Path

# --- CONFIGURATION ---
API_KEYclient = OpenAI(api_key="YOUR_API_KEY_HERE")
OUTPUT_FILENAME = "manifest_5min.mp3"
MODEL = "tts-1-hd"
VOICE = "nova"
SPEED = 0.9

# --- SCRIPT TEXT ---
SCRIPT_TEXT = """
[Background Music: Gentle, ethereal, calming synth pad music begins softly and continues throughout, fading out at the end.]

**Narrator:** Welcome. In these next five minutes, we'll align with your deepest desires.
(Short Pause: ~2s)

Before we begin, just settle your body wherever you are.
(Pause: 3 seconds)
Take a slow, deep breath in through your nose, filling your lungs completely.
(Pause: 4 seconds)
And exhale slowly through your mouth, releasing any tension you might be holding.
(Pause: 5 seconds)

Feel your body relaxing, becoming present, right here, right now, in this powerful moment.
(Pause: 6 seconds)

Now, bring to mind one clear, desired outcome.
(Short Pause: ~2s)
Don’t concern yourself with the 'how' or the 'when' right now.
(Pause: 3 seconds)
Simply focus on 'what' you truly want to experience.
(Pause: 4 seconds)
What is that wonderful reality you wish to embody?
(Pause: 5 seconds)
Allow a clear image or a pure knowing of it to form in your mind.
(Medium Pause: ~5s)

Here is the secret: Begin to *feel* it as if it is already accomplished.
(Pause: 4 seconds)
What emotions would flood through you if this desire were a present reality, right now?
(Short Pause: ~2s)
Is it joy? Freedom? Deep peace? Abundance? Love?
(Pause: 6 seconds)

Allow those feelings to wash over you.
(Short Pause: ~2s)
Don't just think about them; truly *experience* them.
(Pause: 4 seconds)
Feel them in every cell of your being, from the top of your head to the tips of your toes.
(Pause: 7 seconds)
Imagine that wonderful feeling is already real, here, now. Live from this end.
(Long Pause: ~10s)

Breathe into that feeling. Let it expand.
(Pause: 4 seconds)
You are not waiting for this feeling; you are actively generating it from within your own being.
(Pause: 8 seconds)

Hold onto this profound sense of the wish fulfilled.
(Pause: 5 seconds)
See it, not in your future, but as your present experience.
(Pause: 7 seconds)

Take one last deep breath, fully embodying this feeling of completion and deep gratitude.
(Pause: 5 seconds)
As you exhale, silently affirm within your heart: "I am grateful this is done."
(Medium Pause: ~5s)

Now, gently bring your awareness back to your surroundings.
(Short Pause: ~2s)
Carry this feeling of completion and fulfillment with you throughout your day.
(Pause: 4 seconds)
Trust the invisible intelligence to arrange the 'how'.
(Short Pause: ~2s)
You are a powerful creator.

[Background Music continues gently, then slowly fades out over 10 seconds.]
"""

# --- DEPENDENCY CHECK ---
try:
    from openai import OpenAI
    from pydub import AudioSegment
except ImportError:
    print("❌ API Error: Missing dependencies.")
    print("Please run this command in your terminal to install them:")
    print("pip install openai pydub")
    exit(1)

# Check for ffmpeg (required for pydub)
import shutil
if not shutil.which("ffmpeg"):
    print("⚠️ Warning: 'ffmpeg' not found on system path.")
    print("pydub requires ffmpeg to save mp3s.")
    print("If the script fails, please install it (e.g., 'brew install ffmpeg').")

# --- MAIN LOGIC ---

def clean_text(text):
    """Remove [Bracketed] instructions and **Narrator:** tags."""
    text = re.sub(r'\[.*?\]', '', text) # Remove [Notes]
    text = re.sub(r'\*\*Narrator:\*\*', '', text) # Remove **Narrator:**
    return text

def parse_duration(pause_str):
    """Extract seconds from strings like '(Pause: 4 seconds)' or '(Short Pause: ~2s)'"""
    # Look for digits
    match = re.search(r'(\d+)', pause_str)
    if match:
        return int(match.group(1))
    return 1 # Default to 1 second if parsing fails

def generate():
    print("🎙️ Initializing OpenAI Client...")
    client = OpenAI(api_key=API_KEY)
    
    # Clean the script first
    raw_script = clean_text(SCRIPT_TEXT)
    
    # Split by pause logic
    # Regex finds the pause blocks like (Pause: 5 seconds)
    # capturing the group keeps it in the split list
    segments = re.split(r'(\(.*Pause.*?\))', raw_script)
    
    final_audio = AudioSegment.empty()
    
    print("\n🚀 Starting generation...")
    
    for i, segment in enumerate(segments):
        segment = segment.strip()
        if not segment:
            continue
            
        # Check if it's a pause instruction
        if "Pause" in segment and "(" in segment and ")" in segment:
            duration = parse_duration(segment)
            print(f"   Generating Silence: {duration}s")
            silence = AudioSegment.silent(duration=duration * 1000) # pydub uses ms
            final_audio += silence
        else:
            # It's spoken text
            print(f"   Speaking: \"{segment[:30]}...\"")
            
            try:
                response = client.audio.speech.create(
                    model=MODEL,
                    voice=VOICE,
                    speed=SPEED,
                    input=segment
                )
                
                # Save temp file
                temp_filename = f"temp_{i}.mp3"
                response.stream_to_file(temp_filename)
                
                # Load into pydub
                segment_audio = AudioSegment.from_mp3(temp_filename)
                final_audio += segment_audio
                
                # Cleanup temp file
                os.remove(temp_filename)
                
            except Exception as e:
                print(f"❌ Error generating segment: {e}")
                exit(1)
                
    print("\n💾 Exporting final MP3...")
    final_audio.export(OUTPUT_FILENAME, format="mp3", bitrate="192k")
    print(f"✅ Success! File saved to: {os.path.abspath(OUTPUT_FILENAME)}")

if __name__ == "__main__":
    generate()
