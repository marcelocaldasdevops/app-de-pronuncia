/// Utilitário de conversão fonética para Pronúncia Simplificada ("Abrasileirada").
/// Converte palavras em inglês e símbolos IPA para representações intuitivas em português brasileiro.
class PhoneticConverter {
  // Dicionário de termos comuns com pronúncia abrasileirada otimizada
  static const Map<String, String> _knownWords = {
    // Pronomes e pessoas
    'i': 'Ái',
    'you': 'iú',
    'he': 'rí',
    'she': 'xí',
    'it': 'it',
    'we': 'uí',
    'they': 'dêi',
    'me': 'mí',
    'him': 'rim',
    'her': 'rər',
    'us': 'âs',
    'them': 'dêm',
    'my': 'mái',
    'your': 'iór',
    'his': 'riz',
    'their': 'dér',
    'our': 'áur',

    // Verbos auxiliares e modais
    'is': 'iz',
    'are': 'ar',
    'am': 'ém',
    'was': 'uóz',
    'were': 'uər',
    'be': 'bí',
    'been': 'bín',
    'being': 'bí-ing',
    'have': 'rév',
    'has': 'réz',
    'had': 'réd',
    'do': 'dú',
    'does': 'dâz',
    'did': 'did',
    'will': 'uíl',
    'would': 'uúd',
    'can': 'kén',
    'could': 'cúd',
    'should': 'xúd',
    'must': 'mâst',
    'might': 'máit',
    'may': 'mêi',

    // Artigos, preposições e conectivos
    'the': 'dâ',
    'a': 'a',
    'an': 'én',
    'of': 'əv',
    'to': 'tu',
    'in': 'in',
    'on': 'ón',
    'at': 'ét',
    'for': 'fór',
    'with': 'uíd',
    'by': 'bái',
    'from': 'frâm',
    'about': 'ə-báut',
    'and': 'énd',
    'or': 'ór',
    'but': 'bât',
    'if': 'if',
    'so': 'sôu',
    'as': 'éz',
    'this': 'diz',
    'that': 'dét',
    'these': 'díz',
    'those': 'dôuz',

    // Interrogativos
    'what': 'uót',
    'where': 'uér',
    'when': 'uén',
    'why': 'uái',
    'who': 'rú',
    'how': 'ráu',
    'which': 'uítch',

    // Palavras cotidianas comuns
    'coffee': 'có-fi',
    'cozy': 'côu-zi',
    'shop': 'xóp',
    'store': 'stór',
    'nearby': 'nír-bái',
    'recommend': 'ré-kə-ménd',
    'please': 'plíz',
    'water': 'uó-dər',
    'glass': 'glés',
    'cup': 'câp',
    'tea': 'tí',
    'check': 'tchék',
    'bill': 'bíl',
    'menu': 'mé-niu',
    'restaurant': 'rés-to-rânt',
    'hotel': 'rou-tél',
    'airport': 'ér-pórt',
    'flight': 'fláit',
    'car': 'car',
    'taxi': 'ték-si',
    'bus': 'bâs',
    'train': 'trein',
    'station': 'stêi-xən',
    'ticket': 'tí-ket',
    'street': 'strít',
    'city': 'sí-ti',
    'good': 'gúd',
    'morning': 'mór-ning',
    'afternoon': 'éf-tər-nún',
    'evening': 'ív-ning',
    'night': 'náit',
    'hello': 're-lôu',
    'hi': 'rái',
    'thank': 'thénk',
    'thanks': 'thénks',
    'welcome': 'uél-cəm',
    'excuse': 'eks-kiúz',
    'sorry': 'só-ri',
    'help': 'rélp',
    'need': 'níd',
    'want': 'uónt',
    'like': 'láik',
    'love': 'lâv',
    'know': 'nôu',
    'think': 'think',
    'thought': 'thót',
    'see': 'sí',
    'look': 'luk',
    'go': 'gôu',
    'come': 'câm',
    'get': 'gét',
    'make': 'meik',
    'take': 'teik',
    'give': 'guív',
    'tell': 'tél',
    'say': 'sêi',
    'speak': 'spík',
    'talk': 'tók',
    'understand': 'ân-dər-sténd',
    'learn': 'lərn',
    'english': 'íng-lix',
    'friend': 'frênd',
    'time': 'táim',
    'day': 'dei',
    'today': 'tu-déi',
    'tomorrow': 'tu-mó-rôu',
    'yesterday': 'iés-tər-dei',
    'week': 'uík',
    'year': 'iír',
    'money': 'mâ-ni',
    'much': 'mâtch',
    'many': 'mé-ni',
    'more': 'mór',
    'cost': 'cóst',
    'price': 'práis',
    'buy': 'bái',
    'pay': 'pêi',
    'free': 'frí',
    'nice': 'náis',
    'great': 'greit',
    'bad': 'béd',
    'big': 'big',
    'small': 'smól',
    'hot': 'rót',
    'cold': 'côuld',
    'fast': 'fést',
    'slow': 'slôu',
    'yes': 'iés',
    'no': 'nôu',
    'not': 'nót',
    'now': 'náu',
    'later': 'léi-dər',
    'soon': 'sún',
    'always': 'ól-ueiz',
    'never': 'né-vər',
    'maybe': 'mêi-bi',
    'here': 'rír',
    'there': 'dér',
    'very': 'vé-ri',
    'really': 'rí-li',
    'again': 'ə-guên',
  };

