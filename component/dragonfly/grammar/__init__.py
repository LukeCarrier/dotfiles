from dragonfly import Function, Grammar, Key, MappingRule, Mouse, Text, get_engine
from dragonfly.engines.backend_kaldi.dictation import UserDictation as Dictation

engine = get_engine(
    "kaldi",
    model_dir="kaldi_model",
    tmp_dir=None,
    audio_input_device=None,
    audio_self_threaded=True,
    audio_auto_reconnect=True,
    audio_reconnect_callback=None,
    retain_dir=None,
    retain_audio=None,
    retain_metadata=None,
    retain_approval_func=None,
    vad_aggressiveness=3,
    vad_padding_start_ms=150,
    vad_padding_end_ms=200,
    vad_complex_padding_end_ms=600,
    auto_add_to_user_lexicon=True,
    allow_online_pronunciations=False,
    lazy_compilation=True,
    invalidate_cache=False,
    expected_error_rate_threshold=None,
    alternative_dictation=None,
)

engine.add_word_list_to_user_dictation(["kaldi"])
engine.add_word_dict_to_user_dictation({"open F S T": "openFST"})


class TestUserDictationRule(MappingRule):
    mapping = {
        "dictate <text>": Function(lambda text: print("text: %s" % text)),
    }
    extras = [
        Dictation("text"),
    ]
