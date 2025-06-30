import asyncio
import os
import pyaudio
from dotenv import load_dotenv
from google import genai
from google.genai.types import Blob

load_dotenv()
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise ValueError("GOOGLE_API_KEY not found in .env file")

MODEL = "gemini-2.5-flash-preview-native-audio-dialog"
FORMAT = pyaudio.paInt16
CHANNELS = 1
IN_RATE = 16000
OUT_RATE = 24000
CHUNK = int(IN_RATE * 0.1)
SEND_DURATION_SEC = 5
RESPONSE_SILENCE_TIMEOUT = 3.0  
INITIAL_PROMPT_DELAY = 1.0     

SYSTEM_INSTRUCTION = (
    "You are a professional sales representative. Follow these instructions exactly:\n\n"
    "1. Begin the conversation ONLY with: \"Hello, am I speaking with someone from Smith and Company?\" Do not add any other text to your first response.\n"
    "2. Listen to their responses and ask relevant follow‑up questions about their current IT setup or challenges.\n"
    "3. Keep your responses concise, professional, and friendly. Aim for 2‑3 short sentences, suitable for a spoken conversation.\n"
    "4. Do not reveal you are an AI unless specifically asked. Sound human and conversational.\n"
    "5. Focus on understanding their business needs and IT challenges."
)

async def main():
    config = {
        "response_modalities": ["AUDIO"],
        "system_instruction": SYSTEM_INSTRUCTION,
        "speech_config": {
            "voice_config": {
                "prebuilt_voice_config": {
                    "voice_name": "puck"
                }
            }
        },
        "realtime_input_config": {
            "automatic_activity_detection": {
                "start_of_speech_sensitivity": "START_SENSITIVITY_LOW",
                "end_of_speech_sensitivity": "END_SENSITIVITY_LOW",
                "silence_duration_ms": 500
            }
        }
    }

    client = genai.Client(api_key=API_KEY)
    pa = pyaudio.PyAudio()

    mic = pa.open(format=FORMAT, channels=CHANNELS, rate=IN_RATE,
                  input=True, frames_per_buffer=CHUNK)
    speaker = pa.open(format=FORMAT, channels=CHANNELS, rate=OUT_RATE,
                      output=True)

    print("🟢 Live connection ready. Agent will speak first.")

    async with client.aio.live.connect(model=MODEL, config=config) as sess:
        await sess.send_client_content(
            turns={"role": "user", "parts": [{"text": "Start the conversation"}]},
            turn_complete=True
        )
        await asyncio.sleep(INITIAL_PROMPT_DELAY)  # Allow model processing time

        async def send_audio_turn():
            """Capture and send user audio"""
            print("\n🎤 Listening... (Press Ctrl+C to stop)")
            start_time = asyncio.get_event_loop().time()
            frames_sent = 0
            
            while True:
                elapsed = asyncio.get_event_loop().time() - start_time
                if elapsed > SEND_DURATION_SEC:
                    print("🛑 Finished listening")
                    break
                
                try:
                    frame = mic.read(CHUNK, exception_on_overflow=False)
                    await sess.send_realtime_input(
                        audio=Blob(data=frame, mime_type="audio/pcm;rate=16000")
                    )
                    frames_sent += 1
                except Exception as e:
                    print(f"⚠️ Audio send error: {str(e)}")
                    break
                
                await asyncio.sleep(0.01)

        async def receive_audio_turn():
            """Receive and play agent's response"""
            print("🔊 Processing response...")
            last_audio_time = asyncio.get_event_loop().time()
            speaking = False
            response_started = False
            
            async for msg in sess.receive():
                if msg.data:
                    if not response_started:
                        print("💬 Agent speaking...")
                        response_started = True
                    speaker.write(msg.data)
                    last_audio_time = asyncio.get_event_loop().time()
                    speaking = True
                
                if msg.server_content and getattr(msg.server_content, 'interrupted', False):
                    print("⏹️ Response interrupted")
                    break
                
                now = asyncio.get_event_loop().time()
                if speaking and now - last_audio_time > RESPONSE_SILENCE_TIMEOUT:
                    break
            
            if response_started:
                print("✅ Agent finished speaking")

        await receive_audio_turn()  
        
        while True:
            await send_audio_turn()    
            await receive_audio_turn() 

    mic.stop_stream()
    mic.close()
    speaker.stop_stream()
    speaker.close()
    pa.terminate()
    print("✅ Cleaned up.")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n🛑 Conversation ended")
    except Exception as e:
        print(f"\n❌ Error occurred: {e}")