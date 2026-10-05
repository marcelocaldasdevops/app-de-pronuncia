"""
Phonetic conversion and IPA mapping engine.
Converts English graphemes to ARPAbet phonemes via g2p-en,
and translates ARPAbet phonemes to international phonetic alphabet (IPA)
with articulation tips for language learners.
"""

from typing import List, Dict, Any
import re

try:
    from g2p_en import G2p
    _g2p = G2p()
except Exception:
    _g2p = None

# ARPAbet to IPA mapping
ARPABET_TO_IPA: Dict[str, str] = {
    # Vowels
    "AA": "ɑː",
    "AE": "æ",
    "AH": "ʌ",
    "AO": "ɔː",
    "AW": "aʊ",
    "AY": "aɪ",
    "EH": "e",
    "ER": "ɜːr",
    "EY": "eɪ",
    "IH": "ɪ",
    "IY": "iː",
    "OW": "oʊ",
    "OY": "ɔɪ",
    "UH": "ʊ",
    "UW": "uː",
    # Consonants
    "B": "b",
    "CH": "tʃ",
    "D": "d",
    "DH": "ð",
    "F": "f",
    "G": "ɡ",
    "HH": "h",
    "JH": "dʒ",
    "K": "k",
    "L": "l",
    "M": "m",
    "N": "n",
    "NG": "ŋ",
    "P": "p",
    "R": "r",
    "S": "s",
    "SH": "ʃ",
    "T": "t",
    "TH": "θ",
    "V": "v",
    "W": "w",
    "Y": "j",
    "Z": "z",
    "ZH": "ʒ",
}

# Articulation tips for ESL learners (Brazilian Portuguese speakers focus)
PHONEME_TIPS: Dict[str, str] = {
    "θ": "Coloque a ponta da língua suavemente entre os dentes e sopre o ar sem vibrar as cordas vocais (som de 'think').",
    "ð": "Ponta da língua entre os dentes, soprando com vibração das cordas vocais (som de 'this', 'the').",
    "r": "Enrole a ponta da língua para trás em direção ao céu da boca sem encostar, criando som retroflexo americano.",
    "æ": "Abra bem a boca na vertical e abaixe a língua, som intermediário entre 'A' e 'E' (como em 'cat', 'black').",
    "ʌ": "Som de 'A' neutro, curto e gutural, com a boca semiaberta e relaxada (como em 'cup', 'love').",
    "ɪ": "Vogal curta e frouxa, mais próxima de um 'Ê' relaxado do que de um 'I' longo (como em 'sit', 'ship').",
    "iː": "Vogal longa e tensa com os cantos dos lábios esticados em sorriso (como em 'seat', 'sheep').",
    "ʊ": "Lábios levemente arredondados e relaxados, som curto (como em 'book', 'put').",
    "uː": "Lábios bem arredondados e tensos, som longo (como em 'boot', 'two').",
    "w": "Arredonde bem os lábios como para assobiar, sem encostar os dentes (não confunda com 'V').",
    "v": "Encoste suavemente os dentes superiores no lábio inferior e vibre (som de 'voice').",
    "ŋ": "Fundo da língua encostado no céu da boca, ar saindo pelo nariz sem soltar um 'G' duro no final ('sing').",
    "tʃ": "Língua no palato soltando uma rajada rápida com bico nos lábios ('chair', 'church').",
    "dʒ": "Versão vozeada do som anterior, com vibração nas cordas vocais ('job', 'edge').",
    "ʃ": "Lábios em bico com fluxo de ar contínuo ('shoe', 'action').",
    "ʒ": "Versão vozeada de 'sh', similar ao 'J' do português ('measure', 'vision').",
}

def clean_arpabet_token(token: str) -> str:
    """Removes stress digits (0, 1, 2) from ARPAbet token."""
    return re.sub(r"[0-9]", "", token).upper()

def arpabet_to_ipa(arpabet_token: str) -> str:
    """Converts a single ARPAbet phoneme to its IPA equivalent."""
    clean = clean_arpabet_token(arpabet_token)
    return ARPABET_TO_IPA.get(clean, clean.lower())

