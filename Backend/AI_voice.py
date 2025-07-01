

import asyncio
import os
import pyaudio
from google import genai
from dotenv import load_dotenv


client = genai.Client(api_key="AIzaSyBz_1yYajRX8ZNVHoUynStuY3FzN922dtk")


FORMAT = pyaudio.paInt16
CHANNELS = 1
SEND_SAMPLE_RATE = 16000
RECEIVE_SAMPLE_RATE = 24000
CHUNK_SIZE = 1024
MODEL = "gemini-2.5-flash-preview-native-audio-dialog"

SYSTEM_PROMPT = (
    """You are a professional sales representative. Follow these instructions exactly:

1 Start only with: "Hello, am I speaking with someone from SellGem Company?"
2 briefly intrduce yourself as someone who has a solution that can help thier business grow.
3 try to talk about thier pain points and challenges.
Keep replies short, friendly, and professional (2–3 spoken-style sentences).
do not talk for long time try to let the user talk
Do not mention you are an AI unless asked. Stay natural and human-like.
if user tells you sign me in you iwll tell him that you done and you will redirect and he will get an email for the details 
Your goal: Convince them to try our service — an affordable AI sales agent that finds potential clients and does the outreach for them, saving time and boosting sales.

Context: The person you're speaking to is Fares Abdi, a startup founder who built an innovative solution but struggles with outreach and cold calls. Hiring sales staff is too expensive for his bootstrapped business. Our service solves that.

"""
)

pya = pyaudio.PyAudio()

class AudioAgent:
    def __init__(self):
        self.audio_in_queue = asyncio.Queue()
        self.out_queue = asyncio.Queue(maxsize=5)
        self.session = None
        self.audio_stream = None

    async def listen_audio(self):
        mic_info = pya.get_default_input_device_info()
        self.audio_stream = await asyncio.to_thread(
            pya.open,
            format=FORMAT,
            channels=CHANNELS,
            rate=SEND_SAMPLE_RATE,
            input=True,
            input_device_index=mic_info["index"],
            frames_per_buffer=CHUNK_SIZE,
        )
        while True:
            data = await asyncio.to_thread(self.audio_stream.read, CHUNK_SIZE, exception_on_overflow=False)
            await self.out_queue.put({"data": data, "mime_type": "audio/pcm"})

    async def receive_audio(self):
        while True:
            turn = self.session.receive()
            async for response in turn:
                if response.data:
                    self.audio_in_queue.put_nowait(response.data)
                elif response.text:
                    print(f"📨 Agent said: {response.text}", end="")

            while not self.audio_in_queue.empty():
                self.audio_in_queue.get_nowait()

    async def play_audio(self):
        stream = await asyncio.to_thread(
            pya.open,
            format=FORMAT,
            channels=CHANNELS,
            rate=RECEIVE_SAMPLE_RATE,
            output=True,
        )
        while True:
            bytestream = await self.audio_in_queue.get()
            await asyncio.to_thread(stream.write, bytestream)

    async def send_realtime(self):
        while True:
            msg = await self.out_queue.get()
            await self.session.send(input=msg)

    async def run(self):
        try:
            config = {
                "response_modalities": ["AUDIO"],
                "tools": [],
                "system_instruction": SYSTEM_PROMPT,
            }
            
            async with client.aio.live.connect(model=MODEL, config=config) as session, asyncio.TaskGroup() as tg:
                self.session = session

                print("🟢 Connected to Gemini Live API")
                print("🎤 Speak into your microphone...\n")

                tg.create_task(self.listen_audio())
                tg.create_task(self.send_realtime())
                tg.create_task(self.receive_audio())
                tg.create_task(self.play_audio())

                await asyncio.Event().wait()  

        except Exception as e:
            if self.audio_stream:
                self.audio_stream.close()
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(AudioAgent().run())