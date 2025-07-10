from flask import Flask, render_template, request, flash
import re
import logging
from youtube_transcript_api import (
    YouTubeTranscriptApi, TranscriptsDisabled, VideoUnavailable, NoTranscriptFound
)

app = Flask(__name__)
app.secret_key = 'your_secret_key'

logging.basicConfig(level=logging.INFO)

class InvalidYouTubeURL(Exception):
    """Excepción para indicar que la URL de YouTube es inválida."""


class TranscriptNotAvailable(Exception):
    """Excepción para indicar que no se pudo obtener la transcripción."""


class YouTubeScraper:
    """
    Clase que encapsula la lógica para extraer el ID del video de YouTube
    y obtener su transcripción en texto.
    """
    def __init__(self, url):
        """
        Inicializa el scraper con la URL del video.
        Lanza InvalidYouTubeURL si la URL no es válida.
        """
        self.url = url
        self.video_id = self.extract_video_id(url)

    def extract_video_id(self, url):
        """
        Extrae el ID del video de una URL de YouTube.
        Lanza InvalidYouTubeURL si no puede extraer el ID.
        """
        youtube_regex = (
            r'(https?://)?(www\.)?'
            r'(youtube|youtu|youtube-nocookie)\.(com|be)/'
            r'(watch\?v=|embed/|v/|.+\?v=)?([^&=%\?]{11})'
        )
        match = re.match(youtube_regex, url)
        if match:
            return match.group(6)
        else:
            raise InvalidYouTubeURL("La URL proporcionada no es un enlace válido de YouTube.")

    def get_transcript(self):
        """
        Intenta obtener la transcripción del video en español.
        Si no está disponible, intenta en inglés.
        Si no hay transcripciones, levanta TranscriptNotAvailable.
        """
        try:
            # Intentamos primero en español
            transcript = YouTubeTranscriptApi.get_transcript(self.video_id, languages=['es'])
        except NoTranscriptFound:
            # Si no hay en español, intentamos en inglés
            try:
                transcript = YouTubeTranscriptApi.get_transcript(self.video_id, languages=['en'])
            except NoTranscriptFound:
                raise TranscriptNotAvailable("No se encontraron transcripciones para este video.")
        except TranscriptsDisabled:
            raise TranscriptNotAvailable("Los subtítulos/transcripciones están deshabilitados para este video.")
        except VideoUnavailable:
            raise TranscriptNotAvailable("El video no está disponible.")
        except Exception as e:
            # Cualquier otro error inesperado lo enviamos como TranscriptNotAvailable
            raise TranscriptNotAvailable(f"Error inesperado al obtener la transcripción: {e}")

        # Si llegamos aquí, tenemos un transcript
        transcript_text = " ".join([entry['text'] for entry in transcript])
        return transcript_text


@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        url = request.form.get('url', '').strip()
        if not url:
            flash("Por favor, ingresa la URL de un video de YouTube.", "warning")
            return render_template('index.html')

        try:
            scraper = YouTubeScraper(url)
            transcript = scraper.get_transcript()
            return render_template('index.html', transcript=transcript)
        except InvalidYouTubeURL as e:
            flash(str(e), "danger")
            logging.error(f"URL inválida: {url}")
        except TranscriptNotAvailable as e:
            flash(str(e), "danger")
            logging.info(f"Transcripción no disponible para el video del URL: {url}")
        except Exception as e:
            flash("Ocurrió un error inesperado. Por favor, inténtalo más tarde.", "danger")
            logging.error(f"Error inesperado: {str(e)}")

    return render_template('index.html')


import os

if __name__ == '__main__':
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)