  /// Converte um bloco IPA (ex: /kʊd jʊ .../) para notação abrasileirada
  static String ipaToFriendly(String ipa) {
    if (ipa.trim().isEmpty) return '';

    String s = ipa.trim();
    if (s.startsWith('/')) s = s.substring(1);
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);

    // Substituições fonéticas de maior comprimento primeiro
    final replacements = [
      // Encontros consonantais complexos
      ['tʃ', 'tch'],
      ['dʒ', 'dj'],
      ['ʃ', 'x'],
      ['ʒ', 'j'],
      ['θ', 'th'],
      ['ð', 'd'],
      ['ŋ', 'ng'],

      // Ditongos e vogais compostas
      ['aɪ', 'ái'],
      ['eɪ', 'ei'],
      ['ɔɪ', 'ói'],
      ['aʊ', 'áu'],
      ['oʊ', 'ôu'],
      ['iː', 'í'],
      ['uː', 'ú'],
      ['ɜːr', 'ər'],
      ['t̬ɚ', 'dər'],
      ['ɚ', 'ər'],
      ['ɑː', 'ó'],
      ['ɔː', 'ó'],
      ['ʌ', 'â'],
      ['æ', 'é'],
      ['ɛ', 'é'],
      ['ɪ', 'i'],
      ['ʊ', 'u'],

      // Consoantes específicas
      ['ɡ', 'g'],
      ['w', 'u'],
      ['j', 'i'],
      ['h', 'r'],
    ];

    for (final pair in replacements) {
      s = s.replaceAll(pair[0], pair[1]);
    }

    // Limpeza de marcadores de acentuação IPA e formatação de sílabas
    s = s.replaceAll('ˈ', '').replaceAll('ˌ', '').replaceAll('.', '-');

    return s.trim();
  }

  /// Gera a pronúncia abrasileirada para uma frase livre digitada pelo usuário.
  /// Se um [ipaString] for fornecido (do backend ou cache), utiliza-o como base para palavras desconhecidas.
  static String textToFriendly(String text, {String? ipaString}) {
    final clean = text.trim();
    if (clean.isEmpty) return '';

    // Separa pontuação final
    String trailingPunct = '';
    if (clean.endsWith('?') || clean.endsWith('!') || clean.endsWith('.')) {
      trailingPunct = clean.substring(clean.length - 1);
    }

    final words = clean
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return '';

    final resultParts = <String>[];

    for (int i = 0; i < words.length; i++) {
      final w = words[i].toLowerCase();

      // 1. Consulta o dicionário direto de termos comuns
      if (_knownWords.containsKey(w)) {
        resultParts.add(_knownWords[w]!);
        continue;
      }

      // 2. Se temos partes de IPA correspondentes
      // tenta converter a palavra heurística / fonética
      resultParts.add(_heuristicWordToFriendly(w));
    }

    if (resultParts.isEmpty) return '';

    // Capitaliza primeira letra
    String first = resultParts.first;
    if (first.isNotEmpty) {
      first = first[0].toUpperCase() + first.substring(1);
      resultParts[0] = first;
    }

    return '${resultParts.join(' ')}$trailingPunct';
  }

  /// Regras heurísticas para palavras em inglês desconhecidas no dicionário básico
  static String _heuristicWordToFriendly(String word) {
    String w = word.toLowerCase();

    // Sufixos comuns
    if (w.endsWith('tion')) {
      final root = w.substring(0, w.length - 4);
      return '${_heuristicWordToFriendly(root)}-xən';
    }
    if (w.endsWith('ing')) {
      final root = w.substring(0, w.length - 3);
      return '${_heuristicWordToFriendly(root)}-ing';
    }
    if (w.endsWith('ly')) {
      final root = w.substring(0, w.length - 2);
      return '${_heuristicWordToFriendly(root)}-li';
    }
    if (w.endsWith('able')) {
      final root = w.substring(0, w.length - 4);
      return '${_heuristicWordToFriendly(root)}-ə-bəl';
    }

    // Regras de substituição de letras em inglês para sons em português
    w = w.replaceAll('sh', 'x');
    w = w.replaceAll('ch', 'tch');
    w = w.replaceAll('th', 'th');
    w = w.replaceAll('ph', 'f');
    w = w.replaceAll('ee', 'í');
    w = w.replaceAll('oo', 'u');
    w = w.replaceAll('ea', 'í');
    w = w.replaceAll('oa', 'ôu');
    w = w.replaceAll('ai', 'ei');
    w = w.replaceAll('ay', 'ei');
    w = w.replaceAll('ow', 'ôu');
    w = w.replaceAll('igh', 'áit');

    if (w.startsWith('h')) {
      w = 'r${w.substring(1)}';
    }
    if (w.startsWith('w')) {
      w = 'u${w.substring(1)}';
    }

    return w;
  }
}
