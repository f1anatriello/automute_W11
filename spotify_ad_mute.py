"""
spotify-ad-mute (Windows) - muta automaticamente le pubblicita di Spotify.

Come funziona:
  - legge lo stato di riproduzione di Spotify tramite SMTC
    (System Media Transport Controls), l'API di Windows che alimenta
    anche i tasti multimediali della tastiera
  - riconosce una pubblicita quando i campi artista/album arrivano vuoti
    (Spotify non li valorizza per gli annunci)
  - muta SOLO la sessione audio di Spotify.exe tramite Core Audio (WASAPI),
    lo stesso meccanismo dietro il mixer volumi di Windows

Dipendenze:
    pip install winsdk pycaw comtypes
"""

import asyncio
import sys
import time

from pycaw.pycaw import AudioUtilities
from winsdk.windows.media.control import (
    GlobalSystemMediaTransportControlsSessionManager as MediaManager,
)

POLL_SECONDS = 1.0
SPOTIFY_PROCESS_NAME = "spotify.exe"
SPOTIFY_APP_ID_HINT = "spotify"


def log(msg: str) -> None:
    print(f"{time.strftime('%H:%M:%S')} {msg}", flush=True)


async def get_spotify_session():
    """Trova, tra tutte le sessioni multimediali attive (Spotify, Chrome,
    VLC...), quella che appartiene a Spotify."""
    manager = await MediaManager.request_async()
    for session in manager.get_sessions():
        app_id = (session.source_app_user_model_id or "").lower()
        if SPOTIFY_APP_ID_HINT in app_id:
            return session
    return None


async def is_ad_playing() -> bool | None:
    """True se sta suonando una pubblicita, False se un brano normale,
    None se Spotify non e' attivo/raggiungibile."""
    session = await get_spotify_session()
    if session is None:
        return None

    info = await session.try_get_media_properties_async()
    artist = (info.artist or "").strip()
    album = (info.album_title or "").strip()

    # Spotify non valorizza artista/album per le pubblicita: e' l'euristica
    # piu' affidabile disponibile via SMTC (non c'e' un trackid come su Linux).
    return not artist or not album


def set_spotify_mute(mute: bool) -> bool:
    """Muta/smuta solo la sessione audio di Spotify.exe.
    Ritorna True se ha trovato ed agito su almeno una sessione."""
    found = False
    for session in AudioUtilities.GetAllSessions():
        proc = session.Process
        if proc and proc.name().lower() == SPOTIFY_PROCESS_NAME:
            session.SimpleAudioVolume.SetMute(1 if mute else 0, None)
            found = True
    return found


async def main() -> None:
    we_muted = False
    spotify_open = None
    log("Automute Avviato.")

    while True:
        try:
            session = await get_spotify_session()
            spotify_now = session is not None

            if spotify_open is None:
                if spotify_now:
                    log("Spotify aperto.")
                else:
                    log("Spotify chiuso.")
            elif spotify_now != spotify_open:
                if spotify_now:
                    log("Spotify aperto.")
                else:
                    log("Spotify chiuso.")

            spotify_open = spotify_now

            if session is not None:
                info = await session.try_get_media_properties_async()
                artist = (info.artist or "").strip()
                album = (info.album_title or "").strip()
                ad = not artist or not album
            else:
                ad = None
        except Exception as exc:  # SMTC a volte lancia eccezioni transitorie
            log(f"errore lettura SMTC: {exc}")
            ad = None

        if ad is True and not we_muted:
            if set_spotify_mute(True):
                log("Pubblicita' rilevata -> Mute mode")
                we_muted = True
        elif ad is False and we_muted:
            if set_spotify_mute(False):
                log("Pubblicita' finita -> Unmute mode")
            we_muted = False
        # ad is None: Spotify non attivo, non facciamo nulla

        await asyncio.sleep(POLL_SECONDS)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        sys.exit(0)
