import asyncio
import os
import pyaudio
from dotenv import load_dotenv

from google import genai
from google.genai.types import LiveConnectConfig, SpeechConfig, VoiceConfig, PrebuiltVoiceConfig

# Load API key
load_dotenv()
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise ValueError("GOOGLE_API_KEY not found in .env file")

# Config
MODEL = "gemini-2.0-flash-live-001"
FORMAT = pyaudio.paInt16
CHANNELS = 1
IN_RATE = 16000
OUT_RATE = 24000
CHUNK = int(IN_RATE * 0.1)  # 100ms frames
SEND_DURATION_SEC = 5       # how long user can speak per turn
RESPONSE_SILENCE_TIMEOUT = 2.0

async def main():
    config = LiveConnectConfig(
        response_modalities=["AUDIO"],
        speech_config=SpeechConfig(
            voice_config=VoiceConfig(
                prebuilt_voice_config=PrebuiltVoiceConfig(voice_name="puck")
            )
        )
    )

    client = genai.Client(api_key=API_KEY)
    pa = pyaudio.PyAudio()

    mic = pa.open(format=FORMAT, channels=CHANNELS, rate=IN_RATE,
                  input=True, frames_per_buffer=CHUNK)
    speaker = pa.open(format=FORMAT, channels=CHANNELS, rate=OUT_RATE,
                      output=True)

    print("🟢 Live connection ready. Start speaking.")

    async with client.aio.live.connect(model=MODEL, config=config) as sess:

        async def send_audio_turn():
            print("🎤 Sending audio for this turn...")
            start_time = asyncio.get_event_loop().time()
            while True:
                if asyncio.get_event_loop().time() - start_time > SEND_DURATION_SEC:
                    print("🛑 Done sending this turn.")
                    break
                frame = mic.read(CHUNK, exception_on_overflow=False)
                await sess.send(input={"data": frame, "mime_type": "audio/pcm"})
                await asyncio.sleep(0.01)

        async def receive_audio_turn():
            print("🔊 Waiting for Gemini response...")
            last_audio_time = asyncio.get_event_loop().time()
            speaking = False

            async for msg in sess.receive():
                if msg.server_content and msg.server_content.model_turn:
                    for part in msg.server_content.model_turn.parts:
                        if part.inline_data and part.inline_data.data:
                            speaker.write(part.inline_data.data)
                            last_audio_time = asyncio.get_event_loop().time()
                            speaking = True

                now = asyncio.get_event_loop().time()
                if speaking and now - last_audio_time > RESPONSE_SILENCE_TIMEOUT:
                    print("✅ Gemini finished speaking.")
                    break

        # Main loop
        while True:
            await send_audio_turn()
            await receive_audio_turn()

    # Cleanup
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
        print("\n🛑 Interrupted by user.")
    except Exception as e:
        print(f"\n❌ Error occurred: {e}")
