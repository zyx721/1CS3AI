# app.py
import asyncio
import os
import pyaudio
from dotenv import load_dotenv
import google.generativeai as genai
from google.generativeai import types
from aiohttp import web
from aiohttp_cors import setup as cors_setup, ResourceOptions
import json
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- WebSocket and State Management ---
clients = set()
current_state = "idle"
conversation_active = False
conversation_task = None
audio_system = None

async def notify_clients(state):
    """Sends the new state to all connected WebSocket clients."""
    global current_state
    if current_state != state:
        current_state = state
        logger.info(f"STATE CHANGE: {state}")
        if clients:
            message = json.dumps({
                "state": state, 
                "timestamp": time.time(),
                "active": conversation_active
            })
            disconnected_clients = set()
            for ws in clients:
                try:
                    await ws.send_str(message)
                except Exception as e:
                    logger.error(f"Error sending to client: {e}")
                    disconnected_clients.add(ws)
            # Remove disconnected clients
            clients.difference_update(disconnected_clients)

# --- Audio System Class ---
class AudioSystem:
    def __init__(self):
        self.pa = None
        self.mic = None
        self.speaker = None
        
    def initialize(self):
        """Initialize PyAudio system"""
        try:
            self.pa = pyaudio.PyAudio()
            
            # List available audio devices for debugging
            logger.info("Available audio devices:")
            for i in range(self.pa.get_device_count()):
                info = self.pa.get_device_info_by_index(i)
                logger.info(f"  {i}: {info['name']} - {info['maxInputChannels']} in, {info['maxOutputChannels']} out")
            
            # Initialize microphone
            self.mic = self.pa.open(
                format=pyaudio.paInt16,
                channels=1,
                rate=16000,
                input=True,
                frames_per_buffer=1600,
                input_device_index=None  # Use default
            )
            
            # Initialize speaker
            self.speaker = self.pa.open(
                format=pyaudio.paInt16,
                channels=1,
                rate=24000,
                output=True,
                frames_per_buffer=2400,
                output_device_index=None  # Use default
            )
            
            logger.info("Audio system initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize audio system: {e}")
            self.cleanup()
            return False
    
    def cleanup(self):
        """Cleanup audio resources"""
        if self.mic:
            try:
                self.mic.stop_stream()
                self.mic.close()
            except:
                pass
            self.mic = None
            
        if self.speaker:
            try:
                self.speaker.stop_stream()
                self.speaker.close()
            except:
                pass
            self.speaker = None
            
        if self.pa:
            try:
                self.pa.terminate()
            except:
                pass
            self.pa = None

# --- aiohttp Handlers ---
async def websocket_handler(request):
    """Handles WebSocket connections for real-time state updates."""
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    clients.add(ws)
    logger.info("🟢 Client connected")
    
    # Send the initial state
    initial_message = json.dumps({
        "state": current_state,
        "timestamp": time.time(),
        "active": conversation_active
    })
    await ws.send_str(initial_message)
    
    try:
        async for msg in ws:
            if msg.type == web.WSMsgType.TEXT:
                try:
                    data = json.loads(msg.data)
                    command = data.get('command')
                    
                    if command == 'start':
                        await start_conversation()
                    elif command == 'stop':
                        await stop_conversation()
                        
                except json.JSONDecodeError:
                    logger.error(f"Invalid JSON received: {msg.data}")
            elif msg.type == web.WSMsgType.ERROR:
                logger.error(f'WebSocket error: {ws.exception()}')
    except Exception as e:
        logger.error(f"WebSocket handler error: {e}")
    finally:
        clients.discard(ws)
        logger.info("🔴 Client disconnected")

    return ws

async def start_conversation():
    """Start the voice conversation"""
    global conversation_active, conversation_task, audio_system
    
    if conversation_active:
        logger.info("Conversation already active")
        return {"status": "already_active"}
    
    # Initialize audio system
    audio_system = AudioSystem()
    if not audio_system.initialize():
        await notify_clients("error")
        return {"status": "audio_error", "message": "Failed to initialize audio system"}
    
    conversation_active = True
    await notify_clients("connecting")
    
    # Start the conversation task
    conversation_task = asyncio.create_task(run_gemini_conversation())
    
    return {"status": "started"}

async def stop_conversation():
    """Stop the voice conversation"""
    global conversation_active, conversation_task, audio_system
    
    if not conversation_active:
        return {"status": "not_active"}
    
    conversation_active = False
    
    if conversation_task and not conversation_task.done():
        conversation_task.cancel()
        try:
            await conversation_task
        except asyncio.CancelledError:
            pass
    
    if audio_system:
        audio_system.cleanup()
        audio_system = None
    
    await notify_clients("idle")
    logger.info("Conversation stopped")
    
    return {"status": "stopped"}

