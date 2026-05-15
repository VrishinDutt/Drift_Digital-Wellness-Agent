import unittest
from unittest.mock import patch

import context.spotify_provider as spotify_provider


class SpotifyProviderTests(unittest.TestCase):

    def setUp(self):
        spotify_provider._spotify_client = None
        spotify_provider._spotify_config_checked = False
        spotify_provider._spotify_configured = False

    def test_returns_none_when_config_missing(self):
        with patch.object(spotify_provider, "load_spotify_env"):
            with patch.dict("os.environ", {}, clear=True):
                self.assertIsNone(
                    spotify_provider.get_spotify_context()
                )

    def test_returns_none_when_no_playback(self):
        class FakeClient:
            def current_playback(self):
                return None

        with patch.object(
            spotify_provider,
            "get_spotify_client",
            return_value=FakeClient()
        ):
            self.assertIsNone(
                spotify_provider.get_spotify_context()
            )

    def test_returns_none_when_api_fails(self):
        class FakeClient:
            def current_playback(self):
                raise OSError("offline")

        with patch.object(
            spotify_provider,
            "get_spotify_client",
            return_value=FakeClient()
        ):
            self.assertIsNone(
                spotify_provider.get_spotify_context()
            )


if __name__ == "__main__":
    unittest.main()