def get_phoneme_tip(ipa_symbol: str) -> str:
    """Returns anatomical tip for a given IPA symbol if registered."""
    return PHONEME_TIPS.get(ipa_symbol, "Articule com precisão e clareza acústica.")

def word_to_phonemes(word: str) -> List[Dict[str, str]]:
    """
    Decomposes a single English word into its phoneme chain (ARPAbet + IPA).
    """
    clean_word = word.strip().lower()
    if not clean_word:
        return []

    if _g2p is not None:
        phonemes_raw = _g2p(clean_word)
        # Filter out spaces or punctuation
        arpabet_tokens = [clean_arpabet_token(p) for p in phonemes_raw if re.match(r"^[A-Za-z0-9]+$", p)]
    else:
        # Fallback if g2p-en failed to load
        arpabet_tokens = [c.upper() for c in clean_word if c.isalnum()]

    result = []
    for arp in arpabet_tokens:
        ipa_sym = arpabet_to_ipa(arp)
        result.append({
            "arpabet": arp,
            "ipa": ipa_sym,
            "tip": get_phoneme_tip(ipa_sym)
        })
    return result

def ipa_to_friendly_phonetic(ipa_str: str) -> str:
    s = ipa_str.strip().strip('/')
    replacements = [
        ('tʃ', 'tch'),
        ('dʒ', 'dj'),
        ('ʃ', 'x'),
        ('ʒ', 'j'),
        ('θ', 'th'),
        ('ð', 'd'),
        ('ŋ', 'ng'),
        ('aɪ', 'ái'),
        ('eɪ', 'ei'),
        ('ɔɪ', 'ói'),
        ('aʊ', 'áu'),
        ('oʊ', 'ôu'),
        ('iː', 'í'),
        ('uː', 'ú'),
        ('ɜːr', 'ər'),
        ('t̬ɚ', 'dər'),
        ('ɚ', 'ər'),
        ('ɑː', 'ó'),
        ('ɔː', 'ó'),
        ('ʌ', 'â'),
        ('æ', 'é'),
        ('ɛ', 'é'),
        ('ɪ', 'i'),
        ('ʊ', 'u'),
        ('ɡ', 'g'),
        ('w', 'u'),
        ('j', 'i'),
        ('h', 'r'),
    ]
    for old, new in replacements:
        s = s.replace(old, new)
    s = s.replace('ˈ', '').replace('ˌ', '').replace('.', '-')
    if s:
        s = s[0].upper() + s[1:]
    return s

def sentence_to_ipa(text: str) -> Dict[str, Any]:
    """
    Converts a sentence into words with IPA transcriptions and individual phonemes.
    """
    raw_words = re.findall(r"[a-zA-Z0-9']+", text)
    word_details = []
    sentence_ipa_parts = []

    for w in raw_words:
        phonemes = word_to_phonemes(w)
        word_ipa = "".join([p["ipa"] for p in phonemes])
        if word_ipa:
            sentence_ipa_parts.append(word_ipa)
            word_details.append({
                "word": w,
                "ipa": f"/{word_ipa}/",
                "phonemes": phonemes,
                "tip": phonemes[0]["tip"] if phonemes else None
            })
        else:
            word_details.append({
                "word": w,
                "ipa": f"/{w.lower()}/",
                "phonemes": [],
                "tip": None
            })

    full_ipa = f"/{' '.join(sentence_ipa_parts)}/" if sentence_ipa_parts else ""
    friendly_phonetic = ipa_to_friendly_phonetic(full_ipa)
    clean_text = text.strip()
    if clean_text.endswith('?') and not friendly_phonetic.endswith('?'):
        friendly_phonetic += '?'
    elif clean_text.endswith('!') and not friendly_phonetic.endswith('!'):
        friendly_phonetic += '!'
    elif clean_text.endswith('.') and not friendly_phonetic.endswith('.'):
        friendly_phonetic += '.'

    return {
        "sentence": text,
        "phonetic_ipa": full_ipa,
        "friendly_phonetic": friendly_phonetic,
        "words": word_details
    }