# --- Gemini Conversation Logic ---
async def run_gemini_conversation():
    """Main conversation loop with Gemini"""
    global conversation_active, audio_system
    
    # Load environment variables
    load_dotenv()
    API_KEY = os.getenv("GOOGLE_API_KEY")
    if not API_KEY:
        logger.error("GOOGLE_API_KEY not found in .env file")
        await notify_clients("error")
        return

    MODEL = "gemini-2.0-flash-live-001"
    SEND_DURATION_SEC = 5
    RESPONSE_SILENCE_TIMEOUT = 2.0
    INITIAL_PROMPT_DELAY = 1.0
    
    SYSTEM_INSTRUCTION = types.Content(
        parts=[
            types.Part(
                text=(
                    "You are a professional sales representative. Follow these instructions exactly:\n\n"
                    "1. Begin the conversation ONLY with: \"Hello, am I speaking with someone from Smith and Company?\" Do not add any other text to your first response.\n"
                    "2. Listen to their responses and ask relevant follow‑up questions about their current IT setup or challenges.\n"
                    "3. Keep your responses concise, professional, and friendly. Aim for 2‑3 short sentences, suitable for a spoken conversation.\n"
                    "4. Do not reveal you are an AI unless specifically asked. Sound human and conversational.\n"
                    "5. Focus on understanding their business needs and IT challenges."
                )
            )
        ]
    )

    config = types.LiveConnectConfig(
        response_modalities=["AUDIO"],
        system_instruction=SYSTEM_INSTRUCTION,
        speech_config=types.SpeechConfig(
            voice_config=types.VoiceConfig(
                prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name="Puck")
            )
        ),
        realtime_input_config=types.RealtimeInputConfig(
            automatic_activity_detection=types.AutomaticActivityDetection(
                start_of_speech_sensitivity=types.StartSensitivity.START_SENSITIVITY_LOW,
                end_of_speech_sensitivity=types.EndSensitivity.END_SENSITIVITY_LOW,
                silence_duration_ms=500
            )
        )
    )

    try:
        client = genai.Client(api_key=API_KEY)
        logger.info("🟢 Starting Gemini conversation")

        async with client.aio.live.connect(model=MODEL, config=config) as session:
            # Initial prompt to start the conversation
            await session.send_client_content(
                turns=[{"role": "user", "parts": [{"text": "Start the conversation"}]}],
                turn_complete=True
            )
            await asyncio.sleep(INITIAL_PROMPT_DELAY)

            async def send_audio_turn():
                """Capture and send user audio"""
                if not conversation_active or not audio_system or not audio_system.mic:
                    return
                    
                await notify_clients("user")
                logger.info("🎤 Listening...")
                start_time = asyncio.get_event_loop().time()
                
                try:
                    while conversation_active:
                        elapsed = asyncio.get_event_loop().time() - start_time
                        if elapsed > SEND_DURATION_SEC:
                            logger.info("🛑 Finished listening")
                            break
                        
                        try:
                            frame = audio_system.mic.read(1600, exception_on_overflow=False)
                            await session.send_realtime_input(
                                audio=types.Blob(data=frame, mime_type="audio/pcm;rate=16000")
                            )
                        except Exception as e:
                            logger.error(f"Audio send error: {e}")
                            break
                        
                        await asyncio.sleep(0.01)
                except Exception as e:
                    logger.error(f"Error in send_audio_turn: {e}")

            async def receive_audio_turn():
                """Receive and play agent's response"""
                if not conversation_active:
                    return
                    
                logger.info("🔊 Processing response...")
                await notify_clients("idle")
                last_audio_time = asyncio.get_event_loop().time()
                speaking = False
                response_started = False
                
                try:
                    async for msg in session.receive():
                        if not conversation_active:
                            break
                            
                        if msg.data and audio_system and audio_system.speaker:
                            if not response_started:
                                await notify_clients("agent")
                                logger.info("💬 Agent speaking...")
                                response_started = True
                            try:
                                audio_system.speaker.write(msg.data)
                                last_audio_time = asyncio.get_event_loop().time()
                                speaking = True
                            except Exception as e:
                                logger.error(f"Audio playback error: {e}")
                                break
                        
                        if msg.server_content and getattr(msg.server_content, 'interrupted', False):
                            logger.info("⏹️ Response interrupted")
                            break
                        
                        now = asyncio.get_event_loop().time()
                        if speaking and now - last_audio_time > RESPONSE_SILENCE_TIMEOUT:
                            break
                    
                    if response_started:
                        logger.info("✅ Agent finished speaking")
                        await notify_clients("idle")
                        
                except Exception as e:
                    logger.error(f"Error in receive_audio_turn: {e}")

            # Start with agent response
            await receive_audio_turn()
            
            # Main conversation loop
            while conversation_active:
                try:
                    await send_audio_turn()
                    if conversation_active:
                        await receive_audio_turn()
                except asyncio.CancelledError:
                    break
                except Exception as e:
                    logger.error(f"Error in conversation loop: {e}")
                    break

    except Exception as e:
        logger.error(f"Gemini conversation error: {e}")
        await notify_clients("error")
    finally:
        if audio_system:
            audio_system.cleanup()
        await notify_clients("idle")
        logger.info("✅ Conversation ended")

# --- Main Application Setup ---
async def init_app():
    """Initialize the web application"""
    app = web.Application()
    
    # Setup CORS for Flutter
    cors = cors_setup(app, defaults={
        "*": ResourceOptions(
            allow_credentials=True,
            expose_headers="*",
            allow_headers="*",
            allow_methods="*"
        )
    })
    
    # Add routes
    app.router.add_get('/ws', websocket_handler)
    
    # Add CORS to all routes
    for route in list(app.router.routes()):
        cors.add(route)
    
    return app

async def main():
    """Main entry point"""
    app = await init_app()
    
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '192.168.100.5', 8080)
    await site.start()
    
    logger.info("🚀 Voice Chat Server running at ws://192.168.100.5:8080/ws")
    logger.info("Ready for Flutter client connections...")
    
    # Keep the server running
    try:
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        logger.info("Shutting down server...")
    finally:
        await stop_conversation()
        await runner.cleanup()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user.")
    except Exception as e:
        print(f"\n❌ Server error: {e}")