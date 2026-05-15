import os
import sys

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

try:
    from dotenv import load_dotenv
except ImportError:
    def load_dotenv(*args, **kwargs):
        return False

try:
    import spotipy
    from spotipy.exceptions import SpotifyException
    from spotipy.oauth2 import SpotifyOAuth
except ImportError:
    spotipy = None
    SpotifyOAuth = None

    class SpotifyException(Exception):
        pass

from context.base_provider import ContextSignal
from core.paths import project_path

SPOTIFY_SCOPE = "user-read-playback-state user-read-currently-playing"

HIGH_STIMULATION_KEYWORDS = [
    "metal",
    "rage",
    "hardstyle",
    "phonk",
    "drill",
    "aggressive",
    "trap"
]

CALM_KEYWORDS = [
    "ambient",
    "sleep",
    "focus",
    "meditation",
    "lofi",
    "piano",
    "rain",
    "calm"
]

_spotify_client = None
_spotify_config_checked = False
_spotify_configured = False


def load_spotify_env():
    load_dotenv(project_path(".env"))


def spotify_is_configured():
    global _spotify_config_checked
    global _spotify_configured

    if spotipy is None or SpotifyOAuth is None:
        _spotify_config_checked = True
        _spotify_configured = False
        return False

    if _spotify_config_checked:
        return _spotify_configured

    load_spotify_env()

    required = [
        "SPOTIFY_CLIENT_ID",
        "SPOTIFY_CLIENT_SECRET",
        "SPOTIFY_REDIRECT_URI"
    ]

    _spotify_configured = all(
        os.getenv(name)
        for name in required
    )
    _spotify_config_checked = True

    return _spotify_configured


def get_spotify_client():
    global _spotify_client

    if _spotify_client is not None:
        return _spotify_client

    if not spotify_is_configured():
        return None

    try:
        _spotify_client = spotipy.Spotify(
            auth_manager=SpotifyOAuth(
                client_id=os.getenv("SPOTIFY_CLIENT_ID"),
                client_secret=os.getenv("SPOTIFY_CLIENT_SECRET"),
                redirect_uri=os.getenv("SPOTIFY_REDIRECT_URI"),
                scope=SPOTIFY_SCOPE
            )
        )
    except Exception:
        _spotify_client = None

    return _spotify_client


def contains_any(value, keywords):
    return any(
        keyword in value
        for keyword in keywords
    )


def infer_audio_tags(track_name):
    track_name_lower = (track_name or "").lower()
    tags = ["auditory_regulation"]

    if contains_any(track_name_lower, HIGH_STIMULATION_KEYWORDS):
        tags.append("high_stimulation")

    if contains_any(track_name_lower, CALM_KEYWORDS):
        tags.append("calming")

    return tags


def calculate_intensity(tags):
    if "high_stimulation" in tags:
        return 70

    if "calming" in tags:
        return 25

    return 40


def build_spotify_context(current):
    item = current.get("item")

    if not item:
        return None

    track_name = item.get("name", "Unknown Track")
    artists = [
        artist.get("name", "Unknown Artist")
        for artist in item.get("artists", [])
    ]
    tags = infer_audio_tags(track_name)
    signal = ContextSignal(
        source="Spotify",
        context_type="Music Context",
        intensity=calculate_intensity(tags),
        duration=0,
        tags=tags
    )

    return {
        "track": track_name,
        "artists": artists,
        "is_playing": current.get("is_playing", False),
        "signal": signal.to_dict()
    }


def get_spotify_context():
    client = get_spotify_client()

    if not client:
        return None

    try:
        current = client.current_playback()
    except (SpotifyException, OSError):
        return None
    except Exception:
        return None

    if not current:
        return None

    return build_spotify_context(current)


if __name__ == "__main__":
    print(get_spotify_context())
